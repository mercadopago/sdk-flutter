import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../components/pci_field_state.dart';
import '../core/error_mapper.dart';
import '../core/luhn.dart';
import '../domain/errors.dart';
import '../domain/models/buyer_identification.dart';
import '../domain/models/card_token.dart';
import '../domain/models/identification_type.dart';
import '../domain/models/installment.dart';
import '../domain/models/issuer.dart';
import '../domain/models/payment_method.dart';
import '../domain/repositories.dart';
import '../domain/result.dart';
import '../fingerprint/fingerprint_service.dart';

/// Low-level, programmatic API for talking to MercadoPago.
///
/// Use this when you want full control over the UI. If you prefer a hosted
/// experience, use `MercadoPagoCheckout` instead.
///
/// Card data (number, CVV, expiration date) is passed as [PciFieldState]
/// controllers — the raw values are read internally by the SDK and never
/// returned to the caller. The integrator only ever receives the opaque
/// [CardToken] that the backend needs to create a payment.
class CoreMethods {
  CoreMethods({
    required TokenRepository tokenRepository,
    required PaymentMethodRepository paymentMethodRepository,
    required InstallmentRepository installmentRepository,
    required IssuerRepository issuerRepository,
    required IdentificationRepository identificationRepository,
    required FingerprintService fingerprintService,
    required AnalyticsService analytics,
  })  : _tokens = tokenRepository,
        _paymentMethods = paymentMethodRepository,
        _installments = installmentRepository,
        _issuers = issuerRepository,
        _identification = identificationRepository,
        _fingerprint = fingerprintService,
        _analytics = analytics;

  final TokenRepository _tokens;
  final PaymentMethodRepository _paymentMethods;
  final InstallmentRepository _installments;
  final IssuerRepository _issuers;
  final IdentificationRepository _identification;
  final FingerprintService _fingerprint;
  final AnalyticsService _analytics;

