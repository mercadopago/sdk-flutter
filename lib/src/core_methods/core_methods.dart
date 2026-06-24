import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../components/pci_field_state.dart';
import '../core/error_mapper.dart';
import '../core/luhn.dart';
import '../domain/errors.dart';
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
  Future<MercadoPagoResult<CardToken>> createTokenForNewCard({
    required PciFieldState cardNumber,
    required PciFieldState securityCode,
    required PciFieldState expirationDate,
    required String cardholderName,
    String? documentType,
    String? documentNumber,
  }) async {
    final validation = _validateNewCard(
      cardNumber: cardNumber,
      securityCode: securityCode,
      expirationDate: expirationDate,
      cardholderName: cardholderName,
    );
    if (validation != null) {
      _analytics.track(const AnalyticsEvent.tokenizeFailed());
      return Failure<CardToken>(validation);
    }

    final rawNumber = _stripSpaces(cardNumber.rawValue);
    final rawCvv = securityCode.rawValue;
    final exp = expirationDate.rawValue;
    final month = int.parse(exp.substring(0, 2));
    final year = 2000 + int.parse(exp.substring(2, 4));

    try {
      final device = await _fingerprint.collect();
      final token = await _tokens.createTokenForNewCard(
        NewCardInput(
          cardNumber: rawNumber,
          cardholderName: cardholderName,
          expirationMonth: month,
          expirationYear: year,
          securityCode: rawCvv,
          documentType: documentType,
          documentNumber: documentNumber,
        ),
        device,
      );
      _analytics.track(const AnalyticsEvent.tokenizeSuccess());
      return Success<CardToken>(token);
    } catch (e) {
      _analytics.track(const AnalyticsEvent.tokenizeFailed());
      return Failure<CardToken>(mapApiError(e, ErrorLocation.tokenization));
    }
  }

  /// Tokenizes a previously-saved card (identified by [cardId]).
  ///
  /// The [securityCode] (CVV) is supplied as a [PciFieldState] controller —
  /// the raw value is read internally by the SDK.
  Future<MercadoPagoResult<CardToken>> createTokenForSavedCard({
    required String cardId,
    required PciFieldState securityCode,
    int? expirationMonth,
    int? expirationYear,
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
      _analytics.track(const AnalyticsEvent.tokenizeSuccess());
      return Success<CardToken>(token);
    } catch (e) {
      _analytics.track(const AnalyticsEvent.tokenizeFailed());
      return Failure<CardToken>(mapApiError(e, ErrorLocation.tokenization));
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
      return Success<List<PaymentMethod>>(methods);
    } catch (e) {
      return Failure<List<PaymentMethod>>(
        mapApiError(e, ErrorLocation.paymentMethods),
      );
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
      return Success<List<Installment>>(installments);
    } catch (e) {
      return Failure<List<Installment>>(
        mapApiError(e, ErrorLocation.installments),
      );
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
      return Success<List<Issuer>>(issuers);
    } catch (e) {
      return Failure<List<Issuer>>(
        mapApiError(e, ErrorLocation.issuer),
      );
    }
  }

  Future<MercadoPagoResult<List<IdentificationType>>>
      getIdentificationTypes() async {
    try {
      final types = await _identification.getAll();
      return Success<List<IdentificationType>>(types);
    } catch (e) {
      return Failure<List<IdentificationType>>(
        mapApiError(e, ErrorLocation.identification),
      );
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
    final cvv = securityCode.rawValue;
    if (cvv.length < 3 || cvv.length > 4) {
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
}
