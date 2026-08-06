import 'package:flutter/material.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../core/mercadopago_sdk.dart';
import '../domain/errors.dart';
import '../domain/models/mp_cancel_context.dart';
import 'checkout_appearance.dart';
import 'checkout_controller.dart';
import 'mp_checkout_result.dart';
import 'mp_checkout_type.dart';
import 'mp_order.dart';
import 'mp_payment_data.dart';
import 'payment_method_config.dart';
import 'screens/card_form_screen.dart';
import 'screens/installment_screen.dart';
import 'screens/review_screen.dart';

/// Entry point for the hosted checkout UI.
///
/// A single builder adapts to the [MPCheckoutType] passed in (mirroring the
/// native SDKs' unified `Builder`): `MPCheckoutType.cardSave()` or
/// `MPCheckoutType.cardTransaction(order)`. The phantom generic makes the
/// `onResult` callback statically typed. Configure with
/// [setPaymentMethodConfiguration], then [show] it:
///
/// ```dart
/// MercadoPagoCheckout(
///   MPCheckoutType.cardTransaction(
///     MPOrder(orderId: orderId, clientToken: clientToken),
///   ),
///   appearance: const MPCheckoutAppearance(),
/// )
///     .setPaymentMethodConfiguration([
///       MPPaymentMethodConfig.card(installment: MPInstallment(maxInstallments: 3)),
///     ])
///     .show(context, onResult: (result) {
///       switch (result) {
///         case CheckoutSuccess(:final data): // ...
///         case CheckoutError(:final error): // ...
///         case CheckoutUserCancelled(:final context): // ...
///       }
///     });
/// ```
class MercadoPagoCheckout<T extends MPPaymentData> {
  MercadoPagoCheckout(
    this.checkoutType, {
    this.appearance = const MPCheckoutAppearance(),
  });

  final MPCheckoutType<T> checkoutType;
  final MPCheckoutAppearance appearance;
  MPCardConfig _cardConfig = const MPCardConfig();

  /// Restricts card types/brands and the installment range. Returns `this`.
  MercadoPagoCheckout<T> setPaymentMethodConfiguration(
    List<MPPaymentMethodConfig> configs,
  ) {
    _cardConfig = MPCardConfig.from(configs);
    return this;
  }

  /// Pushes the checkout onto the [Navigator] and delivers the typed result to
  /// [onResult]. Mirrors the native `show`.
  void show(
    BuildContext context, {
    required void Function(MercadoPagoCheckoutResult<T> result) onResult,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => build(onResult: onResult)),
    );
  }

  /// Returns the checkout as a `Widget` (for embedding or tests). Most apps
  /// should use [show].
  Widget build({
    required void Function(MercadoPagoCheckoutResult<T> result) onResult,
  }) {
    final (kind, order) = switch (checkoutType) {
      MPCardTransactionCheckout(:final order) => (
          CheckoutKind.cardTransaction,
          order,
        ),
      MPCardSaveCheckout() => (CheckoutKind.cardSave, null),
    };
    return _CheckoutHost<T>(
      kind: kind,
      appearance: appearance,
      cardConfig: _cardConfig,
      order: order,
      onResult: onResult,
    );
  }
}

class _CheckoutHost<T extends MPPaymentData> extends StatefulWidget {
  const _CheckoutHost({
    required this.kind,
    required this.appearance,
    required this.cardConfig,
    required this.onResult,
    this.order,
  });

  final CheckoutKind kind;
  final MPCheckoutAppearance appearance;
  final MPCardConfig cardConfig;
  final MPOrder? order;
  final void Function(MercadoPagoCheckoutResult<T>) onResult;

  @override
  State<_CheckoutHost<T>> createState() => _CheckoutHostState<T>();
}

class _CheckoutHostState<T extends MPPaymentData>
    extends State<_CheckoutHost<T>> {
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
      orderRepository: sdk.orderRepository,
      analytics: _analytics,
      appearanceStyle: widget.appearance.analyticsStyle,
      sellerCustomization: widget.appearance.sellerCustomization,
      excludedPaymentTypes:
          widget.cardConfig.excludedTypes.map((t) => t.value).toList(),
      excludedPaymentMethods:
          widget.cardConfig.excludedBrands.map((b) => b.value).toList(),
      minInstallments: installment?.minInstallments,
      maxInstallments: installment?.maxInstallments,
      orderId: widget.order?.orderId,
      clientToken: widget.order?.clientToken,
    );
    _controller.addListener(_onControllerChanged);
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
    widget.onResult(CheckoutUserCancelled<T>(_controller.buildCancelContext()));
    _maybePop();
  }

  void _onTokenized() {
    if (widget.kind == CheckoutKind.cardSave) {
      _deliverCardSave();
    }
    // CardTransaction advances to installments inside the controller.
  }

  void _deliverCardSave() {
    if (_delivered) return;
    final data = _controller.buildCardSaveData();
    _delivered = true;
    if (data != null) {
      _trackComplete();
      widget.onResult(CheckoutSuccess<T>(data as T));
    } else {
      widget.onResult(_errorResult());
    }
    _maybePop();
  }

  Future<void> _onConfirmTransaction() async {
    if (_delivered) return;
    final data = await _controller.processTransaction();
    if (!mounted || _delivered) return;
    _delivered = true;
    if (data != null) {
      _trackComplete();
      widget.onResult(CheckoutSuccess<T>(data as T));
    } else {
      widget.onResult(_errorResult());
    }
    _maybePop();
  }

  MercadoPagoCheckoutResult<T> _errorResult() => CheckoutError<T>(
        _controller.lastError ??
            const UnknownError(message: 'Checkout failed.'),
      );

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
      data:
          widget.appearance.themeFor(MediaQuery.platformBrightnessOf(context)),
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
          onBack: () => _controller.cancelInstallments(),
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
