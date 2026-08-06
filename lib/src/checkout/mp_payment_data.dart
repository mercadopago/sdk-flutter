import '../domain/models/card_token.dart';

/// Data delivered to the integrator when a hosted-checkout flow succeeds.
///
/// A sealed hierarchy mirroring the native `MPPaymentData` (`CardSave` /
/// `CardTransaction`). The concrete type is inferred from the [MPCheckoutType]
/// used, so the `onResult` callback is statically typed with no casting.
sealed class MPPaymentData {
  const MPPaymentData();
}

/// Result of a Card Save flow: the tokenized card. The integrator forwards the
/// token to their backend (the SDK does not process a payment here).
final class MPCardSaveData extends MPPaymentData {
  const MPCardSaveData({
    required this.token,
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuerId,
    this.cardId,
  });

  /// Tokenized card. Forward [CardToken.token] to your backend.
  final CardToken token;

  /// Payment method identifier (e.g. `"visa"`).
  final String paymentMethodId;

  /// Payment type category (e.g. `"credit_card"`).
  final String paymentTypeId;

  /// Identifier of the card's issuing bank.
  final String issuerId;

  /// Populated when the card was already saved on the customer's account.
  final String? cardId;
}

/// Result of a Card Transaction flow. The SDK processed the order server-side,
/// so this carries the resulting [orderId] + [orderStatus] (not the raw token).
final class MPCardTransactionData extends MPPaymentData {
  const MPCardTransactionData({
    required this.orderId,
    required this.orderStatus,
    required this.paymentMethodId,
    required this.paymentTypeId,
    this.transactionAmount,
    this.installments,
  });

  /// Identifier of the processed order.
  final String orderId;

  /// Order status returned by the process call (e.g. `"processed"`).
  final String orderStatus;

  /// Payment method identifier (e.g. `"visa"`).
  final String paymentMethodId;

  /// Payment type category (e.g. `"credit_card"`).
  final String paymentTypeId;

  /// Amount charged (from the selected installment); `null` if unknown.
  final double? transactionAmount;

  /// Number of installments selected; `null` if not applicable.
  final int? installments;
}
