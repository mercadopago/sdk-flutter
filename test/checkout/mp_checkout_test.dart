import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  group('MPCheckoutType', () {
    test('cardSave() is the save variant', () {
      expect(MPCheckoutType.cardSave(), isA<MPCardSaveCheckout>());
    });

    test('cardTransaction(order) carries the order', () {
      final type = MPCheckoutType.cardTransaction(
        const MPOrder(orderId: 'o1', clientToken: 't1'),
      );
      expect(type, isA<MPCardTransactionCheckout>());
      expect((type as MPCardTransactionCheckout).order.orderId, 'o1');
    });
  });

  group('MercadoPagoCheckoutResult', () {
    test('pattern-matches success / error / cancelled', () {
      const data = MPCardTransactionData(
        orderId: 'o1',
        orderStatus: 'processed',
        paymentMethodId: 'visa',
        paymentTypeId: 'credit_card',
        transactionAmount: 100,
        installments: 3,
      );
      const MercadoPagoCheckoutResult<MPCardTransactionData> result =
          CheckoutSuccess(data);

      final label = switch (result) {
        CheckoutSuccess(:final data) => 'ok:${data.orderStatus}',
        CheckoutError() => 'error',
        CheckoutUserCancelled() => 'cancelled',
      };
      expect(label, 'ok:processed');
    });
  });

  group('MPUserCancelledContext', () {
    test('card save carries per-field states', () {
      const context = MPCardSaveCancelled(
        fields: [
          MPCancelledFieldState(
            field: CheckoutField.securityCode,
            state: CancelFieldState.incomplete,
          ),
        ],
      );
      expect(context.fields.single.field, CheckoutField.securityCode);
      expect(context.fields.single.state, CancelFieldState.incomplete);
    });

    test('card transaction also carries visited screens', () {
      const context = MPCardTransactionCancelled(
        fields: [],
        screens: [CheckoutScreen.cardForm, CheckoutScreen.installments],
      );
      expect(context.screens, [
        CheckoutScreen.cardForm,
        CheckoutScreen.installments,
      ]);
    });
  });
}
