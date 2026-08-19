import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/mercadopago.dart';

void main() {
  group('Configuration', () {
    test('accepts a well-formed APP_USR public key', () {
      final config = Configuration.fromValues(
        publicKey: 'APP_USR-abc123XYZabc',
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

  group('Country.siteId', () {
    test('maps every supported country to its MercadoLibre site id', () {
      expect(Country.argentina.siteId, 'MLA');
      expect(Country.brazil.siteId, 'MLB');
      expect(Country.chile.siteId, 'MLC');
      // Colombia must be MCO (the correct value); the native iOS SDK has a bug
      // mapping COL to MLC, which collides with Chile.
      expect(Country.colombia.siteId, 'MCO');
      expect(Country.mexico.siteId, 'MLM');
      expect(Country.peru.siteId, 'MPE');
      expect(Country.uruguay.siteId, 'MLU');
    });

    test('Colombia and Chile do not share a site id', () {
      expect(Country.colombia.siteId, isNot(Country.chile.siteId));
    });
  });
}
