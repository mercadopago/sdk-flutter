import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/src/data/dtos/order_process_dto.dart';
import 'package:mercadopago_flutter_sdk/src/domain/repositories.dart';

void main() {
  group('OrderProcessDto', () {
    test('serializes the request body (amount 2dp, payment_method_type)', () {
      final body = OrderProcessDto.toRequestBody(
        const OrderProcessParams(
          orderId: 'o1',
          clientToken: 't1',
          paymentMethodId: 'visa',
          paymentTypeId: 'credit_card',
          token: 'tok_123',
          installments: 3,
          amount: 1500,
        ),
      );
      expect(body['payment_method_id'], 'visa');
      // paymentTypeId travels under payment_method_type (native quirk).
      expect(body['payment_method_type'], 'credit_card');
      expect(body['token'], 'tok_123');
      expect(body['installments'], 3);
      expect(body['amount'], '1500.00');
    });

    test('parses the response down to {id, status}', () {
      final result = OrderProcessDto.parse(const {
        'id': 'ord_1',
        'status': 'processed',
        'total_amount': 1500,
      });
      expect(result.id, 'ord_1');
      expect(result.status, 'processed');
    });
  });
}
