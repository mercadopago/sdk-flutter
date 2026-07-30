import 'package:flutter/material.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../core/mercadopago_sdk.dart';
import '../domain/models/card_save_result.dart';
import '../domain/models/card_transaction_result.dart';
import '../domain/models/mp_cancel_context.dart';
import '../domain/result.dart';
import 'checkout_appearance.dart';
import 'checkout_controller.dart';
import 'mp_order.dart';
import 'payment_method_config.dart';
import 'screens/card_form_screen.dart';
import 'screens/installment_screen.dart';
import 'screens/review_screen.dart';

/// Entry point for the hosted checkout UI.
///
/// Two flows are supported:
/// * [MercadoPagoCheckout.forCardSave] — tokenize a card for later use.
/// * [MercadoPagoCheckout.forCardTransaction] — tokenize a card and let the
///   user pick installments for a payment bound to an [MPOrder].
///
/// Both flows are server-driven: the card form's fields, labels, document
/// types, installment options and (for transactions) the amount come from the
/// `card_payment_brick` BFF. Sellers restrict card types/brands and the
/// installment range via [CardSaveCheckoutBuilder.setPaymentMethodConfiguration]
/// / [CardTransactionCheckoutBuilder.setPaymentMethodConfiguration], matching
/// the native Android/iOS SDKs.
///
/// Each factory returns a builder. Call `.build()` to get a `Widget` you can
/// push with `Navigator.push` or show inside a modal.
sealed class MercadoPagoCheckout {
  const MercadoPagoCheckout._();

  static CardSaveCheckoutBuilder forCardSave({
    void Function(MercadoPagoResult<CardSaveResult> result)? onResult,
    MPCheckoutAppearance appearance = const MPCheckoutAppearance(),
  }) {
    return CardSaveCheckoutBuilder._(
      onResult: onResult,
      appearance: appearance,
    );
  }

  /// Starts a card transaction bound to [order]. The amount is resolved
  /// server-side from the order — it is not passed here (mirroring the native
  /// SDKs). Create the order from your backend via the Orders API.
  static CardTransactionCheckoutBuilder forCardTransaction({
    required MPOrder order,
    void Function(MercadoPagoResult<CardTransactionResult> result)? onResult,
    MPCheckoutAppearance appearance = const MPCheckoutAppearance(),
  }) {
    return CardTransactionCheckoutBuilder._(
      order: order,
      onResult: onResult,
      appearance: appearance,
    );
  }
}

class CardSaveCheckoutBuilder {
  CardSaveCheckoutBuilder._({
    required this.onResult,
    required this.appearance,
  });

  final void Function(MercadoPagoResult<CardSaveResult> result)? onResult;
  final MPCheckoutAppearance appearance;
  MPCardConfig _cardConfig = const MPCardConfig();

  /// Restricts card types/brands (installment range does not apply to card
  /// save). Returns `this` for chaining.
  CardSaveCheckoutBuilder setPaymentMethodConfiguration(
    List<MPPaymentMethodConfig> configs,
  ) {
    _cardConfig = MPCardConfig.from(configs);
    return this;
  }

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardSave,
        appearance: appearance,
        cardConfig: _cardConfig,
        onCardSaveResult: onResult,
      );
}

class CardTransactionCheckoutBuilder {
  CardTransactionCheckoutBuilder._({
    required this.order,
    required this.onResult,
    required this.appearance,
  });

  final MPOrder order;
  final void Function(MercadoPagoResult<CardTransactionResult> result)?
      onResult;
  final MPCheckoutAppearance appearance;
  MPCardConfig _cardConfig = const MPCardConfig();

  /// Restricts card types/brands and the installment range offered. Returns
  /// `this` for chaining.
  CardTransactionCheckoutBuilder setPaymentMethodConfiguration(
    List<MPPaymentMethodConfig> configs,
  ) {
    _cardConfig = MPCardConfig.from(configs);
    return this;
  }

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardTransaction,
        appearance: appearance,
        cardConfig: _cardConfig,
        orderId: order.orderId,
        clientToken: order.clientToken,
        onCardTransactionResult: onResult,
      );
}