  /// Tokenizes a brand-new card.
  ///
  /// Card data is supplied through [PciFieldState] controllers — the SDK
  /// reads the raw values internally and they are never exposed to the caller.
  ///
  /// [expirationDate] must have been populated by [ExpirationDateField] in
  /// MMYY format (4 digits, e.g. `"1230"` for December 2030).
  ///
  /// [identification] carries the cardholder's name plus an optional
  /// identification document (matching the native `BuyerIdentification`).
  Future<MercadoPagoResult<CardToken>> createTokenForNewCard({
    required PciFieldState cardNumber,
    required PciFieldState expirationDate,
    required PciFieldState securityCode,
    required BuyerIdentification identification,
  }) async {
    final documentType = identification.type;
    final validation = _validateNewCard(
      cardNumber: cardNumber,
      securityCode: securityCode,
      expirationDate: expirationDate,
      cardholderName: identification.name,
    );
    if (validation != null) {
      _analytics.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: validation.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(validation);
    }

    final rawNumber = _stripSpaces(cardNumber.rawValue);
    final rawCvv = securityCode.rawValue;
    final exp = expirationDate.rawValue;
    final month = int.parse(exp.substring(0, 2));
    final year = 2000 + int.parse(exp.substring(2, 4));

    // Validate the CVV length against the card's securityCodeLength resolved
    // from a BIN lookup (exact match, fallback 3) — mirrors the native SDKs,
    // whose tokenization use cases reject e.g. a 3-digit CVV on a 4-digit Amex.
    final expectedCvvLength = await _securityCodeLengthForBin(rawNumber);
    if (rawCvv.length != expectedCvvLength) {
      _analytics.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: 'InvalidCvvError',
        ),
      );
      return const Failure<CardToken>(InvalidCvvError());
    }

    try {
      final device = await _fingerprint.collect();
      final token = await _tokens.createTokenForNewCard(
        NewCardInput(
          cardNumber: rawNumber,
          cardholderName: identification.name,
          expirationMonth: month,
          expirationYear: year,
          securityCode: rawCvv,
          documentType: identification.type,
          documentNumber: identification.number,
        ),
        device,
      );
      _analytics.track(
        AnalyticsEvent.tokenizeSuccess(
          isSavedCard: false,
          identityDocumentType: documentType,
        ),
      );
      return Success<CardToken>(token);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.tokenization);
      _analytics.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(error);
    }
  }

  /// Tokenizes a previously-saved card (identified by [cardId]).
  ///
  /// The [securityCode] (CVV) is supplied as a [PciFieldState] controller —
  /// the raw value is read internally by the SDK. [expirationDate] is an
  /// optional [PciFieldState] in MMYY format (mirroring the native SDKs, which
  /// take an optional PCI expiration field, not raw month/year integers).
  Future<MercadoPagoResult<CardToken>> createTokenForSavedCard({
    required String cardId,
    required PciFieldState securityCode,
    PciFieldState? expirationDate,
  }) async {
    if (cardId.isEmpty) {
      return const Failure<CardToken>(
        ValidationError(
          field: 'cardId',
          message: 'cardId must not be empty.',
          location: ErrorLocation.tokenization,
        ),
      );
    }
    final rawCvv = securityCode.rawValue;
    if (rawCvv.length < 3 || rawCvv.length > 4) {
      return const Failure<CardToken>(InvalidCvvError());
    }

    final (expirationMonth, expirationYear) = _parseExpiry(expirationDate);

    try {
      final device = await _fingerprint.collect();
      final token = await _tokens.createTokenForSavedCard(
        SavedCardInput(
          cardId: cardId,
          securityCode: rawCvv,
          expirationMonth: expirationMonth,
          expirationYear: expirationYear,
        ),
        device,
      );
      _analytics.track(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: true),
      );
      return Success<CardToken>(token);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.tokenization);
      _analytics.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: true,
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(error);
    }
  }

  Future<MercadoPagoResult<List<PaymentMethod>>> getPaymentMethods({
    required String bin,
  }) async {
    if (bin.isEmpty) {
      return const Failure<List<PaymentMethod>>(BinIsEmptyError());
    }
    try {
      final methods = await _paymentMethods.getByBin(bin);
      final first = methods.isNotEmpty ? methods.first : null;
      _analytics.track(
        AnalyticsEvent.paymentMethods(
          cardBrand: first?.id ?? '',
          paymentType: first?.paymentTypeId ?? '',
          securityLength: first?.securityCodeLength ?? 0,
        ),
      );
      return Success<List<PaymentMethod>>(methods);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.paymentMethods);
      _analytics.track(
        AnalyticsEvent.paymentMethodsError(
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<List<PaymentMethod>>(error);
    }
  }

  Future<MercadoPagoResult<List<Installment>>> getInstallments({
    required String bin,
    required double amount,
    ProcessingMode mode = ProcessingMode.aggregator,
  }) async {
    if (bin.isEmpty) {
      return const Failure<List<Installment>>(BinIsEmptyError());
    }
    if (amount <= 0) {
      return const Failure<List<Installment>>(
        ValidationError(
          field: 'amount',
          message: 'amount must be greater than zero.',
          location: ErrorLocation.installments,
        ),
      );
    }
    try {
      final installments = await _installments.get(
        bin: bin,
        amount: amount,
        mode: mode,
      );
      _analytics.track(
        AnalyticsEvent.installments(
          paymentType:
              installments.isNotEmpty ? installments.first.paymentTypeId : '',
          transactionAmount: amount,
        ),
      );
      return Success<List<Installment>>(installments);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.installments);
      _analytics.track(
        AnalyticsEvent.installmentsError(
          errorType: error.runtimeType.toString(),
          transactionAmount: amount,
        ),
      );
      return Failure<List<Installment>>(error);
    }
  }

  Future<MercadoPagoResult<List<Issuer>>> getIssuers({
    required String paymentMethodId,
    required String bin,
  }) async {
    if (bin.isEmpty) {
      return const Failure<List<Issuer>>(BinIsEmptyError());
    }
    if (paymentMethodId.isEmpty) {
      return const Failure<List<Issuer>>(
        ValidationError(
          field: 'paymentMethodId',
          message: 'paymentMethodId must not be empty.',
          location: ErrorLocation.issuer,
        ),
      );
    }
    try {
      final issuers = await _issuers.get(
        paymentMethodId: paymentMethodId,
        bin: bin,
      );
      _analytics.track(
        AnalyticsEvent.issuers(
          issuers: issuers.map((i) => i.id).toList(growable: false),
        ),
      );
      return Success<List<Issuer>>(issuers);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.issuer);
      _analytics.track(
        AnalyticsEvent.issuersError(errorType: error.runtimeType.toString()),
      );
      return Failure<List<Issuer>>(error);
    }
  }

  Future<MercadoPagoResult<List<IdentificationType>>>
      getIdentificationTypes() async {
    try {
      final types = await _identification.getAll();
      _analytics.track(
        AnalyticsEvent.identificationTypes(
          documentTypes: types.map((t) => t.name).toList(growable: false),
        ),
      );
      return Success<List<IdentificationType>>(types);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.identification);
      _analytics.track(
        AnalyticsEvent.identificationTypesError(
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<List<IdentificationType>>(error);
    }
  }

  MercadoPagoError? _validateNewCard({
    required PciFieldState cardNumber,
    required PciFieldState securityCode,
    required PciFieldState expirationDate,
    required String cardholderName,
  }) {
    final number = _stripSpaces(cardNumber.rawValue);
    if (number.isEmpty || !isValidLuhn(number)) {
      return const InvalidCardNumberError();
    }
    // Only a presence check here; the exact length is validated against the
    // card's securityCodeLength (from the BIN lookup) in createTokenForNewCard.
    if (securityCode.rawValue.isEmpty) {
      return const InvalidCvvError();
    }
    final exp = expirationDate.rawValue;
    if (exp.length != 4) {
      return const InvalidExpirationDateError();
    }
    final month = int.tryParse(exp.substring(0, 2)) ?? 0;
    final year = int.tryParse(exp.substring(2, 4)) ?? 0;
    if (month < 1 || month > 12) {
      return const InvalidExpirationDateError();
    }
    final now = DateTime.now();
    final fullYear = 2000 + year;
    final expiry = DateTime(fullYear, month + 1, 0);
    if (expiry.isBefore(DateTime(now.year, now.month, 1))) {
      return const CardExpiredError();
    }
    if (cardholderName.trim().isEmpty) {
      return const ValidationError(
        field: 'cardholderName',
        message: 'cardholderName must not be empty.',
        location: ErrorLocation.tokenization,
      );
    }
    return null;
  }

  String _stripSpaces(String value) => value.replaceAll(RegExp(r'\s+'), '');

  /// Resolves the expected CVV length for a card number from a BIN lookup
  /// (BIN-8), returning the payment method's `securityCodeLength` or `3` as a
  /// fallback when the lookup misses or errors — matching the native SDKs.
  Future<int> _securityCodeLengthForBin(String cardNumber) async {
    final bin = cardNumber.length >= 8 ? cardNumber.substring(0, 8) : cardNumber;
    try {
      final methods = await _paymentMethods.getByBin(bin);
      final length = methods.isNotEmpty ? methods.first.securityCodeLength : 0;
      return length > 0 ? length : 3;
    } catch (_) {
      return 3;
    }
  }

  /// Parses an optional MMYY PCI expiration field into `(month, year)` ints.
  /// Returns `(null, null)` when absent or malformed (a saved card may not
  /// require the expiration date).
  (int?, int?) _parseExpiry(PciFieldState? expirationDate) {
    final exp = expirationDate?.rawValue ?? '';
    if (exp.length != 4) return (null, null);
    final month = int.tryParse(exp.substring(0, 2));
    final year = int.tryParse(exp.substring(2, 4));
    if (month == null || year == null) return (null, null);
    return (month, 2000 + year);
  }
}
