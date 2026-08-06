import 'mp_order.dart';
import 'mp_payment_data.dart';

/// The kind of hosted checkout to run, mirroring the native `MPCheckoutType`.
///
/// A single [MercadoPagoCheckout] adapts to the type passed here; the phantom
/// generic `T` makes the result callback statically typed (no casting):
/// `MPCheckoutType.cardSave()` → `MPCardSaveData`,
/// `MPCheckoutType.cardTransaction(order)` → `MPCardTransactionData`.
sealed class MPCheckoutType<T extends MPPaymentData> {
  const MPCheckoutType();

  /// Tokenize a card for later use. No order required.
  static MPCheckoutType<MPCardSaveData> cardSave() => const MPCardSaveCheckout();

  /// Tokenize and process a payment bound to [order] (Orders API).
  static MPCheckoutType<MPCardTransactionData> cardTransaction(MPOrder order) =>
      MPCardTransactionCheckout(order);
}

final class MPCardSaveCheckout extends MPCheckoutType<MPCardSaveData> {
  const MPCardSaveCheckout();
}

final class MPCardTransactionCheckout
    extends MPCheckoutType<MPCardTransactionData> {
  const MPCardTransactionCheckout(this.order);
  final MPOrder order;
}
