import 'package:meta/meta.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../pci/pci.dart';
import '../core/error_mapper.dart';
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
/// Use this together with the PCI input widgets to build a custom card form.
///
/// Card data (number, CVV, expiration date) is passed as [PciFieldState]
/// controllers — the raw values are read internally by the SDK and never
/// returned to the caller. The integrator only ever receives the opaque
/// [CardToken] that the backend needs to create a payment.
class CoreMethods {
  @internal
  CoreMethods({
    required this._tokenizer,
    required PaymentMethodRepository paymentMethodRepository,
    required InstallmentRepository installmentRepository,
    required IssuerRepository issuerRepository,
    required IdentificationRepository identificationRepository,
    required FingerprintService fingerprintService,
    required AnalyticsService analytics,
    Duration cvvMetadataTimeout = const Duration(seconds: 2),
  }) : assert(
         cvvMetadataTimeout > Duration.zero,
         'cvvMetadataTimeout must be positive.',
       ),
       _paymentMethods = paymentMethodRepository,
       _installments = installmentRepository,
       _issuers = issuerRepository,
       _identification = identificationRepository,
       _fingerprint = fingerprintService,
       _analyticsService = analytics,
       _cvvMetadataTimeout = cvvMetadataTimeout;

  static final RegExp _binPattern = RegExp(r'^\d{8}$');

  final PciTokenizer _tokenizer;
  final PaymentMethodRepository _paymentMethods;
  final InstallmentRepository _installments;
  final IssuerRepository _issuers;
  final IdentificationRepository _identification;
  final FingerprintService _fingerprint;
  final AnalyticsService _analyticsService;
  final Duration _cvvMetadataTimeout;

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
    final documentType = identification.type?.trim();
    final validation = _tokenizer.validateNewCard(
      cardNumber: cardNumber,
      expirationDate: expirationDate,
      securityCode: securityCode,
      identification: identification,
    );
    if (validation != null) {
      _analyticsService.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: validation.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(validation);
    }

    final revisions = (
      cardNumber: _tokenizer.revisionOf(cardNumber),
      expirationDate: _tokenizer.revisionOf(expirationDate),
      securityCode: _tokenizer.revisionOf(securityCode),
    );

    // Discovery accepts the native contract's optional card metadata. Apply
    // any trustworthy PAN/CVV constraints here, at the operation that needs
    // them. A lookup outage must not fabricate defaults and reject a valid
    // card before the tokenization endpoint can evaluate it.
    final bin = _tokenizer.binOf(cardNumber);
    final cardMetadata = bin == null
        ? null
        : await _cardValidationMetadataForBin(bin);
    if (!_newCardFieldsAreAtRevisions(
      cardNumber: cardNumber,
      expirationDate: expirationDate,
      securityCode: securityCode,
      revisions: revisions,
    )) {
      final error = _changedPciInputError();
      _analyticsService.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(error);
    }
    final metadataError = _validateCardMetadata(
      cardNumber: cardNumber,
      securityCode: securityCode,
      metadata: cardMetadata,
    );
    if (metadataError != null) {
      _analyticsService.track(
        AnalyticsEvent.tokenizeFailed(
          isSavedCard: false,
          identityDocumentType: documentType,
          errorType: metadataError.runtimeType.toString(),
        ),
      );
      return Failure<CardToken>(metadataError);
    }

