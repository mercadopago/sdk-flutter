import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  test('MPOrder groups orderId + clientToken', () {
    const order = MPOrder(orderId: 'o1', clientToken: 't1');
    expect(order.orderId, 'o1');
    expect(order.clientToken, 't1');
  });

  test('MPInstallment defaults to 1..180', () {
    const installment = MPInstallment();
    expect(installment.minInstallments, 1);
    expect(installment.maxInstallments, 180);
  });

  test('MPPayer holds a typed email', () {
    expect(const MPPayer(email: 'buyer@example.com').email, 'buyer@example.com');
  });

  group('BuyerIdentification', () {
    test('requires a name; number/type optional', () {
      const id = BuyerIdentification(name: 'JOHN DOE');
      expect(id.name, 'JOHN DOE');
      expect(id.number, isNull);
      expect(id.type, isNull);
    });

    test('carries an optional identification document', () {
      const id =
          BuyerIdentification(name: 'JOHN DOE', number: '012345678', type: 'CPF');
      expect(id.number, '012345678');
      expect(id.type, 'CPF');
    });
  });
}
