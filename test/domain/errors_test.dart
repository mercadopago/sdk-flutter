import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  group('MercadoPagoError diagnostics', () {
    test('network and validation errors include actionable metadata', () {
      const network = NetworkError(
        message: 'unavailable',
        statusCode: 503,
        isRetriable: true,
        location: ErrorLocation.tokenization,
      );
      const validation = ValidationError(
        field: 'bin',
        message: 'invalid',
        location: ErrorLocation.paymentMethods,
      );

      expect(network.toString(), contains('status: 503'));
      expect(network.toString(), contains('retriable: true'));
      expect(validation.toString(), contains('field: bin'));
      expect(
        validation.toString(),
        contains('location: ErrorLocation.paymentMethods'),
      );
    });

    test(
      'typed runtime errors expose their location without sensitive data',
      () {
        const errors = <MercadoPagoError>[
          InvalidCardNumberError(),
          InvalidCvvError(),
          InvalidExpirationDateError(),
          CardExpiredError(),
          BinIsEmptyError(),
          UnknownError(
            message: 'generic failure',
            location: ErrorLocation.unknown,
          ),
        ];

        for (final error in errors) {
          expect(error.toString(), contains('location:'));
        }
      },
    );
  });
}
