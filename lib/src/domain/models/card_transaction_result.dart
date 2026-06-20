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

  final CardToken token;
  final String paymentMethodId;
  final String paymentTypeId;
  final String issuerId;

  /// Installment plan selected by the user.
  final PayerCost payerCost;

  /// Final amount the user accepted (matches `payerCost.totalAmount`).
  final double transactionAmount;

  /// Convenience accessor for the number of installments selected.
  int get installments => payerCost.installments;
}
