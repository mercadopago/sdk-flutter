import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
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
import 'card_data.dart';

/// Low-level, programmatic API for talking to MercadoPago.
///
/// Use this when you want full control over the UI. If you prefer a hosted
/// experience, use `MercadoPagoCheckout` instead.
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
  Future<MercadoPagoResult<CardToken>> createTokenForNewCard(
    NewCardData data,
  ) async {
    final validation = _validateNewCard(data);
    if (validation != null) {
      _analytics.track(const AnalyticsEvent.tokenizeFailed());
      return Failure<CardToken>(validation);
    }

    try {
      final device = await _fingerprint.collect();
      final token = await _tokens.createTokenForNewCard(
        NewCardInput(
          cardNumber: _stripSpaces(data.cardNumber),
          cardholderName: data.cardholderName,
          expirationMonth: data.expirationMonth,
          expirationYear: data.expirationYear,
          securityCode: data.securityCode,
          documentType: data.documentType,
          documentNumber: data.documentNumber,
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

  /// Tokenizes a previously-saved card (identified by [SavedCardData.cardId]).
  Future<MercadoPagoResult<CardToken>> createTokenForSavedCard(
    SavedCardData data,
  ) async {
    if (data.cardId.isEmpty) {
      return const Failure<CardToken>(
        ValidationError(
          field: 'cardId',
          message: 'cardId must not be empty.',
          location: ErrorLocation.tokenization,
        ),
      );
    }
    if (data.securityCode.isEmpty || data.securityCode.length < 3) {
      return const Failure<CardToken>(InvalidCvvError());
    }

    try {
      final device = await _fingerprint.collect();
      final token = await _tokens.createTokenForSavedCard(
        SavedCardInput(
          cardId: data.cardId,
          securityCode: data.securityCode,
          expirationMonth: data.expirationMonth,
          expirationYear: data.expirationYear,
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

  MercadoPagoError? _validateNewCard(NewCardData data) {
    final number = _stripSpaces(data.cardNumber);
    if (number.isEmpty || !isValidLuhn(number)) {
      return const InvalidCardNumberError();
    }
    if (data.securityCode.length < 3 || data.securityCode.length > 4) {
      return const InvalidCvvError();
    }
    if (data.expirationMonth < 1 || data.expirationMonth > 12) {
      return const InvalidExpirationDateError();
    }
    final now = DateTime.now();
    final fullYear =
        data.expirationYear < 100 ? 2000 + data.expirationYear : data.expirationYear;
    final expiry = DateTime(fullYear, data.expirationMonth + 1, 0);
    if (expiry.isBefore(DateTime(now.year, now.month, 1))) {
      return const CardExpiredError();
    }
    if (data.cardholderName.trim().isEmpty) {
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