    try {
      final device = await _fingerprint.collect();
      if (!_newCardFieldsAreAtRevisions(
        cardNumber: cardNumber,
        expirationDate: expirationDate,
        securityCode: securityCode,
        revisions: revisions,
      )) {
        final error = _changedPciInputError();
        _analyticsService.track(
          AnalyticsEvent.tokenizeFailed(
            isSavedCard: false,
            identityDocumentType: documentType,
            errorType: error.runtimeType.toString(),
          ),
        );
        return Failure<CardToken>(error);
      }
      final finalValidation = _tokenizer.validateNewCard(
        cardNumber: cardNumber,
        expirationDate: expirationDate,
        securityCode: securityCode,
        identification: identification,
      );
      if (finalValidation != null) {
        _analyticsService.track(
          AnalyticsEvent.tokenizeFailed(
            isSavedCard: false,
            identityDocumentType: documentType,
            errorType: finalValidation.runtimeType.toString(),
          ),
        );
        return Failure<CardToken>(finalValidation);
      }
      final finalMetadataError = _validateCardMetadata(
        cardNumber: cardNumber,
        securityCode: securityCode,
        metadata: cardMetadata,
      );
      if (finalMetadataError != null) {
        _analyticsService.track(
          AnalyticsEvent.tokenizeFailed(
            isSavedCard: false,
            identityDocumentType: documentType,
            errorType: finalMetadataError.runtimeType.toString(),
          ),
        );
        return Failure<CardToken>(finalMetadataError);
      }
      final token = await _tokenizer.createNewCardToken(
        cardNumber: cardNumber,
        expirationDate: expirationDate,
        securityCode: securityCode,
        identification: identification,
        device: device,
      );
      _analyticsService.track(
        AnalyticsEvent.tokenizeSuccess(
          isSavedCard: false,
          identityDocumentType: documentType,
        ),
      );
      return Success<CardToken>(token);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.tokenization);
      _analyticsService.track(
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
    final normalizedCardId = cardId.trim();
    if (normalizedCardId.isEmpty) {
      return const Failure<CardToken>(
        ValidationError(
          field: 'cardId',
          message: 'cardId must not be empty.',
          location: ErrorLocation.tokenization,
        ),
      );
    }
    final validation = _tokenizer.validateSavedCard(
      securityCode: securityCode,
      expirationDate: expirationDate,
    );
    if (validation != null) {
      return Failure<CardToken>(validation);
    }

    final securityCodeRevision = _tokenizer.revisionOf(securityCode);
    final expirationDateRevision = expirationDate == null
        ? null
        : _tokenizer.revisionOf(expirationDate);

    try {
      final device = await _fingerprint.collect();
      if (!_tokenizer.isAtRevision(securityCode, securityCodeRevision) ||
          (expirationDate != null &&
              !_tokenizer.isAtRevision(
                expirationDate,
                expirationDateRevision!,
              ))) {
        return Failure<CardToken>(_changedPciInputError());
      }
      final finalValidation = _tokenizer.validateSavedCard(
        securityCode: securityCode,
        expirationDate: expirationDate,
      );
      if (finalValidation != null) {
        return Failure<CardToken>(finalValidation);
      }
      final token = await _tokenizer.createSavedCardToken(
        cardId: normalizedCardId,
        securityCode: securityCode,
        expirationDate: expirationDate,
        device: device,
      );
      _analyticsService.track(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: true),
      );
      return Success<CardToken>(token);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.tokenization);
      _analyticsService.track(
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
    ProcessingMode mode = ProcessingMode.aggregator,
  }) async {
    final binError = _validateBin(bin, ErrorLocation.paymentMethods);
    if (binError != null) {
      return Failure<List<PaymentMethod>>(binError);
    }
    try {
      final methods = await _paymentMethods.getByBin(bin: bin, mode: mode);
      final first = methods.isNotEmpty ? methods.first : null;
      _analyticsService.track(
        AnalyticsEvent.paymentMethods(
          cardBrand: first?.id ?? '',
          paymentType: first?.paymentTypeId ?? '',
          securityLength: first?.securityCodeLength ?? 0,
        ),
      );
      return Success<List<PaymentMethod>>(methods);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.paymentMethods);
      _analyticsService.track(
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
    final binError = _validateBin(bin, ErrorLocation.installments);
    if (binError != null) {
      return Failure<List<Installment>>(binError);
    }
    if (!amount.isFinite || amount <= 0) {
      return const Failure<List<Installment>>(
        ValidationError(
          field: 'amount',
          message: 'amount must be finite and greater than zero.',
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
      _analyticsService.track(
        AnalyticsEvent.installments(
          paymentType: installments.isNotEmpty
              ? installments.first.paymentTypeId
              : '',
          transactionAmount: amount,
        ),
      );
      return Success<List<Installment>>(installments);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.installments);
      _analyticsService.track(
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
    final binError = _validateBin(bin, ErrorLocation.issuer);
    if (binError != null) {
      return Failure<List<Issuer>>(binError);
    }
    final normalizedPaymentMethodId = paymentMethodId.trim();
    if (normalizedPaymentMethodId.isEmpty) {
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
        paymentMethodId: normalizedPaymentMethodId,
        bin: bin,
      );
      _analyticsService.track(
        AnalyticsEvent.issuers(
          issuers: issuers.map((i) => i.id).toList(growable: false),
        ),
      );
      return Success<List<Issuer>>(issuers);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.issuer);
      _analyticsService.track(
        AnalyticsEvent.issuersError(errorType: error.runtimeType.toString()),
      );
      return Failure<List<Issuer>>(error);
    }
  }

  Future<MercadoPagoResult<List<IdentificationType>>>
  getIdentificationTypes() async {
    try {
      final types = await _identification.getAll();
      _analyticsService.track(
        AnalyticsEvent.identificationTypes(
          documentTypes: types.map((t) => t.name).toList(growable: false),
        ),
      );
      return Success<List<IdentificationType>>(types);
    } catch (e) {
      final error = mapApiError(e, ErrorLocation.identification);
      _analyticsService.track(
        AnalyticsEvent.identificationTypesError(
          errorType: error.runtimeType.toString(),
        ),
      );
      return Failure<List<IdentificationType>>(error);
    }
  }

  MercadoPagoError? _validateBin(String bin, ErrorLocation location) {
    if (bin.isEmpty) return BinIsEmptyError(location: location);
    if (!_binPattern.hasMatch(bin)) {
      return ValidationError(
        field: 'bin',
        message: 'bin must contain exactly 8 numeric digits.',
        location: location,
      );
    }
    return null;
  }

  /// Resolves optional PAN/CVV rules for a card number from a BIN-8 lookup,
  /// matching the native CoreMethods contract (Android `CARD_BIN_LENGTH = 8`,
  /// iOS `CardNumber.binLength = 8`). Discovery intentionally accepts absent
  /// metadata; tokenization narrows its generic validation only for rules the
  /// response actually supplies.
  Future<_CardValidationMetadata?> _cardValidationMetadataForBin(
    String bin,
  ) async {
    try {
      final methods = await _paymentMethods
          .getByBin(bin: bin, mode: ProcessingMode.aggregator)
          .timeout(_cvvMetadataTimeout);
      for (final method in methods) {
        if (method.cardNumberLengthMin != null ||
            method.cardNumberLengthMax != null ||
            method.securityCodeLength != null) {
          return _CardValidationMetadata(
            minPanLength: method.cardNumberLengthMin,
            maxPanLength: method.cardNumberLengthMax,
            cvvLength: method.securityCodeLength,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  MercadoPagoError? _validateCardMetadata({
    required PciFieldState cardNumber,
    required PciFieldState securityCode,
    required _CardValidationMetadata? metadata,
  }) {
    if (metadata == null) return null;

    final panLength = _tokenizer.cardNumberLength(cardNumber);
    final minPanLength = metadata.minPanLength;
    final maxPanLength = metadata.maxPanLength;
    final hasValidMin =
        minPanLength != null && minPanLength >= 13 && minPanLength <= 19;
    final hasValidMax =
        maxPanLength != null && maxPanLength >= 13 && maxPanLength <= 19;
    if ((hasValidMin && panLength < minPanLength) ||
        (hasValidMax && panLength > maxPanLength)) {
      return const InvalidCardNumberError();
    }

    final cvvLength = metadata.cvvLength;
    if ((cvvLength == 3 || cvvLength == 4) &&
        _tokenizer.securityCodeLength(securityCode) != cvvLength) {
      return const InvalidCvvError();
    }
    return null;
  }

  bool _newCardFieldsAreAtRevisions({
    required PciFieldState cardNumber,
    required PciFieldState expirationDate,
    required PciFieldState securityCode,
    required ({int cardNumber, int expirationDate, int securityCode}) revisions,
  }) =>
      _tokenizer.isAtRevision(cardNumber, revisions.cardNumber) &&
      _tokenizer.isAtRevision(expirationDate, revisions.expirationDate) &&
      _tokenizer.isAtRevision(securityCode, revisions.securityCode);

  ValidationError _changedPciInputError() => const ValidationError(
    field: 'cardData',
    message: 'Card data changed while tokenization was in progress. Retry.',
    location: ErrorLocation.tokenization,
  );
}

final class _CardValidationMetadata {
  const _CardValidationMetadata({
    required this.minPanLength,
    required this.maxPanLength,
    required this.cvvLength,
  });

  final int? minPanLength;
  final int? maxPanLength;
  final int? cvvLength;
}
