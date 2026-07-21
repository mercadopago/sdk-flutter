import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';
import 'package:mercadopago_flutter_sdk/src/checkout/checkout_controller.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/card_bin_data.dart';
import 'package:mercadopago_flutter_sdk/src/domain/models/card_form_config.dart';

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
  FakeAnalyticsService? analytics,
  double? amount,
  List<String> excludedPaymentTypes = const [],
  List<String> excludedPaymentMethods = const [],
}) {
  return CheckoutController(
    kind: kind,
    coreMethods: _buildCoreMethods(tokens: tokens),
    cardFormRepository: cardForm ?? FakeCardFormRepository(),
    analytics: analytics ?? FakeAnalyticsService(),
    amount: amount,
    payerEmail:
        kind == CheckoutKind.cardTransaction ? 'buyer@example.com' : null,
    excludedPaymentTypes: excludedPaymentTypes,
    excludedPaymentMethods: excludedPaymentMethods,
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

    test('initialize tracks checkout_start with the checkout type', () async {
      final analytics = FakeAnalyticsService();
      final ctrl = _build(analytics: analytics);
      await ctrl.initialize();
      final start = analytics.events.first;
      expect(start.path, '/checkout_api_native/checkout/card_form/initialize');
      expect(start.data['checkout_type'], 'card_save');
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
    test('onBinChanged resolves method + installments from the BFF', () async {
      final ctrl = _build(cardForm: FakeCardFormRepository(binData: _binData));
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      expect(ctrl.selectedMethod?.id, 'visa');
      expect(ctrl.installments.length, 2);
      expect(ctrl.securityCodeLength, 3);
      ctrl.dispose();
    });

    test('onBinChanged passes exclusions to the BFF params', () async {
      final cardForm = FakeCardFormRepository(binData: _binData);
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        amount: 100,
        cardForm: cardForm,
        excludedPaymentTypes: const ['debit_card'],
        excludedPaymentMethods: const ['amex'],
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      expect(cardForm.lastBinParams?.excludedPaymentTypes, ['debit_card']);
      expect(cardForm.lastBinParams?.excludedPaymentMethods, ['amex']);
      expect(cardForm.lastBinParams?.amount, 100);
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

    test('isBusy is true during submit and false after', () async {
      final ctrl = _build();
      expect(ctrl.isBusy, isFalse);
      final future = _submit(ctrl);
      expect(ctrl.isBusy, isTrue);
      await future;
      expect(ctrl.isBusy, isFalse);
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

    test('buildCardSaveResult carries method + issuer from the BIN', () async {
      final ctrl = _build(cardForm: FakeCardFormRepository(binData: _binData));
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      final result = ctrl.buildCardSaveResult();
      expect(result, isA<Success<CardSaveResult>>());
      final data = (result as Success<CardSaveResult>).data;
      expect(data.paymentMethodId, 'visa');
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
    test('requires amount', () {
      expect(
        () => CheckoutController(
          kind: CheckoutKind.cardTransaction,
          coreMethods: _buildCoreMethods(),
          cardFormRepository: FakeCardFormRepository(),
          analytics: FakeAnalyticsService(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('advances to installment selection after BIN + tokenization',
        () async {
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        amount: 100,
        cardForm: FakeCardFormRepository(binData: _binData),
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      expect(ctrl.step, CheckoutStep.installmentSelection);
      ctrl.dispose();
    });

    test('selectInstallment updates selection and builds the result',
        () async {
      final analytics = FakeAnalyticsService();
      final ctrl = _build(
        kind: CheckoutKind.cardTransaction,
        amount: 100,
        cardForm: FakeCardFormRepository(binData: _binData),
        analytics: analytics,
      );
      ctrl.onBinChanged('45099535');
      await _settleDebounce();
      await _submit(ctrl);
      ctrl.selectInstallment(ctrl.installments[1]);
      expect(ctrl.selectedInstallment?.installments, 3);
      expect(
        analytics.events.any(
          (e) => e.path == '/checkout_api_native/checkout/installments/selected',
        ),
        isTrue,
      );

      final result = ctrl.buildCardTransactionResult();
      expect(result, isA<Success<CardTransactionResult>>());
      final data = (result as Success<CardTransactionResult>).data;
      expect(data.installments, 3);
      expect(data.transactionAmount, 105);
      ctrl.dispose();
    });
  });
}
