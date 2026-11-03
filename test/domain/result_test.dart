import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  group('MercadoPagoResult exhaustive pattern matching', () {
    String describe(MercadoPagoResult<int> r) => switch (r) {
      Success(:final data) => 'ok:$data',
      Failure(:final error) => 'err:${error.runtimeType}',
    };

    test('Success branch', () {
      expect(describe(const Success(42)), 'ok:42');
    });

    test('Failure branch', () {
      expect(describe(const Failure(BinIsEmptyError())), 'err:BinIsEmptyError');
    });
  });
}
