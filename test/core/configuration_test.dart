import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  group('Configuration', () {
    test('accepts a well-formed APP_USR public key', () {
      final config = Configuration.fromValues(
        publicKey: 'APP_USR-abc123XYZ',
        countryCode: 'ARG',
      );
      expect(config.country, Country.argentina);
    });

    test('accepts a real MercadoPago public key with UUID hyphens', () {
      // Real keys are UUIDs (8-4-4-4-12 with hyphens). This guards against
      // a regression where the regex omitted '-' from the body class.
      final config = Configuration.fromValues(
        publicKey: 'APP_USR-00000000-0000-4000-8000-000000000000',
        countryCode: 'ARG',
      );
      expect(config.country, Country.argentina);
    });

    test('rejects a public key without APP_USR prefix', () {
      expect(
        () => Configuration.fromValues(
          publicKey: 'TEST-1234',
          countryCode: 'ARG',
        ),
        throwsA(isA<SDKInvalidPublicKeyError>()),
      );
    });

    test('rejects an unsupported country code', () {
      expect(
        () => Configuration.fromValues(
          publicKey: 'APP_USR-abc123',
          countryCode: 'ZZZ',
        ),
        throwsA(isA<SDKInvalidCountryError>()),
      );
    });

    test('country lookup is case-insensitive', () {
      expect(Country.fromCode('arg'), Country.argentina);
      expect(Country.fromCode('Bra'), Country.brazil);
    });
  });
}
