import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';
import 'package:mercadopago_sdk/src/core/api_error.dart';
import 'package:mercadopago_sdk/src/core_methods/core_methods.dart';

import '../_fakes/fake_analytics_service.dart';
import '../_fakes/fake_fingerprint_service.dart';
import '../_fakes/fake_repositories.dart';

CoreMethods buildCoreMethods({
  FakeTokenRepository? tokens,
  FakePaymentMethodRepository? paymentMethods,
  FakeInstallmentRepository? installments,
  FakeIssuerRepository? issuers,
  FakeIdentificationRepository? identification,
}) {
  return CoreMethods(
    tokenRepository: tokens ?? FakeTokenRepository(),
    paymentMethodRepository: paymentMethods ?? FakePaymentMethodRepository(),
    installmentRepository: installments ?? FakeInstallmentRepository(),
    issuerRepository: issuers ?? FakeIssuerRepository(),
    identificationRepository:
        identification ?? FakeIdentificationRepository(),
    fingerprintService: FakeFingerprintService(),
    analytics: FakeAnalyticsService(),
  );
}

void main() {
  group('createTokenForNewCard', () {
    test('returns Success on valid input', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        const NewCardData(
          cardNumber: '4111 1111 1111 1111',
          cardholderName: 'JOHN DOE',
          expirationMonth: 12,
          expirationYear: 2030,
          securityCode: '123',
        ),
      );
      expect(result, isA<Success<CardToken>>());
    });

    test('returns Failure(InvalidCardNumberError) when Luhn fails', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        const NewCardData(
          cardNumber: '4111111111111112',
          cardholderName: 'JOHN DOE',
          expirationMonth: 12,
          expirationYear: 2030,
          securityCode: '123',
        ),
      );
      expect(result, isA<Failure<CardToken>>());
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<InvalidCardNumberError>());
    });

    test('returns Failure(InvalidCvvError) when CVV length wrong', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        const NewCardData(
          cardNumber: '4111111111111111',
          cardholderName: 'JOHN DOE',
          expirationMonth: 12,
          expirationYear: 2030,
          securityCode: '1',
        ),
      );
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<InvalidCvvError>());
    });

    test('returns Failure(CardExpiredError) when expiry is in the past',
        () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        const NewCardData(
          cardNumber: '4111111111111111',
          cardholderName: 'JOHN DOE',
          expirationMonth: 1,
          expirationYear: 2020,
          securityCode: '123',
        ),
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
        const NewCardData(
          cardNumber: '4111111111111111',
          cardholderName: 'JOHN DOE',
          expirationMonth: 12,
          expirationYear: 2030,
          securityCode: '123',
        ),
      );
      final failure = result as Failure<CardToken>;
      expect(failure.error, isA<NetworkError>());
      expect((failure.error as NetworkError).isRetriable, isTrue);
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
        identification: FakeIdentificationRepository(response: const [
          IdentificationType(
            id: 'DNI',
            name: 'DNI',
            type: 'number',
            minLength: 7,
            maxLength: 8,
          ),
        ]),
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
