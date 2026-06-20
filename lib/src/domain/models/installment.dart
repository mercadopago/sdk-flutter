/// A single installment option ("cuota") for a card payment.
class PayerCost {
  const PayerCost({
    required this.installments,
    required this.installmentRate,
    required this.discountRate,
    required this.minAllowedAmount,
    required this.maxAllowedAmount,
    required this.installmentAmount,
    required this.totalAmount,
    required this.labels,
    required this.paymentMethodOptionId,
  });

  /// Number of payments (e.g. 1, 3, 6, 12).
  final int installments;

  /// Annualized interest rate as a percentage (0 = interest-free).
  final double installmentRate;

  final double discountRate;
  final double minAllowedAmount;
  final double maxAllowedAmount;

  /// Amount the cardholder pays per installment.
  final double installmentAmount;

  /// Total amount after applying [installmentRate].
  final double totalAmount;

  final List<String> labels;
  final String paymentMethodOptionId;
}

/// Installment plan returned for a (bin, amount) tuple.
class Installment {
  const Installment({
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuer,
    required this.processingMode,
    required this.merchantAccountId,
    required this.payerCosts,
  });

  final String paymentMethodId;
  final String paymentTypeId;
  final InstallmentIssuer issuer;
  final String processingMode;
  final String? merchantAccountId;
  final List<PayerCost> payerCosts;
}

class InstallmentIssuer {
  const InstallmentIssuer({
    required this.id,
    required this.name,
    required this.secureThumbnail,
    required this.thumbnail,
  });

  final String id;
  final String name;
  final String secureThumbnail;
  final String thumbnail;
}
