import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_client.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_error.dart';
import 'package:mercadopago_sdk_flutter/src/core/session_manager.dart';
import 'package:mercadopago_sdk_flutter/src/pci/pci.dart'
    show PciTokenizer, debugSeedPciField;

import '../_fakes/fake_analytics_service.dart';
import '../_fakes/fake_fingerprint_service.dart';
import '../_fakes/fake_repositories.dart';

/// Default tokenization response: the leanest successful card token.
MockClient _successfulTokenization() =>
    MockClient((_) async => http.Response('{"id":"tok_test"}', 201));

/// Builds a [CoreMethods] whose tokenizer talks to [httpClient].
///
/// Tokenization is steered through the HTTP client rather than a fake
/// repository: [PciTokenizer] is `final` and owns the only code that reads a
/// raw PCI value, so the request body is the outermost observable point.
CoreMethods buildCoreMethods({
  MockClient? httpClient,
  FakePaymentMethodRepository? paymentMethods,
  FakeInstallmentRepository? installments,
  FakeIssuerRepository? issuers,
  FakeIdentificationRepository? identification,
  FakeAnalyticsService? analytics,
  FakeFingerprintService? fingerprintService,
  Duration cvvMetadataTimeout = const Duration(seconds: 2),
}) {
  final api = ApiClient(
    sessionManager: SessionManager(),
    publicKey: 'APP_USR-1234567890',
    httpClient: httpClient ?? _successfulTokenization(),
  );
  addTearDown(api.close);
  return CoreMethods(
    tokenizer: PciTokenizer(api: api),
    paymentMethodRepository: paymentMethods ?? FakePaymentMethodRepository(),
    installmentRepository: installments ?? FakeInstallmentRepository(),
    issuerRepository: issuers ?? FakeIssuerRepository(),
    identificationRepository: identification ?? FakeIdentificationRepository(),
    fingerprintService: fingerprintService ?? FakeFingerprintService(),
    analytics: analytics ?? FakeAnalyticsService(),
    cvvMetadataTimeout: cvvMetadataTimeout,
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
  cardNumberLengthMin: 15,
  cardNumberLengthMax: 15,
  securityCodeLength: 4,
  securityCodeLocation: 'front',
);

/// A payment method that requires a 3-digit CVV (like Visa).
PaymentMethod _threeDigitCvvMethod() => const PaymentMethod(
  id: 'visa',
  name: 'Visa',
  paymentTypeId: 'credit_card',
  status: 'active',
  thumbnail: '',
  secureThumbnail: '',
  minAllowedAmount: 0,
  maxAllowedAmount: double.infinity,
  accreditationTime: 0,
  additionalInfoNeeded: [],
  cardNumberLengthMin: 16,
  cardNumberLengthMax: 16,
  securityCodeLength: 3,
  securityCodeLocation: 'back',
);

PaymentMethod _methodWithoutCardMetadata() => const PaymentMethod(
  id: 'account_money',
  name: 'Account money',
  paymentTypeId: 'account_money',
  status: 'active',
  thumbnail: '',
  secureThumbnail: '',
  minAllowedAmount: 0,
  maxAllowedAmount: double.infinity,
  accreditationTime: 0,
  additionalInfoNeeded: [],
);

/// Helper: creates a [PciFieldState] pre-filled with [value].
PciFieldState pci(String value) {
  final state = PciFieldState();
  debugSeedPciField(state, value);
  return state;
}

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

    test('clears every PCI controller after successful tokenization', () async {
      final cm = buildCoreMethods();
      final cardNumber = pci('4111111111111111');
      final securityCode = pci('123');
      final expirationDate = pci('1230');

      final result = await cm.createTokenForNewCard(
        cardNumber: cardNumber,
        securityCode: securityCode,
        expirationDate: expirationDate,
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(result, isA<Success<CardToken>>());
      expect(cardNumber.length, 0);
      expect(securityCode.length, 0);
      expect(expirationDate.length, 0);
    });

    test(
      'does not clear values edited while new-card request is in flight',
      () async {
        final requestStarted = Completer<void>();
        final response = Completer<http.Response>();
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async {
            if (!requestStarted.isCompleted) requestStarted.complete();
            return response.future;
          }),
        );
        final cardNumber = pci('4111111111111111');
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final request = cm.createTokenForNewCard(
          cardNumber: cardNumber,
          securityCode: securityCode,
          expirationDate: expirationDate,
          identification: const BuyerIdentification(name: 'JOHN DOE'),
        );
        await requestStarted.future;
        // Every mid-flight edit has a different length than the value the
        // request captured, so the length assertions below can only hold if
        // the edit survived.
        debugSeedPciField(cardNumber, '411111111111111');
        debugSeedPciField(securityCode, '4567');
        debugSeedPciField(expirationDate, '113');
        response.complete(http.Response('{"id":"tok_snapshot"}', 201));

        expect(await request, isA<Success<CardToken>>());
        expect(cardNumber.length, 15);
        expect(securityCode.length, 4);
        expect(expirationDate.length, 3);
      },
    );

    test(
      'revalidates PCI fields changed while fingerprint collection is pending',
      () async {
        final fingerprintStarted = Completer<void>();
        final releaseFingerprint = Completer<void>();
        var tokenizationRequests = 0;
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async {
            tokenizationRequests++;
            return http.Response('{"id":"tok_unexpected"}', 201);
          }),
          fingerprintService: FakeFingerprintService(
            collectionBarrier: releaseFingerprint.future,
            onCollect: fingerprintStarted.complete,
          ),
        );
        final cardNumber = pci('4111111111111111');
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final request = cm.createTokenForNewCard(
          cardNumber: cardNumber,
          securityCode: securityCode,
          expirationDate: expirationDate,
          identification: const BuyerIdentification(name: 'JOHN DOE'),
        );
        await fingerprintStarted.future;
        debugSeedPciField(cardNumber, '4111111111111112');
        debugSeedPciField(securityCode, '1');
        debugSeedPciField(expirationDate, '1329');
        releaseFingerprint.complete();

        final result = await request;
        expect((result as Failure<CardToken>).error, isA<ValidationError>());
        expect(tokenizationRequests, 0);
      },
    );

    test(
      'aborts a valid cross-BIN edit while fingerprint collection is pending',
      () async {
        final fingerprintStarted = Completer<void>();
        final releaseFingerprint = Completer<void>();
        var tokenizationRequests = 0;
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async {
            tokenizationRequests++;
            return http.Response('{"id":"tok_unexpected"}', 201);
          }),
          paymentMethods: FakePaymentMethodRepository(
            response: [_threeDigitCvvMethod()],
          ),
          fingerprintService: FakeFingerprintService(
            collectionBarrier: releaseFingerprint.future,
            onCollect: fingerprintStarted.complete,
          ),
        );
        final cardNumber = pci('4111111111111111');
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final request = cm.createTokenForNewCard(
          cardNumber: cardNumber,
          securityCode: securityCode,
          expirationDate: expirationDate,
          identification: const BuyerIdentification(name: 'JOHN DOE'),
        );
        await fingerprintStarted.future;
        // Both replacements are valid, but belong to another BIN/CVV rule.
        debugSeedPciField(cardNumber, '378282246310005');
        debugSeedPciField(securityCode, '1234');
        releaseFingerprint.complete();

        final result = await request;
        expect((result as Failure<CardToken>).error, isA<ValidationError>());
        expect(tokenizationRequests, 0);
      },
    );

    test('aborts an edit while BIN metadata is pending', () async {
      final metadata = Completer<List<PaymentMethod>>();
      var tokenizationRequests = 0;
      final cm = buildCoreMethods(
        httpClient: MockClient((_) async {
          tokenizationRequests++;
          return http.Response('{"id":"tok_unexpected"}', 201);
        }),
        paymentMethods: FakePaymentMethodRepository(
          responseFuture: metadata.future,
        ),
      );
      final cardNumber = pci('4111111111111111');
      final securityCode = pci('123');
      final expirationDate = pci('1230');

      final request = cm.createTokenForNewCard(
        cardNumber: cardNumber,
        securityCode: securityCode,
        expirationDate: expirationDate,
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      debugSeedPciField(cardNumber, '378282246310005');
      debugSeedPciField(securityCode, '1234');
      metadata.complete([_threeDigitCvvMethod()]);

      final result = await request;
      expect((result as Failure<CardToken>).error, isA<ValidationError>());
      expect(tokenizationRequests, 0);
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

    test('rejects PANs outside the 13-19 digit range', () async {
      final cm = buildCoreMethods();

      for (final cardNumber in ['0', '00000000000000000000']) {
        final result = await cm.createTokenForNewCard(
          cardNumber: pci(cardNumber),
          securityCode: pci('123'),
          expirationDate: pci('1230'),
          identification: const BuyerIdentification(name: 'JOHN DOE'),
        );

        expect(
          (result as Failure<CardToken>).error,
          isA<InvalidCardNumberError>(),
        );
      }
    });

    test('rejects a non-numeric PAN', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('411111111111111a'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(
        (result as Failure<CardToken>).error,
        isA<InvalidCardNumberError>(),
      );
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

    test('returns Failure(InvalidCvvError) when CVV is not numeric', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('abc'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });

    test('rejects a CVV whose length != the card securityCodeLength', () async {
      // The card (Amex) requires 4 digits; a 3-digit CVV must be rejected.
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          response: [_fourDigitCvvMethod()],
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('378282246310005'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );
      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });

    test('accepts a 4-digit CVV when BIN metadata requires it', () async {
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          response: [_fourDigitCvvMethod()],
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('378282246310005'),
        securityCode: pci('1234'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(result, isA<Success<CardToken>>());
    });

    test('rejects a PAN length outside the payment-method metadata', () async {
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          response: [_fourDigitCvvMethod()],
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('1234'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(
        (result as Failure<CardToken>).error,
        isA<InvalidCardNumberError>(),
      );
    });

    test('does not invent rules when native card metadata is absent', () async {
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          response: [_methodWithoutCardMetadata()],
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('123'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(result, isA<Success<CardToken>>());
    });

    test('does not invent a 3-digit CVV rule when BIN lookup fails', () async {
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          error: const ApiException(message: 'payment methods unavailable'),
        ),
      );
      final result = await cm.createTokenForNewCard(
        cardNumber: pci('4111111111111111'),
        securityCode: pci('1234'),
        expirationDate: pci('1230'),
        identification: const BuyerIdentification(name: 'JOHN DOE'),
      );

      expect(result, isA<Success<CardToken>>());
    });

    test(
      'does not block tokenization when BIN metadata lookup times out',
      () async {
        final pending = Completer<List<PaymentMethod>>();
        final cm = buildCoreMethods(
          paymentMethods: FakePaymentMethodRepository(
            responseFuture: pending.future,
          ),
          cvvMetadataTimeout: const Duration(milliseconds: 1),
        );

        final result = await cm.createTokenForNewCard(
          cardNumber: pci('4111111111111111'),
          securityCode: pci('1234'),
          expirationDate: pci('1230'),
          identification: const BuyerIdentification(name: 'JOHN DOE'),
        );

        expect(result, isA<Success<CardToken>>());
      },
    );

    test('requires identification type and number together', () async {
      for (final identification in const [
        BuyerIdentification(name: 'JOHN DOE', type: 'DNI'),
        BuyerIdentification(name: 'JOHN DOE', number: '12345678'),
        BuyerIdentification(name: 'JOHN DOE', type: ' ', number: '12345678'),
        BuyerIdentification(name: 'JOHN DOE', type: 'DNI', number: ' '),
        BuyerIdentification(name: 'JOHN DOE', type: ' ', number: ' '),
      ]) {
        final result = await buildCoreMethods().createTokenForNewCard(
          cardNumber: pci('4111111111111111'),
          securityCode: pci('123'),
          expirationDate: pci('1230'),
          identification: identification,
        );

        final error = (result as Failure<CardToken>).error;
        expect(error, isA<ValidationError>());
        expect((error as ValidationError).field, 'identification');
      }
    });

    test(
      'returns Failure(CardExpiredError) when expiry is in the past',
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
      },
    );

    test(
      'returns Failure(NetworkError) when repository throws ApiException',
      () async {
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async => http.Response('', 500)),
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
      },
    );
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

    test(
      'maps repository failures and tracks saved-card tokenization errors',
      () async {
        final analytics = FakeAnalyticsService();
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async => http.Response('', 503)),
          analytics: analytics,
        );

        final result = await cm.createTokenForSavedCard(
          cardId: 'card_123',
          securityCode: pci('123'),
        );

        expect((result as Failure<CardToken>).error, isA<NetworkError>());
        expect(analytics.events.single.path, contains('tokenization/error'));
      },
    );

    test('accepts an optional PCI expiration field (MMYY)', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('123'),
        expirationDate: pci('1230'),
      );
      expect(result, isA<Success<CardToken>>());
    });

    test(
      'clears supplied PCI controllers after successful tokenization',
      () async {
        final cm = buildCoreMethods();
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final result = await cm.createTokenForSavedCard(
          cardId: 'card_123',
          securityCode: securityCode,
          expirationDate: expirationDate,
        );

        expect(result, isA<Success<CardToken>>());
        expect(securityCode.length, 0);
        expect(expirationDate.length, 0);
      },
    );

    test(
      'does not clear values edited while saved-card request is in flight',
      () async {
        final requestStarted = Completer<void>();
        final response = Completer<http.Response>();
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async {
            if (!requestStarted.isCompleted) requestStarted.complete();
            return response.future;
          }),
        );
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final request = cm.createTokenForSavedCard(
          cardId: 'card_123',
          securityCode: securityCode,
          expirationDate: expirationDate,
        );
        await requestStarted.future;
        // Different lengths than the captured values, so the assertions below
        // distinguish "edit preserved" from "cleared and re-seeded".
        debugSeedPciField(securityCode, '4567');
        debugSeedPciField(expirationDate, '113');
        response.complete(http.Response('{"id":"tok_snapshot"}', 201));

        expect(await request, isA<Success<CardToken>>());
        expect(securityCode.length, 4);
        expect(expirationDate.length, 3);
      },
    );

    test(
      'aborts saved-card fields changed while fingerprint is pending',
      () async {
        final fingerprintStarted = Completer<void>();
        final releaseFingerprint = Completer<void>();
        var tokenizationRequests = 0;
        final cm = buildCoreMethods(
          httpClient: MockClient((_) async {
            tokenizationRequests++;
            return http.Response('{"id":"tok_unexpected"}', 201);
          }),
          fingerprintService: FakeFingerprintService(
            collectionBarrier: releaseFingerprint.future,
            onCollect: fingerprintStarted.complete,
          ),
        );
        final securityCode = pci('123');
        final expirationDate = pci('1230');

        final request = cm.createTokenForSavedCard(
          cardId: 'card_123',
          securityCode: securityCode,
          expirationDate: expirationDate,
        );
        await fingerprintStarted.future;
        debugSeedPciField(securityCode, '1');
        debugSeedPciField(expirationDate, '1329');
        releaseFingerprint.complete();

        final result = await request;
        expect((result as Failure<CardToken>).error, isA<ValidationError>());
        expect(tokenizationRequests, 0);
      },
    );

    test('rejects an empty cardId', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: '',
        securityCode: pci('123'),
      );
      expect((result as Failure<CardToken>).error, isA<ValidationError>());
    });

    test('rejects a whitespace-only cardId', () async {
      final result = await buildCoreMethods().createTokenForSavedCard(
        cardId: '   ',
        securityCode: pci('123'),
      );

      expect((result as Failure<CardToken>).error, isA<ValidationError>());
    });

    test('trims a valid cardId before sending it to the API', () async {
      late http.Request captured;
      final cm = buildCoreMethods(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"id":"tok_test"}', 201);
        }),
      );

      final result = await cm.createTokenForSavedCard(
        cardId: '  card_123  ',
        securityCode: pci('123'),
      );

      expect(result, isA<Success<CardToken>>());
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['card_id'], 'card_123');
    });

    test('rejects an invalid CVV length', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('1'),
      );
      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });

    test('rejects a non-numeric CVV', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('abc'),
      );

      expect((result as Failure<CardToken>).error, isA<InvalidCvvError>());
    });

    test('rejects a supplied malformed expiration date', () async {
      final cm = buildCoreMethods();

      for (final expiration in ['', '123', '1329', 'ab29']) {
        final result = await cm.createTokenForSavedCard(
          cardId: 'card_123',
          securityCode: pci('123'),
          expirationDate: pci(expiration),
        );

        expect(
          (result as Failure<CardToken>).error,
          isA<InvalidExpirationDateError>(),
        );
      }
    });

    test('rejects a supplied expired expiration date', () async {
      final cm = buildCoreMethods();
      final result = await cm.createTokenForSavedCard(
        cardId: 'card_123',
        securityCode: pci('123'),
        expirationDate: pci('0120'),
      );

      expect((result as Failure<CardToken>).error, isA<CardExpiredError>());
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

    test('returns Success on an 8-digit bin', () async {
      final repository = FakePaymentMethodRepository(response: const []);
      final cm = buildCoreMethods(paymentMethods: repository);
      final result = await cm.getPaymentMethods(bin: '42345678');
      expect(result, isA<Success<List<PaymentMethod>>>());
      expect(repository.lastBin, '42345678');
      expect(repository.lastMode, ProcessingMode.aggregator);
    });

    test('propagates gateway mode to payment-method discovery', () async {
      final repository = FakePaymentMethodRepository(response: const []);
      final cm = buildCoreMethods(paymentMethods: repository);

      final result = await cm.getPaymentMethods(
        bin: '42345678',
        mode: ProcessingMode.gateway,
      );

      expect(result, isA<Success<List<PaymentMethod>>>());
      expect(repository.lastMode, ProcessingMode.gateway);
    });

    test('rejects a non-empty bin that is not exactly 8 digits', () async {
      final cm = buildCoreMethods();
      final result = await cm.getPaymentMethods(bin: '423456');

      final error = (result as Failure<List<PaymentMethod>>).error;
      expect(error, isA<ValidationError>());
      expect((error as ValidationError).field, 'bin');
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

    test('maps repository failures and tracks the error', () async {
      final analytics = FakeAnalyticsService();
      final cm = buildCoreMethods(
        paymentMethods: FakePaymentMethodRepository(
          error: const ApiException(message: 'payment methods unavailable'),
        ),
        analytics: analytics,
      );

      final result = await cm.getPaymentMethods(bin: '45099535');

      expect(
        (result as Failure<List<PaymentMethod>>).error,
        isA<NetworkError>(),
      );
      expect(
        analytics.events.single.path,
        '/checkout_api_native/core_methods/payment_methods/error',
      );
    });
  });

  group('getInstallments', () {
    test('returns Failure on zero amount', () async {
      final cm = buildCoreMethods();
      final result = await cm.getInstallments(bin: '42345678', amount: 0);
      expect(result, isA<Failure<List<Installment>>>());
    });

    test('rejects non-finite amounts', () async {
      final cm = buildCoreMethods();

      for (final amount in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final result = await cm.getInstallments(
          bin: '42345678',
          amount: amount,
        );
        final error = (result as Failure<List<Installment>>).error;
        expect(error, isA<ValidationError>());
        expect((error as ValidationError).field, 'amount');
      }
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
      final result = await cm.getInstallments(bin: '42345678', amount: 100);
      expect(result, isA<Success<List<Installment>>>());
    });

    test('rejects a bin longer than 8 digits', () async {
      final cm = buildCoreMethods();
      final result = await cm.getInstallments(bin: '423456789', amount: 100);

      expect(
        (result as Failure<List<Installment>>).error,
        isA<ValidationError>(),
      );
    });

    test('maps repository failures and tracks the error', () async {
      final analytics = FakeAnalyticsService();
      final cm = buildCoreMethods(
        installments: FakeInstallmentRepository(
          error: const ApiException(message: 'installments unavailable'),
        ),
        analytics: analytics,
      );

      final result = await cm.getInstallments(bin: '42345678', amount: 100);

      expect((result as Failure<List<Installment>>).error, isA<NetworkError>());
      expect(
        analytics.events.single.path,
        '/checkout_api_native/core_methods/installments/error',
      );
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
      final result = await cm.getIssuers(paymentMethodId: '', bin: '42345678');
      expect((result as Failure<List<Issuer>>).error, isA<ValidationError>());
    });

    test('rejects a whitespace-only paymentMethodId', () async {
      final result = await buildCoreMethods().getIssuers(
        paymentMethodId: '   ',
        bin: '42345678',
      );

      expect((result as Failure<List<Issuer>>).error, isA<ValidationError>());
    });

    test('trims paymentMethodId before sending it to the repository', () async {
      final issuers = FakeIssuerRepository();
      final result = await buildCoreMethods(
        issuers: issuers,
      ).getIssuers(paymentMethodId: '  visa  ', bin: '42345678');

      expect(result, isA<Success<List<Issuer>>>());
      expect(issuers.lastPaymentMethodId, 'visa');
    });

    test('rejects a non-numeric bin', () async {
      final cm = buildCoreMethods();
      final result = await cm.getIssuers(
        paymentMethodId: 'visa',
        bin: '42345x',
      );

      expect((result as Failure<List<Issuer>>).error, isA<ValidationError>());
    });

    test('maps repository failures and tracks the error', () async {
      final analytics = FakeAnalyticsService();
      final result = await buildCoreMethods(
        issuers: FakeIssuerRepository(
          error: const ApiException(message: 'issuers unavailable'),
        ),
        analytics: analytics,
      ).getIssuers(paymentMethodId: 'visa', bin: '42345678');

      expect((result as Failure<List<Issuer>>).error, isA<NetworkError>());
      expect(
        analytics.events.single.path,
        '/checkout_api_native/core_methods/issuers/error',
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

    test('maps repository failures and tracks the error', () async {
      final analytics = FakeAnalyticsService();
      final result = await buildCoreMethods(
        identification: FakeIdentificationRepository(
          error: const ApiException(message: 'identification unavailable'),
        ),
        analytics: analytics,
      ).getIdentificationTypes();

      expect(
        (result as Failure<List<IdentificationType>>).error,
        isA<NetworkError>(),
      );
      expect(
        analytics.events.single.path,
        '/checkout_api_native/core_methods/identification_types/error',
      );
    });
  });
}
