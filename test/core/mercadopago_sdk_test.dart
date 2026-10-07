import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/mercadopago.dart';

const _validPublicKey = 'APP_USR-00000000-0000-4000-8000-000000000000';

void main() {
  final sdk = MercadoPagoSDK.shared;

  setUp(sdk.dispose);
  tearDown(sdk.dispose);

  group('MercadoPagoSDK.setNewConfiguration', () {
    test('keeps the active SDK intact when the new public key is invalid', () {
      sdk.initialize(publicKey: _validPublicKey, countryCode: 'ARG');
      final configuration = sdk.configuration;
      final sessionId = sdk.sessionId;
      final coreMethods = sdk.coreMethods;

      expect(
        () => sdk.setNewConfiguration(publicKey: 'invalid', countryCode: 'BRA'),
        throwsA(isA<SDKInvalidPublicKeyError>()),
      );

      expect(sdk.isInitialized, isTrue);
      expect(sdk.configuration, same(configuration));
      expect(sdk.sessionId, sessionId);
      expect(sdk.coreMethods, same(coreMethods));
    });

    test('keeps the active SDK intact when the new country is invalid', () {
      sdk.initialize(publicKey: _validPublicKey, countryCode: 'ARG');
      final configuration = sdk.configuration;
      final sessionId = sdk.sessionId;
      final coreMethods = sdk.coreMethods;

      expect(
        () => sdk.setNewConfiguration(
          publicKey: _validPublicKey,
          countryCode: 'ZZZ',
        ),
        throwsA(isA<SDKInvalidCountryError>()),
      );

      expect(sdk.isInitialized, isTrue);
      expect(sdk.configuration, same(configuration));
      expect(sdk.sessionId, sessionId);
      expect(sdk.coreMethods, same(coreMethods));
    });

    test('propagates the analytics opt-out across reconfiguration', () {
      sdk.initialize(
        publicKey: _validPublicKey,
        countryCode: 'ARG',
        analyticsEnabled: false,
      );
      expect(sdk.configuration.analyticsEnabled, isFalse);

      sdk.setNewConfiguration(
        publicKey: _validPublicKey,
        countryCode: 'BRA',
        analyticsEnabled: false,
      );

      expect(sdk.configuration.analyticsEnabled, isFalse);
      expect(sdk.configuration.country, Country.brazil);
    });
  });
}
