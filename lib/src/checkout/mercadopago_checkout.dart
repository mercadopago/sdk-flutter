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
/// Each factory returns a builder. Call `.build(context)` to get a `Widget`
/// you can push with `Navigator.push` or show inside a modal.
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

  static CardTransactionCheckoutBuilder forCardTransaction({
    required double amount,
    required String payerEmail,
    void Function(MercadoPagoResult<CardTransactionResult> result)? onResult,
    MPCheckoutAppearance appearance = const MPCheckoutAppearance(),
  }) {
    return CardTransactionCheckoutBuilder._(
      amount: amount,
      payerEmail: payerEmail,
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

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardSave,
        appearance: appearance,
        onCardSaveResult: onResult,
      );
}

class CardTransactionCheckoutBuilder {
  CardTransactionCheckoutBuilder._({
    required this.amount,
    required this.payerEmail,
    required this.onResult,
    required this.appearance,
  });

  final double amount;
  final String payerEmail;
  final void Function(MercadoPagoResult<CardTransactionResult> result)?
      onResult;
  final MPCheckoutAppearance appearance;

  Widget build() => _CheckoutHost(
        kind: CheckoutKind.cardTransaction,
        amount: amount,
        payerEmail: payerEmail,
        appearance: appearance,
        onCardTransactionResult: onResult,
      );
}

class _CheckoutHost extends StatefulWidget {
  const _CheckoutHost({
    required this.kind,
    required this.appearance,
    this.amount,
    this.payerEmail,
    this.onCardSaveResult,
    this.onCardTransactionResult,
  });

  final CheckoutKind kind;
  final MPCheckoutAppearance appearance;
  final double? amount;
  final String? payerEmail;
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
      analytics: _analytics,
      amount: widget.amount,
      payerEmail: widget.payerEmail,
    );
    _controller.addListener(_onControllerChanged);
    _analytics.track(const AnalyticsEvent.checkoutStart());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _onCancel() {
    if (_delivered) return;
    _delivered = true;
    _analytics.track(const AnalyticsEvent.checkoutCancel());
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
    _analytics.track(const AnalyticsEvent.checkoutComplete());
    widget.onCardTransactionResult
        ?.call(_controller.buildCardTransactionResult());
    _maybePop();
  }

  void _deliverCardSave() {
    if (_delivered) return;
    _delivered = true;
    _analytics.track(const AnalyticsEvent.checkoutComplete());
    widget.onCardSaveResult?.call(_controller.buildCardSaveResult());
    _maybePop();
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
      case CheckoutStep.cardForm:
      case CheckoutStep.initialization:
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
}
