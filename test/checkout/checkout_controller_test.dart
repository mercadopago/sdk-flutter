import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
import 'package:mercadopago_flutter_sdk/src/checkout/checkout_controller.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/card_bin_data.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/card_form_config.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/order_process_result.dart';

import '../_fakes/fake_analytics_service.dart';
import '../_fakes/fake_fingerprint_service.dart';
import '../_fakes/fake_repositories.dart';

CoreMethods _buildCoreMethods({FakeTokenRepository? tokens}) {
  return CoreMethods(
    tokenRepository: tokens ?? FakeTokenRepository(),
    paymentMethodRepository: FakePaymentMethodRepository(),
    installmentRepository: FakeInstallmentRepository(),
    issuerRepository: FakeIssuerRepository(),
    identificationRepository: FakeIdentificationRepository(),
    fingerprintService: FakeFingerprintService(),
    analytics: FakeAnalyticsService(),
  );
}

CheckoutController _build({
  CheckoutKind kind = CheckoutKind.cardSave,
  FakeTokenRepository? tokens,
  FakeCardFormRepository? cardForm,
  FakeOrderRepository? orders,
  FakeAnalyticsService? analytics,
  List<String> excludedPaymentTypes = const [],
  List<String> excludedPaymentMethods = const [],
  int? minInstallments,
  int? maxInstallments,
}) {
  final isTransaction = kind == CheckoutKind.cardTransaction;
  return CheckoutController(
    kind: kind,
    coreMethods: _buildCoreMethods(tokens: tokens),
    cardFormRepository: cardForm ?? FakeCardFormRepository(),
    orderRepository: orders ?? FakeOrderRepository(),
    analytics: analytics ?? FakeAnalyticsService(),
    excludedPaymentTypes: excludedPaymentTypes,
    excludedPaymentMethods: excludedPaymentMethods,
    minInstallments: minInstallments,
    maxInstallments: maxInstallments,
    orderId: isTransaction ? 'order_1' : null,
    clientToken: isTransaction ? 'tok_1' : null,
  );
}

/// Card-BIN data with two installment options and one payment method.
const _binData = CardBinData(
  paymentMethods: [
    CardBinMethod(
      id: 'visa',
      paymentTypeId: 'credit_card',
      securityCode: SecurityCodeSpec(type: 'number', length: 3),
      issuers: [CheckoutIssuer(id: '1', name: 'Test Bank')],
    ),
  ],
  installments: [
    CheckoutInstallment(
      installments: 1,
      installmentAmount: 100,
      totalAmount: 100,
      primaryLabel: '1x 100',
      secondaryLabel: 'Total 100',
    ),
    CheckoutInstallment(
      installments: 3,
      installmentAmount: 35,
      totalAmount: 105,
      primaryLabel: '3x 35',
      secondaryLabel: 'Total 105',
    ),
  ],
);

PciFieldState pci(String value) => PciFieldState()..update(value);

Future<MercadoPagoResult<CardToken>> _submit(CheckoutController ctrl) =>
    ctrl.submitCardForm(
      cardNumber: pci('4111111111111111'),
      securityCode: pci('123'),
      expirationDate: pci('1230'),
      cardholderName: 'TEST USER',
    );

Future<void> _settleDebounce() =>
    Future<void>.delayed(const Duration(milliseconds: 350));