class _CheckoutHost extends StatefulWidget {
  const _CheckoutHost({
    required this.kind,
    required this.appearance,
    required this.cardConfig,
    this.orderId,
    this.clientToken,
    this.onCardSaveResult,
    this.onCardTransactionResult,
  });

  final CheckoutKind kind;
  final MPCheckoutAppearance appearance;
  final MPCardConfig cardConfig;
  final String? orderId;
  final String? clientToken;
  final void Function(MercadoPagoResult<CardSaveResult>)? onCardSaveResult;
  final void Function(MercadoPagoResult<CardTransactionResult>)?
      onCardTransactionResult;

  @override
  State<_CheckoutHost> createState() => _CheckoutHostState();
}

class _CheckoutHostState extends State<_CheckoutHost> {
  late final CheckoutController _controller;
  late final AnalyticsService _analytics;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    final sdk = MercadoPagoSDK.shared;
    _analytics = sdk.analytics;
    final installment = widget.cardConfig.installment;
    _controller = CheckoutController(
      kind: widget.kind,
      coreMethods: sdk.coreMethods,
      cardFormRepository: sdk.cardFormRepository,
      analytics: _analytics,
      excludedPaymentTypes:
          widget.cardConfig.excludedTypes.map((t) => t.value).toList(),
      excludedPaymentMethods:
          widget.cardConfig.excludedBrands.map((b) => b.value).toList(),
      minInstallments: installment?.minInstallments,
      maxInstallments: installment?.maxInstallments,
      orderId: widget.orderId,
      clientToken: widget.clientToken,
    );
    _controller.addListener(_onControllerChanged);
    // Loads the server-driven form config and tracks `checkout_start`.
    _controller.initialize();
  }

  @override
  void dispose() {
    try {
      _controller.removeListener(_onControllerChanged);
    } finally {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _onCancel() {
    if (_delivered) return;
    _delivered = true;
    _analytics.track(AnalyticsEvent.checkoutCancel());
    final context = MPCancelContext(step: _controller.step);
    if (widget.kind == CheckoutKind.cardSave) {
      widget.onCardSaveResult?.call(Cancelled<CardSaveResult>(context));
    } else {
      widget
          .onCardTransactionResult
          ?.call(Cancelled<CardTransactionResult>(context));
    }
    _maybePop();
  }

  void _onTokenized() {
    if (widget.kind == CheckoutKind.cardSave) {
      _deliverCardSave();
    }
    // CardTransaction flow naturally advances inside the controller.
  }

  void _onConfirmTransaction() {
    if (_delivered) return;
    _delivered = true;
    _trackComplete();
    widget.onCardTransactionResult
        ?.call(_controller.buildCardTransactionResult());
    _maybePop();
  }

  void _deliverCardSave() {
    if (_delivered) return;
    _delivered = true;
    _trackComplete();
    widget.onCardSaveResult?.call(_controller.buildCardSaveResult());
    _maybePop();
  }

  void _trackComplete() {
    final method = _controller.selectedMethod;
    _analytics.track(
      AnalyticsEvent.checkoutComplete(
        cardBrand: method?.id,
        paymentType: method?.paymentTypeId,
        transactionAmount: _controller.selectedInstallment?.totalAmount,
      ),
    );
  }

  void _maybePop() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.appearance.themeFor(MediaQuery.platformBrightnessOf(context)),
      child: _stepWidget(),
    );
  }

  Widget _stepWidget() {
    switch (_controller.step) {
      case CheckoutStep.initialization:
        return _buildInitializing();
      case CheckoutStep.cardForm:
        return CardFormScreen(
          controller: _controller,
          onCancel: _onCancel,
          onTokenized: _onTokenized,
        );
      case CheckoutStep.installmentSelection:
        return InstallmentScreen(
          controller: _controller,
          onBack: _controller.backToCardForm,
          onContinue: _controller.goToReview,
        );
      case CheckoutStep.review:
        return ReviewScreen(
          controller: _controller,
          onBack: _controller.backToInstallments,
          onConfirm: _onConfirmTransaction,
        );
    }
  }

  Widget _buildInitializing() {
    final error = _controller.lastError;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancel,
        ),
      ),
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load the checkout.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _controller.initialize,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
