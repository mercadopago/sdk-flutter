import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  group('BuyerIdentification', () {
    test('requires a cardholder name', () {
      const identification = BuyerIdentification(name: 'JOHN DOE');

      expect(identification.name, 'JOHN DOE');
      expect(identification.number, isNull);
      expect(identification.type, isNull);
    });

    test('carries an optional identification document', () {
      const identification = BuyerIdentification(
        name: 'JOHN DOE',
        number: '12345678',
        type: 'DNI',
      );

      expect(identification.number, '12345678');
      expect(identification.type, 'DNI');
    });
  });
}
