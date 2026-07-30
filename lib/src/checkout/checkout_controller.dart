import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../components/pci_field_state.dart';
import '../core/error_mapper.dart';
import '../core_methods/core_methods.dart';
import '../domain/errors.dart';
import '../domain/models/buyer_identification.dart';
import '../domain/models/card_bin_data.dart';
import '../domain/models/card_form_config.dart';
import '../domain/models/card_save_result.dart';
import '../domain/models/card_token.dart';
import '../domain/models/card_transaction_result.dart';
import '../domain/models/mp_cancel_context.dart';
import '../domain/repositories.dart';
import '../domain/result.dart';

/// Type of checkout flow the user is performing.
enum CheckoutKind { cardSave, cardTransaction }

/// Coordinates state between checkout screens (card form → installments →
/// review) and the underlying data sources.
///
/// The card form is server-driven: [initialize] fetches field configs,
/// translations and document types from the `card_payment_brick/initialization`
/// BFF endpoint, and [onBinChanged] resolves payment methods, issuers, CVV
/// rules and installment options from the aggregated `.../card` endpoint in a
/// single round-trip. Tokenization still flows through [CoreMethods] so raw
/// card data never leaves the SDK.
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required this.kind,
    required CoreMethods coreMethods,
    required CardFormRepository cardFormRepository,
    required AnalyticsService analytics,
    this.excludedPaymentTypes = const [],
    this.excludedPaymentMethods = const [],
    this.minInstallments,
    this.maxInstallments,
    this.orderId,
    this.clientToken,
  })  : _coreMethods = coreMethods,
        _cardForm = cardFormRepository,
        _analytics = analytics,
        assert(
          kind == CheckoutKind.cardSave || orderId != null,
          'CardTransaction requires an order (orderId).',
        );

  final CheckoutKind kind;
  final CoreMethods _coreMethods;
  final CardFormRepository _cardForm;
  final AnalyticsService _analytics;
  final List<String> excludedPaymentTypes;
  final List<String> excludedPaymentMethods;
  final int? minInstallments;
  final int? maxInstallments;
  final String? orderId;
  final String? clientToken;

  CheckoutType get _checkoutType => kind == CheckoutKind.cardSave
      ? CheckoutType.cardSave
      : CheckoutType.cardTransaction;

  CheckoutStep _step = CheckoutStep.initialization;
  CheckoutStep get step => _step;

  // Server-driven form configuration (loaded once by [initialize]).
  CardFormConfig? _config;
  CardFormConfig? get config => _config;

  // BIN-resolved data (payment methods, issuers, CVV rules, installments).
  CardBinData? _binData;
  CardBinMethod? _selectedMethod;
  List<CheckoutInstallment> _installments = const [];
  CheckoutInstallment? _selectedInstallment;
  CardToken? _token;
  MercadoPagoError? _lastError;

  CardBinData? get binData => _binData;
  CardBinMethod? get selectedMethod => _selectedMethod;
  List<CheckoutInstallment> get installments => _installments;

  /// Active translations, preferring the BIN-refined set over the initial one.
  CardFormTranslations? get translations =>
      _binData?.translations ?? _config?.translations;
  CheckoutInstallment? get selectedInstallment => _selectedInstallment;
  CardToken? get token => _token;
  MercadoPagoError? get lastError => _lastError;

  /// Effective CVV length for the current selection, preferring the BIN-level
  /// spec, then the form-level default, then a sensible fallback.
  int get securityCodeLength =>
      _selectedMethod?.securityCode?.length ??
      _config?.securityCode.length ??
      3;

  bool _busy = false;
  bool get isBusy => _busy;
  Timer? _binDebounce;

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  /// Loads the server-driven form configuration. Call once when the checkout
  /// opens. On success the flow advances from [CheckoutStep.initialization] to
  /// [CheckoutStep.cardForm].
  Future<void> initialize() async {
    _analytics.track(
      AnalyticsEvent.checkoutStart(
        checkoutType: _checkoutType.value,
        excludedPaymentTypes: excludedPaymentTypes,
        excludedPaymentMethods: excludedPaymentMethods,
        orderId: orderId,
      ),
    );
    try {
      _config = await _cardForm.initialize(
        CardFormInitParams(
          checkoutType: _checkoutType,
          orderId: orderId,
          clientToken: clientToken,
        ),
      );
      _lastError = null;
      _step = CheckoutStep.cardForm;
    } catch (e) {
      _lastError = InitializationFailedError(reason: e.toString());
      _analytics.track(
        AnalyticsEvent.checkoutInitializeError(
          errorType: _lastError.runtimeType.toString(),
        ),
      );
    }
    notifyListeners();
  }

  /// Amount used for the aggregated BIN lookup. Card save flows send `0`
  /// (matching the native SDKs); card transactions use the amount the server
  /// resolved from the order (via `initialization`). Never integrator-supplied.
  double get _binLookupAmount => _config?.amount ?? 0;

  /// Resolves payment methods, issuers, CVV config and installments for the
  /// entered BIN. Called as the user types; debounced to 300 ms.
  void onBinChanged(String bin) {
    _binDebounce?.cancel();
    _binDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final data = await _cardForm.getCardBin(
          CardBinParams(
            bin: bin,
            checkoutType: _checkoutType,
            amount: _binLookupAmount,
            excludedPaymentTypes: excludedPaymentTypes,
            excludedPaymentMethods: excludedPaymentMethods,
            minInstallments: minInstallments,
            maxInstallments: maxInstallments,
          ),
        );
        _binData = data;
        _selectedMethod =
            data.paymentMethods.isNotEmpty ? data.paymentMethods.first : null;
        _installments = data.installments;
        _selectedInstallment = _defaultInstallment(data.installments);
        _lastError = null;
      } catch (e) {
        _lastError = mapApiError(e, ErrorLocation.paymentMethods);
      }
      notifyListeners();
    });
  }

  /// Submits the card form. Performs tokenization and, for CardTransaction
  /// flows, advances to installment selection. For CardSave flows the result
  /// is delivered immediately to the caller via the screen's callback.
  ///
  /// Returns immediately with a [Failure] if a submission is already in
  /// progress — callers must not call this concurrently.
  Future<MercadoPagoResult<CardToken>> submitCardForm({
    required PciFieldState cardNumber,
    required PciFieldState securityCode,
    required PciFieldState expirationDate,
    required String cardholderName,
    String? documentType,
    String? documentNumber,
  }) async {
    if (_busy) {
      return const Failure(
        ValidationError(
          field: 'submit',
          message: 'A submission is already in progress.',
        ),
      );
    }
    _setBusy(true);
    try {
      final result = await _coreMethods.createTokenForNewCard(
        cardNumber: cardNumber,
        securityCode: securityCode,
        expirationDate: expirationDate,
        identification: BuyerIdentification(
          name: cardholderName,
          number: documentNumber,
          type: documentType,
        ),
      );
      switch (result) {
        case Success(:final data):
          _token = data;
          _lastError = null;
          if (kind == CheckoutKind.cardTransaction &&
              _installments.isNotEmpty) {
            _step = CheckoutStep.installmentSelection;
          }
        case Failure(:final error):
          _lastError = error;
        case Cancelled():
          break;
      }
      return result;
    } finally {
      _setBusy(false);
    }
  }

  CheckoutInstallment? _defaultInstallment(List<CheckoutInstallment> options) {
    for (final option in options) {
      if (option.selected) return option;
    }
    return options.isNotEmpty ? options.first : null;
  }

  void selectInstallment(CheckoutInstallment installment) {
    _selectedInstallment = installment;
    _analytics.track(
      AnalyticsEvent.installmentSelected(installments: installment.installments),
    );
    notifyListeners();
  }

  void goToReview() {
    _step = CheckoutStep.review;
    notifyListeners();
  }

  void backToCardForm() {
    _lastError = null;
    _step = CheckoutStep.cardForm;
    notifyListeners();
  }

  void backToInstallments() {
    _lastError = null;
    _step = CheckoutStep.installmentSelection;
    notifyListeners();
  }

  String get _issuerId {
    final issuers = _selectedMethod?.issuers ?? const [];
    return issuers.isNotEmpty ? issuers.first.id : '';
  }

  /// Builds the final CardSave result.
  MercadoPagoResult<CardSaveResult> buildCardSaveResult() {
    final t = _token;
    final m = _selectedMethod;
    if (t == null || m == null) {
      return const Failure(
        InitializationFailedError(reason: 'Token or payment method missing.'),
      );
    }
    return Success(
      CardSaveResult(
        token: t,
        paymentMethodId: m.id,
        paymentTypeId: m.paymentTypeId,
        issuerId: _issuerId,
      ),
    );
  }

  /// Builds the final CardTransaction result.
  MercadoPagoResult<CardTransactionResult> buildCardTransactionResult() {
    final t = _token;
    final m = _selectedMethod;
    final installment = _selectedInstallment;
    if (t == null || m == null || installment == null) {
      return const Failure(
        InitializationFailedError(reason: 'Required checkout state missing.'),
      );
    }
    return Success(
      CardTransactionResult(
        token: t,
        paymentMethodId: m.id,
        paymentTypeId: m.paymentTypeId,
        issuerId: _issuerId,
        installment: installment,
        transactionAmount: installment.totalAmount,
      ),
    );
  }

  MercadoPagoError mapApi(Object e, ErrorLocation location) =>
      mapApiError(e, location);

  @override
  void dispose() {
    _binDebounce?.cancel();
    super.dispose();
  }
}
