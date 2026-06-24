import 'card_token.dart';
import 'installment.dart';

/// Result returned by the CardTransaction checkout flow.
class CardTransactionResult {
  const CardTransactionResult({
    required this.token,
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuerId,
    required this.payerCost,
    required this.transactionAmount,
  });

  /// Tokenized card. Forward [CardToken.token] to your backend together with
  /// [installments] and [transactionAmount] to create the payment.
  final CardToken token;

  /// Payment method identifier (e.g. `"visa"`, `"master"`).
  final String paymentMethodId;

  /// Payment type category (e.g. `"credit_card"`, `"debit_card"`).
  final String paymentTypeId;

  /// Identifier of the card's issuing bank.
  final String issuerId;

  /// Installment plan selected by the user.
  final PayerCost payerCost;

  /// Final amount the user accepted (matches `payerCost.totalAmount`).
  final double transactionAmount;

  /// Convenience accessor for the number of installments selected.
  int get installments => payerCost.installments;
}
