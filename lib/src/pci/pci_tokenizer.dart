part of 'pci.dart';

/// The only place raw PCI values are read.
///
/// `final` so no library outside `pci.dart` can implement or extend it, and no
/// method returns a value derived from the PAN or CVV: validation returns
/// errors, tokenization returns an opaque [CardToken]. That is what makes
/// "the card number never leaves the SDK" a property of the code rather than a
/// request to the integrator.
final class PciTokenizer {
  PciTokenizer({required ApiClient api})
    : _repository = CardTokenRepositoryImpl(api);

  static final RegExp _panPattern = RegExp(r'^\d{13,19}$');
  static final RegExp _cvvPattern = RegExp(r'^\d{3,4}$');

  final CardTokenRepositoryImpl _repository;

  /// Captures the non-sensitive revision counter of a PCI field.
  ///
  /// CoreMethods uses this to abort when a user edits card data across an
  /// asynchronous boundary. It intentionally exposes no field value.
  int revisionOf(PciFieldState field) => field._revision;

  /// Whether [field] is still at a previously captured [revision].
  bool isAtRevision(PciFieldState field, int revision) =>
      field._revision == revision;

  /// Digits the CVV currently holds. Safe: a length is not card data, and the
  /// caller needs it to compare against the BIN metadata.
  int securityCodeLength(PciFieldState securityCode) => securityCode.length;

  /// Digits the PAN currently holds. Safe: only the length is exposed, never
  /// the card number itself. CoreMethods uses it to apply optional BIN rules
  /// immediately before tokenization.
  int cardNumberLength(PciFieldState cardNumber) =>
      _digitsOf(cardNumber).length;

  /// The BIN-8 for metadata lookups, or null when fewer than 8 digits have
  /// been entered. The BIN is already public through
  /// [CardNumberField.onBinChanged] and `CardToken.firstSixDigits`.
  String? binOf(PciFieldState cardNumber) {
    final digits = _digitsOf(cardNumber);
    return digits.length >= 8 ? digits.substring(0, 8) : null;
  }

  /// Validates a new card locally. Sees the raw values; returns none of them.
  MercadoPagoError? validateNewCard({
    required PciFieldState cardNumber,
    required PciFieldState expirationDate,
    required PciFieldState securityCode,
    required BuyerIdentification identification,
  }) {
    final pan = _digitsOf(cardNumber);
    if (!_panPattern.hasMatch(pan) || !isValidLuhn(pan)) {
      return const InvalidCardNumberError();
    }
    if (!_cvvPattern.hasMatch(securityCode._value)) {
      return const InvalidCvvError();
    }
    final expiryError = _validateExpiration(expirationDate._value);
    if (expiryError != null) return expiryError;
    return _validateIdentification(identification);
  }

  /// Tokenizes a new card: validates, builds the request, sends it, and clears
  /// the fields that were not edited while the request was in flight.
  /// Returns only the opaque token.
  Future<CardToken> createNewCardToken({
    required PciFieldState cardNumber,
    required PciFieldState expirationDate,
    required PciFieldState securityCode,
    required BuyerIdentification identification,
    required DeviceData device,
  }) async {
    final cardSnapshot = cardNumber._snapshot;
    final cvvSnapshot = securityCode._snapshot;
    final expirySnapshot = expirationDate._snapshot;

    final exp = expirySnapshot.value;
    final token = await _repository.createNewCardToken(
      cardNumber: _stripSpaces(cardSnapshot.value),
      cardholderName: identification.name.trim(),
      expirationMonth: int.parse(exp.substring(0, 2)),
      expirationYear: 2000 + int.parse(exp.substring(2, 4)),
      securityCode: cvvSnapshot.value,
      documentType: identification.type?.trim(),
      documentNumber: identification.number?.trim(),
      device: device,
    );

    cardNumber._clearIfUnchanged(cardSnapshot);
    securityCode._clearIfUnchanged(cvvSnapshot);
    expirationDate._clearIfUnchanged(expirySnapshot);
    return token;
  }

  /// Validates a saved-card CVV and optional expiration. Returns only errors.
  MercadoPagoError? validateSavedCard({
    required PciFieldState securityCode,
    PciFieldState? expirationDate,
  }) {
    if (!_cvvPattern.hasMatch(securityCode._value)) {
      return const InvalidCvvError();
    }
    return _parseOptionalExpiry(expirationDate?._value).error;
  }

  /// Tokenizes a saved card. Returns only the opaque token.
  Future<CardToken> createSavedCardToken({
    required String cardId,
    required PciFieldState securityCode,
    PciFieldState? expirationDate,
    required DeviceData device,
  }) async {
    final cvvSnapshot = securityCode._snapshot;
    final expirySnapshot = expirationDate?._snapshot;
    final expiry = _parseOptionalExpiry(expirySnapshot?.value);

    final token = await _repository.createSavedCardToken(
      cardId: cardId,
      securityCode: cvvSnapshot.value,
      expirationMonth: expiry.month,
      expirationYear: expiry.year,
      device: device,
    );

    securityCode._clearIfUnchanged(cvvSnapshot);
    if (expirationDate != null && expirySnapshot != null) {
      expirationDate._clearIfUnchanged(expirySnapshot);
    }
    return token;
  }

  String _digitsOf(PciFieldState state) => _stripSpaces(state._value);

  String _stripSpaces(String value) => value.replaceAll(RegExp(r'\s+'), '');

  MercadoPagoError? _validateIdentification(
    BuyerIdentification identification,
  ) {
    if (identification.name.trim().isEmpty) {
      return const ValidationError(
        field: 'cardholderName',
        message: 'cardholderName must not be empty.',
        location: ErrorLocation.tokenization,
      );
    }
    final type = identification.type?.trim();
    final number = identification.number?.trim();
    // One half supplied without the other, or either half blank after
    // trimming, is the same contract violation and reports the same field.
    final documentPairIsInvalid =
        (type == null) != (number == null) ||
        (type != null && (type.isEmpty || number!.isEmpty));
    if (documentPairIsInvalid) {
      return const ValidationError(
        field: 'identification',
        message: 'identification type and number must be supplied together.',
        location: ErrorLocation.tokenization,
      );
    }
    return null;
  }

  MercadoPagoError? _validateExpiration(String value) {
    if (value.length != 4) return const InvalidExpirationDateError();

    final month = int.tryParse(value.substring(0, 2));
    final shortYear = int.tryParse(value.substring(2, 4));
    if (month == null || shortYear == null || month < 1 || month > 12) {
      return const InvalidExpirationDateError();
    }

    final now = DateTime.now();
    final lastDayOfMonth = DateTime(2000 + shortYear, month + 1, 0);
    if (lastDayOfMonth.isBefore(DateTime(now.year, now.month, 1))) {
      return const CardExpiredError();
    }
    return null;
  }

  /// Parses an optional MMYY value. Absence is allowed; a supplied malformed
  /// or expired value is reported as a typed error instead of being silently
  /// omitted from the request.
  ({int? month, int? year, MercadoPagoError? error}) _parseOptionalExpiry(
    String? value,
  ) {
    if (value == null) {
      return (month: null, year: null, error: null);
    }
    final error = _validateExpiration(value);
    if (error != null) return (month: null, year: null, error: error);
    return (
      month: int.parse(value.substring(0, 2)),
      year: 2000 + int.parse(value.substring(2, 4)),
      error: null,
    );
  }
}
