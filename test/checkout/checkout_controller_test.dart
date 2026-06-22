import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';
import 'package:mercadopago_sdk/src/checkout/checkout_controller.dart';

import '../_fakes/fake_analytics_service.dart';
import '../_fakes/fake_fingerprint_service.dart';
import '../_fakes/fake_repositories.dart';

CoreMethods _buildCoreMethods({
  FakeTokenRepository? tokens,
  FakePaymentMethodRepository? paymentMethods,
  FakeInstallmentRepository? installments,
}) {
  return CoreMethods(
    tokenRepository: tokens ?? FakeTokenRepository(),
    paymentMethodRepository: paymentMethods ?? FakePaymentMethodRepository(),
    installmentRepository: installments ?? FakeInstallmentRepository(),
    issuerRepository: FakeIssuerRepository(),
    identificationRepository: FakeIdentificationRepository(),
    fingerprintService: FakeFingerprintService(),
    analytics: FakeAnalyticsService(),
  );
}

const _validCard = NewCardData(
  cardNumber: '4111111111111111',
  cardholderName: 'TEST USER',
  expirationMonth: 12,
  expirationYear: 2030,
  securityCode: '123',
);

void main() {
  group('CheckoutController — CardSave', () {
    test('submitCardForm returns Success on valid data', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(),
        analytics: FakeAnalyticsService(),
      );
      final result = await ctrl.submitCardForm(_validCard);
      expect(result, isA<Success<CardToken>>());
      ctrl.dispose();
    });

    test('concurrent submitCardForm returns Failure on second call', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(),
        analytics: FakeAnalyticsService(),
      );
      // Fire two calls concurrently — second should be rejected immediately.
      final first = ctrl.submitCardForm(_validCard);
      final second = ctrl.submitCardForm(_validCard);
      final secondResult = await second;
      expect(secondResult, isA<Failure<CardToken>>());
      await first;
      ctrl.dispose();
    });

    test('isBusy is true during submit and false after', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(),
        analytics: FakeAnalyticsService(),
      );
      expect(ctrl.isBusy, isFalse);
      final future = ctrl.submitCardForm(_validCard);
      expect(ctrl.isBusy, isTrue);
      await future;
      expect(ctrl.isBusy, isFalse);
      ctrl.dispose();
    });

    test('submitCardForm returns Failure on token error', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(
          tokens: FakeTokenRepository(
            error: Exception('network failure'),
          ),
        ),
        analytics: FakeAnalyticsService(),
      );
      final result = await ctrl.submitCardForm(_validCard);
      expect(result, isA<Failure<CardToken>>());
      ctrl.dispose();
    });
  });

  group('CheckoutController — state navigation', () {
    test('backToCardForm clears lastError', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(
          tokens: FakeTokenRepository(error: Exception('err')),
        ),
        analytics: FakeAnalyticsService(),
      );
      await ctrl.submitCardForm(_validCard);
      expect(ctrl.lastError, isNotNull);
      ctrl.backToCardForm();
      expect(ctrl.lastError, isNull);
      ctrl.dispose();
    });

    test('backToInstallments clears lastError', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(
          tokens: FakeTokenRepository(error: Exception('err')),
        ),
        analytics: FakeAnalyticsService(),
      );
      await ctrl.submitCardForm(_validCard);
      ctrl.backToInstallments();
      expect(ctrl.lastError, isNull);
      ctrl.dispose();
    });

    test('goToReview sets step to review', () {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardSave,
        coreMethods: _buildCoreMethods(),
        analytics: FakeAnalyticsService(),
      );
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
          analytics: FakeAnalyticsService(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('advances to installment selection on successful tokenization', () async {
      final ctrl = CheckoutController(
        kind: CheckoutKind.cardTransaction,
        coreMethods: _buildCoreMethods(
          installments: FakeInstallmentRepository(
            response: [
              const Installment(
                paymentMethodId: 'visa',
                paymentTypeId: 'credit_card',
                issuer: InstallmentIssuer(
                  id: '1',
                  name: 'Test Bank',
                  secureThumbnail: '',
                  thumbnail: '',
                ),
                processingMode: 'aggregator',
                merchantAccountId: null,
                payerCosts: [
                  PayerCost(
                    installments: 1,
                    installmentRate: 0,
                    discountRate: 0,
                    minAllowedAmount: 0,
                    maxAllowedAmount: 9999,
                    installmentAmount: 100,
                    totalAmount: 100,
                    labels: [],
                    paymentMethodOptionId: 'opt1',
                  ),
                ],
              ),
            ],
          ),
        ),
        analytics: FakeAnalyticsService(),
        amount: 100,
        payerEmail: 'test@test.com',
      );
      await ctrl.submitCardForm(_validCard);
      expect(ctrl.step, CheckoutStep.installmentSelection);
      ctrl.dispose();
    });
  });
}