void main() {
  group('CheckoutController — initialization', () {
    test('starts in the initialization step', () {
      final ctrl = _build();
      expect(ctrl.step, CheckoutStep.initialization);
      ctrl.dispose();
    });

    test('initialize loads config and advances to card form', () async {
      final ctrl = _build();
      await ctrl.initialize();
      expect(ctrl.step, CheckoutStep.cardForm);
      expect(ctrl.config, isNotNull);
      expect(ctrl.lastError, isNull);
      ctrl.dispose();
    });

    test('initialize tracks checkout_start with type + appearance', () async {
      final analytics = FakeAnalyticsService();
      final ctrl = _build(analytics: analytics);
      await ctrl.initialize();
      final start = analytics.events.first;
      expect(start.path, '/checkout_api_native/checkout/card_form/initialize');
      expect(start.data['checkout_type'], 'card_save');
      expect(start.data['appearance'], 'system');
      ctrl.dispose();
    });

    test('initialize surfaces an error and stays on initialization', () async {
      final ctrl = _build(
        cardForm: FakeCardFormRepository(initError: Exception('boom')),
      );
      await ctrl.initialize();
      expect(ctrl.step, CheckoutStep.initialization);
      expect(ctrl.lastError, isNotNull);
      ctrl.dispose();
    });
  });

  group('CheckoutController — BIN lookup', () {
    test('onBinChanged passes exclusions + installment bounds to the BFF',
        () async {
      final cardForm = FakeCardFormRepository(binData: _binData);
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        cardForm: cardForm,
        excludedPaymentTypes: const ['debit_card'],
        excludedPaymentMethods: const ['amex'],
        minInstallments: 1,
        maxInstallments: 6,
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      expect(cardForm.lastBinParams?.excludedPaymentTypes, ['debit_card']);
      expect(cardForm.lastBinParams?.excludedPaymentMethods, ['amex']);
      expect(cardForm.lastBinParams?.minInstallments, 1);
      expect(cardForm.lastBinParams?.maxInstallments, 6);
      ctrl.dispose();
    });

    test('BIN lookup amount comes from the server config (order-driven)',
        () async {
      final cardForm =
          FakeCardFormRepository(binData: _binData, configAmount: 250);
      final ctrl =
          _build(kind: CheckoutKind.cardTransaction, cardForm: cardForm);
      await ctrl.initialize();
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      expect(cardForm.lastBinParams?.amount, 250);
      ctrl.dispose();
    });
  });

  group('CheckoutController — CardSave', () {
    test('submitCardForm returns Success on valid data', () async {
      final ctrl = _build();
      final result = await _submit(ctrl);
      expect(result, isA<Success<CardToken>>());
      ctrl.dispose();
    });

    test('concurrent submitCardForm returns Failure on second call', () async {
      final ctrl = _build();
      final first = _submit(ctrl);
      final second = _submit(ctrl);
      expect(await second, isA<Failure<CardToken>>());
      await first;
      ctrl.dispose();
    });

    test('submitCardForm returns Failure on token error', () async {
      final ctrl = _build(
        tokens: FakeTokenRepository(error: Exception('network failure')),
      );
      final result = await _submit(ctrl);
      expect(result, isA<Failure<CardToken>>());
      ctrl.dispose();
    });

    test('buildCardSaveData carries method + issuer from the BIN', () async {
      final ctrl = _build(cardForm: FakeCardFormRepository(binData: _binData));
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      final data = ctrl.buildCardSaveData();
      expect(data, isNotNull);
      expect(data!.paymentMethodId, 'visa');
      expect(data.paymentTypeId, 'credit_card');
      expect(data.issuerId, '1');
      ctrl.dispose();
    });
  });

  group('CheckoutController — state navigation', () {
    test('backToCardForm clears lastError', () async {
      final ctrl = _build(
        tokens: FakeTokenRepository(error: Exception('err')),
      );
      await _submit(ctrl);
      expect(ctrl.lastError, isNotNull);
      ctrl.backToCardForm();
      expect(ctrl.lastError, isNull);
      ctrl.dispose();
    });

    test('goToReview sets step to review', () {
      final ctrl = _build();
      ctrl.goToReview();
      expect(ctrl.step, CheckoutStep.review);
      ctrl.dispose();
    });
  });

  group('CheckoutController — CardTransaction', () {
    test('requires an order (orderId)', () {
      expect(
        () => CheckoutController(
          kind: CheckoutKind.cardTransaction,
          coreMethods: _buildCoreMethods(),
          cardFormRepository: FakeCardFormRepository(),
          orderRepository: FakeOrderRepository(),
          analytics: FakeAnalyticsService(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('advances to installment selection after BIN + tokenization',
        () async {
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        cardForm: FakeCardFormRepository(binData: _binData),
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      expect(ctrl.step, CheckoutStep.installmentSelection);
      ctrl.dispose();
    });

    test('processTransaction processes the order and returns its status',
        () async {
      final analytics = FakeAnalyticsService();
      final orders = FakeOrderRepository(
        result: const OrderProcessResult(id: 'ord_99', status: 'processed'),
      );
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        cardForm: FakeCardFormRepository(binData: _binData),
        orders: orders,
        analytics: analytics,
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      ctrl.selectInstallment(ctrl.installments[1]);
      expect(ctrl.selectedInstallment?.installments, 3);
      expect(
        analytics.events.any(
          (e) =>
              e.path == '/checkout_api_native/checkout/installments/selected',
        ),
        isTrue,
      );

      final data = await ctrl.processTransaction();
      expect(data, isNotNull);
      expect(data!.orderId, 'ord_99');
      expect(data.orderStatus, 'processed');
      expect(data.installments, 3);
      expect(data.transactionAmount, 105);
      // The /process request carried the selected installment + token.
      expect(orders.lastParams?.installments, 3);
      expect(orders.lastParams?.orderId, 'order_1');
      expect(
        analytics.events.any(
          (e) => e.path == '/checkout_api_native/checkout/installments/submit',
        ),
        isTrue,
      );
      ctrl.dispose();
    });
  });
}
