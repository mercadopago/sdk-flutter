import 'card_bin_data.dart';
import 'card_token.dart';

/// Result returned by the CardTransaction checkout flow.
class CardTransactionResult {
  const CardTransactionResult({
    required this.token,
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuerId,
    required this.installment,
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

  /// Installment option selected by the user (from the aggregated BFF lookup).
  final CheckoutInstallment installment;

  /// Final amount the user accepted (matches `installment.totalAmount`).
  final double transactionAmount;

  /// Convenience accessor for the number of installments selected.
  int get installments => installment.installments;
}
