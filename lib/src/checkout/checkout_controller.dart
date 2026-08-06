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
import '../domain/models/card_token.dart';
import '../domain/models/mp_cancel_context.dart';
import '../domain/repositories.dart';
import '../domain/result.dart';
import 'mp_payment_data.dart';
import 'mp_user_cancelled_context.dart';

/// Type of checkout flow the user is performing.
enum CheckoutKind { cardSave, cardTransaction }

/// Coordinates state between checkout screens (card form → installments →
/// review) and the underlying data sources.
///
/// The card form is server-driven (`card_payment_brick` BFF). For card
/// transactions the controller also **processes** the order via
/// [OrderRepository] after tokenization + installment selection, so the result
/// carries the resolved order status. Tokenization flows through [CoreMethods]
/// so raw card data never leaves the SDK.
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required this.kind,
    required CoreMethods coreMethods,
    required CardFormRepository cardFormRepository,
    required OrderRepository orderRepository,
    required AnalyticsService analytics,
    this.appearanceStyle = 'system',
    this.sellerCustomization = const [],
    this.excludedPaymentTypes = const [],
    this.excludedPaymentMethods = const [],
    this.minInstallments,
    this.maxInstallments,
    this.orderId,
    this.clientToken,
  })  : _coreMethods = coreMethods,
        _cardForm = cardFormRepository,
        _orders = orderRepository,
        _analytics = analytics,
        assert(
          kind == CheckoutKind.cardSave || orderId != null,
          'CardTransaction requires an order (orderId).',
        );

  final CheckoutKind kind;
  final CoreMethods _coreMethods;
  final CardFormRepository _cardForm;
  final OrderRepository _orders;
  final AnalyticsService _analytics;

  /// `system` / `light` / `dark` — reported in the card_form/initialize track.
  final String appearanceStyle;
  final List<String> sellerCustomization;
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

  CardFormConfig? _config;
  CardFormConfig? get config => _config;

  CardBinData? _binData;
  CardBinMethod? _selectedMethod;
  List<CheckoutInstallment> _installments = const [];
  CheckoutInstallment? _selectedInstallment;
  CardToken? _token;
  MercadoPagoError? _lastError;

  final List<CheckoutScreen> _visitedScreens = [];
  List<MPCancelledFieldState> _fieldStates = const [];

  CardBinData? get binData => _binData;
  CardBinMethod? get selectedMethod => _selectedMethod;
  List<CheckoutInstallment> get installments => _installments;

  /// Active translations, preferring the BIN-refined set over the initial one.
  CardFormTranslations? get translations =>
      _binData?.translations ?? _config?.translations;
  CheckoutInstallment? get selectedInstallment => _selectedInstallment;
  CardToken? get token => _token;
  MercadoPagoError? get lastError => _lastError;

  /// Effective CVV length for the current selection (BIN spec → form default → 3).
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

  void _markScreen(CheckoutScreen screen) {
    if (!_visitedScreens.contains(screen)) _visitedScreens.add(screen);
  }

  /// Records the latest per-field state of the card form for the cancel context.
  /// Called by the card-form screen.
  void setFieldStates(List<MPCancelledFieldState> states) {
    _fieldStates = states;
  }

  /// Loads the server-driven form config and tracks `card_form/initialize`.
  Future<void> initialize() async {
    _analytics.track(
      AnalyticsEvent.checkoutStart(
        checkoutType: _checkoutType.value,
        appearance: appearanceStyle,
        sellerCustomization: sellerCustomization,
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
      _markScreen(CheckoutScreen.cardForm);
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

  /// BIN-lookup amount — server-resolved from the order (never integrator-supplied).
  double get _binLookupAmount => _config?.amount ?? 0;

  /// Resolves methods/issuers/CVV/installments for the BIN. Debounced 300 ms.
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

  /// Tokenizes the card. For CardTransaction, advances to installment selection.
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
        expirationDate: expirationDate,
        securityCode: securityCode,
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
            _markScreen(CheckoutScreen.installments);
            _trackInstallmentsInitialize();
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

  void _trackInstallmentsInitialize() {
    _analytics.track(
      AnalyticsEvent.installmentsInitialize(
        checkoutType: _checkoutType.value,
        paymentMethodId: _selectedMethod?.id ?? '',
        paymentType: _selectedMethod?.paymentTypeId ?? '',
        selectionType: _binData?.selectionType ?? '',
        quotasCount: _installments.length,
        transactionAmount: _config?.amount ?? 0,
        orderId: orderId,
      ),
    );
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
    _markScreen(CheckoutScreen.review);
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

  /// Installments screen dismissed — fires the cancel track and returns to the
  /// card form.
  void cancelInstallments({String reason = 'back_pressed'}) {
    _analytics.track(AnalyticsEvent.installmentsCancel(reason: reason));
    backToCardForm();
  }

  String get _issuerId {
    final issuers = _selectedMethod?.issuers ?? const [];
    return issuers.isNotEmpty ? issuers.first.id : '';
  }

  /// Builds the CardSave payment data (tokenized card). `null` if state missing.
  MPCardSaveData? buildCardSaveData() {
    final t = _token;
    final m = _selectedMethod;
    if (t == null || m == null) {
      _lastError = const InitializationFailedError(
        reason: 'Token or payment method missing.',
      );
      return null;
    }
    return MPCardSaveData(
      token: t,
      paymentMethodId: m.id,
      paymentTypeId: m.paymentTypeId,
      issuerId: _issuerId,
    );
  }

  /// Fires the installments submit track and processes the order via the BFF.
  /// Returns the transaction data on success, or `null` (with [lastError] set).
  Future<MPCardTransactionData?> processTransaction() async {
    final t = _token;
    final m = _selectedMethod;
    final inst = _selectedInstallment;
    final order = orderId;
    if (t == null || m == null || inst == null || order == null) {
      _lastError = const InitializationFailedError(
        reason: 'Required checkout state missing.',
      );
      return null;
    }
    _analytics.track(
      AnalyticsEvent.installmentsSubmit(
        installments: inst.installments,
        installmentAmount: inst.installmentAmount,
        totalAmount: inst.totalAmount,
      ),
    );
    _setBusy(true);
    try {
      final result = await _orders.process(
        OrderProcessParams(
          orderId: order,
          clientToken: clientToken ?? '',
          paymentMethodId: m.id,
          paymentTypeId: m.paymentTypeId,
          token: t.token,
          installments: inst.installments,
          amount: _config?.amount ?? inst.totalAmount,
        ),
      );
      _lastError = null;
      return MPCardTransactionData(
        orderId: result.id,
        orderStatus: result.status,
        paymentMethodId: m.id,
        paymentTypeId: m.paymentTypeId,
        transactionAmount: inst.totalAmount,
        installments: inst.installments,
      );
    } catch (e) {
      _lastError = mapApiError(e, ErrorLocation.installments);
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Builds the cancel context (per-field state + visited screens).
  MPUserCancelledContext buildCancelContext() {
    final fields = List<MPCancelledFieldState>.of(_fieldStates);
    if (kind == CheckoutKind.cardSave) {
      return MPCardSaveCancelled(fields: fields);
    }
    return MPCardTransactionCancelled(
      fields: fields,
      screens: List<CheckoutScreen>.of(_visitedScreens),
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
