import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  group('MercadoPagoResult exhaustive pattern matching', () {
    String describe(MercadoPagoResult<int> r) => switch (r) {
          Success(:final data) => 'ok:$data',
          Failure(:final error) => 'err:${error.runtimeType}',
          Cancelled() => 'cancelled',
        };

    test('Success branch', () {
      expect(describe(const Success(42)), 'ok:42');
    });

    test('Failure branch', () {
      expect(
        describe(const Failure(BinIsEmptyError())),
        'err:BinIsEmptyError',
      );
    });

    test('Cancelled branch', () {
      expect(
        describe(const Cancelled(MPCancelContext(step: CheckoutStep.cardForm))),
        'cancelled',
      );
    });
  });
}
