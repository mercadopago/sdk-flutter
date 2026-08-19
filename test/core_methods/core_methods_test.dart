import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/mercadopago.dart';
import 'package:mercadopago/src/core/api_error.dart';

import '../_fakes/fake_analytics_service.dart';
import '../_fakes/fake_fingerprint_service.dart';
import '../_fakes/fake_repositories.dart';

CoreMethods buildCoreMethods({
  FakeTokenRepository? tokens,
  FakePaymentMethodRepository? paymentMethods,
  FakeInstallmentRepository? installments,
  FakeIssuerRepository? issuers,
  FakeIdentificationRepository? identification,
  FakeAnalyticsService? analytics,
}) {
  return CoreMethods(
    tokenRepository: tokens ?? FakeTokenRepository(),
    paymentMethodRepository: paymentMethods ?? FakePaymentMethodRepository(),
    installmentRepository: installments ?? FakeInstallmentRepository(),
    issuerRepository: issuers ?? FakeIssuerRepository(),
    identificationRepository:
        identification ?? FakeIdentificationRepository(),
    fingerprintService: FakeFingerprintService(),
    analytics: analytics ?? FakeAnalyticsService(),
  );
}

/// A payment method that requires a 4-digit CVV (like Amex).
PaymentMethod _fourDigitCvvMethod() => const PaymentMethod(
      id: 'amex',
      name: 'American Express',
      paymentTypeId: 'credit_card',
      status: 'active',
      thumbnail: '',
      secureThumbnail: '',
      minAllowedAmount: 0,
      maxAllowedAmount: double.infinity,
      accreditationTime: 0,
      additionalInfoNeeded: [],
      binLengthMin: 15,
      binLengthMax: 15,
      securityCodeLength: 4,
      securityCodeLocation: 'front',
    );

/// Helper: creates a [PciFieldState] pre-filled with [value].
PciFieldState pci(String value) => PciFieldState()..update(value);

void main() {
  group('createTokenForNewCard', () {
    test('returns Success on valid input', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      expect(result, isA<Success<CardToken>>());
    });

    test('returns Failure(InvalidCardNumberError) when Luhn fails', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111112'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      expect(result, isA<Failure<CardToken>>());
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<InvalidCardNumberError>());
    });

    test('returns Failure(InvalidCvvError) when CVV length wrong', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('1'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<InvalidCvvError>());
    });

    test('rejects a CVV whose length != the card securityCodeLength',
        () async {
      // The card (Amex) requires 4 digits; a 3-digit CVV must be rejected.
      final cm = buildCoreMethods(
        paymentMethods:
            FakePaymentMethodRepository(response: [_fourDigitCvvMethod()]),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });

    test('returns Failure(CardExpiredError) when expiry is in the past',
        () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('123'),
        expirationDate: pci('0120'), // January 2020 — expired
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<CardExpiredError>());
    });

    test('returns Failure(NetworkError) when repository throws ApiException',
        () async {
      final cm = buildCoreMethods(
        tokens: FakeTokenRepository(
          error: const ApiException(message: 'boom', statusCode: 500),
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<NetworkError>());
      expect((failure.error as NetworkError).isRetriable, isTrue);
    });
  });

  group('createTokenForSavedCard', () {
    test('returns Success with only cardId + CVV (no expiration)', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('123'),
      );
      expect(result, isA<Success<CardToken>>());
    });

    test('accepts an optional PCI expiration field (MMYY)', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('123'),
        expirationDate: pci('1230'),
      );
      expect(result, isA<Success<CardToken>>());
    });

    test('rejects an empty cardId', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: '',
        securityCode: pci('123'),
      );
      expect((result as Failure<CardToken>).error, isA<ValidationError>());
    });

    test('rejects an invalid CVV length', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('1'),
      );
      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });
  });

  group('getPaymentMethods', () {
    test('returns Failure(BinIsEmptyError) on empty bin', () async {
      final cm = buildCoreMethods();
      final result = await cm.getPaymentMethods(bin: '');
      expect(
        (result as Failure<List<PaymentMethod>>).error,
        isA<BinIsEmptyError>(),
      );
    });

    test('returns Success on non-empty bin', () async {
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(response: const []),
      );
      final result = await cm.getPaymentMethods(bin: '423456');
      expect(result, isA<Success<List<PaymentMethod>>>());
    });

    test('fires the payment_methods analytics track', () async {
      final analytics = FakeAnalyticsService();
      final cm = buildCoreMethods(analytics: analytics);
      await cm.getPaymentMethods(bin: '45099535');
      expect(
        analytics.events.any(
          (e) => e.path == '/checkout_api_native/core_methods/payment_methods',
        ),
        isTrue,
      );
    });
  });

  group('getInstallments', () {
    test('returns Failure on zero amount', () async {
      final cm = buildCoreMethods();
      final result = await cm.getInstallments(bin: '423456', amount: 0);
      expect(result, isA<Failure<List<Installment>>>());
    });

    test('returns Failure on empty bin', () async {
      final cm = buildCoreMethods();
      final result = await cm.getInstallments(bin: '', amount: 100);
      expect(
        (result as Failure<List<Installment>>).error,
        isA<BinIsEmptyError>(),
      );
    });

    test('returns Success for valid input', () async {
      final cm = buildCoreMethods();
      final result = await cm.getInstallments(bin: '423456', amount: 100);
      expect(result, isA<Success<List<Installment>>>());
    });
  });

  group('getIssuers', () {
    test('rejects empty bin', () async {
      final cm = buildCoreMethods();
      final result = await cm.getIssuers(paymentMethodId: 'visa', bin: '');
      expect((result as Failure<List<Issuer>>).error, isA<BinIsEmptyError>());
    });

    test('rejects empty paymentMethodId', () async {
      final cm = buildCoreMethods();
      final result = await cm.getIssuers(paymentMethodId: '', bin: '423456');
      expect(
        (result as Failure<List<Issuer>>).error,
        isA<ValidationError>(),
      );
    });
  });

  group('getIdentificationTypes', () {
    test('forwards repository results', () async {
      final cm = buildCoreMethods(
        identification: FakeIdentificationRepository(
          response: const [
            IdentificationType(
              id: 'DNI',
              name: 'DNI',
              type: 'number',
              minLength: 7,
              maxLength: 8,
            ),
          ],
        ),
      );
      final result = await cm.getIdentificationTypes();
      expect(result, isA<Success<List<IdentificationType>>>());
      expect(
        (result as Success<List<IdentificationType>>).data.first.id,
        'DNI',
      );
    });
  });
}
