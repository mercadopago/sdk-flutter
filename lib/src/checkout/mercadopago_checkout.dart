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
import 'payment_method_config.dart';
import 'screens/card_form_screen.dart';
import 'screens/installment_screen.dart';
import 'screens/review_screen.dart';

/// Entry point for the hosted checkout UI.
///
/// Two flows are supported:
/// * [MercadoPagoCheckout.forCardSave] — tokenize a card for later use.
/// * [MercadoPagoCheckout.forCardTransaction] — tokenize a card and have the
///   user pick installments for an immediate payment.
///
/// Both flows are server-driven: the card form's fields, labels, document
/// types and installment options come from the `card_payment_brick` BFF.
/// Sellers can exclude payment types/brands via [excludedPaymentTypes] and
/// [excludedPaymentMethods].
///
/// Each factory returns a builder. Call `.build()` to get a `Widget` you can
/// push with `Navigator.push` or show inside a modal.
sealed class MercadoPagoCheckout {
  const MercadoPagoCheckout._();

  static CardSaveCheckoutBuilder forCardSave({
    void Function(MercadoPagoResult<CardSaveResult> result)? onResult,
    MPCheckoutAppearance appearance = const MPCheckoutAppearance(),
    List<MPCardType> excludedPaymentTypes = const [],
    List<MPCardBrand> excludedPaymentMethods = const [],
  }) {
    return CardSaveCheckoutBuilder._(
      onResult: onResult,
      appearance: appearance,
      excludedPaymentTypes: excludedPaymentTypes,
      excludedPaymentMethods: excludedPaymentMethods,
    );
  }

  static CardTransactionCheckoutBuilder forCardTransaction({
    required double amount,
    required String payerEmail,
    void Function(MercadoPagoResult<CardTransactionResult> result)? onResult,
    MPCheckoutAppearance appearance = const MPCheckoutAppearance(),
    List<MPCardType> excludedPaymentTypes = const [],
    List<MPCardBrand> excludedPaymentMethods = const [],
    String? orderId,
    String? clientToken,
  }) {
    return CardTransactionCheckoutBuilder._(
      amount: amount,
      payerEmail: payerEmail,
      onResult: onResult,
      appearance: appearance,
      excludedPaymentTypes: excludedPaymentTypes,
      excludedPaymentMethods: excludedPaymentMethods,
      orderId: orderId,
      clientToken: clientToken,
    );
  }
}

class CardSaveCheckoutBuilder {
  CardSaveCheckoutBuilder._({
    required this.onResult,
    required this.appearance,
    required this.excludedPaymentTypes,
    required this.excludedPaymentMethods,
  });

  final void Function(MercadoPagoResult<CardSaveResult> result)? onResult;
  final MPCheckoutAppearance appearance;
  final List<MPCardType> excludedPaymentTypes;
  final List<MPCardBrand> excludedPaymentMethods;

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardSave,
        appearance: appearance,
        excludedPaymentTypes: excludedPaymentTypes,
        excludedPaymentMethods: excludedPaymentMethods,
        onCardSaveResult: onResult,
      );
}

class CardTransactionCheckoutBuilder {
  CardTransactionCheckoutBuilder._({
    required this.amount,
    required this.payerEmail,
    required this.onResult,
    required this.appearance,
    required this.excludedPaymentTypes,
    required this.excludedPaymentMethods,
    required this.orderId,
    required this.clientToken,
  });

  final double amount;
  final String payerEmail;
  final void Function(MercadoPagoResult<CardTransactionResult> result)?
      onResult;
  final MPCheckoutAppearance appearance;
  final List<MPCardType> excludedPaymentTypes;
  final List<MPCardBrand> excludedPaymentMethods;
  final String? orderId;
  final String? clientToken;

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardTransaction,
        amount: amount,
        payerEmail: payerEmail,
        appearance: appearance,
        excludedPaymentTypes: excludedPaymentTypes,
        excludedPaymentMethods: excludedPaymentMethods,
        orderId: orderId,
        clientToken: clientToken,
        onCardTransactionResult: onResult,
      );
}

class _CheckoutHost extends StatefulWidget {
  const _CheckoutHost({
    required this.kind,
    required this.appearance,
    required this.excludedPaymentTypes,
    required this.excludedPaymentMethods,
    this.amount,
    this.payerEmail,
    this.orderId,
    this.clientToken,
    this.onCardSaveResult,
    this.onCardTransactionResult,
  });

  final CheckoutKind kind;
  final MPCheckoutAppearance appearance;
  final List<MPCardType> excludedPaymentTypes;
  final List<MPCardBrand> excludedPaymentMethods;
  final double? amount;
  final String? payerEmail;
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
    _controller = CheckoutController(
      kind: widget.kind,
      coreMethods: sdk.coreMethods,
      cardFormRepository: sdk.cardFormRepository,
      analytics: _analytics,
      amount: widget.amount,
      payerEmail: widget.payerEmail,
      excludedPaymentTypes:
          widget.excludedPaymentTypes.map((t) => t.value).toList(),
      excludedPaymentMethods:
          widget.excludedPaymentMethods.map((b) => b.value).toList(),
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
      data: widget.appearance.toTheme(),
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
