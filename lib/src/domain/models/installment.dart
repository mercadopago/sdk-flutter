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

  /// Promotional discount rate as a percentage (0 when no discount applies).
  final double discountRate;

  /// Minimum transaction amount eligible for this installment plan.
  final double minAllowedAmount;

  /// Maximum transaction amount eligible for this installment plan.
  /// `double.infinity` when there is no cap.
  final double maxAllowedAmount;

  /// Amount the cardholder pays per installment.
  final double installmentAmount;

  /// Total amount after applying [installmentRate].
  final double totalAmount;

  /// Promotional or informational labels associated with this plan
  /// (e.g. `["CFT_0%", "TEA_0%"]`).
  final List<String> labels;

  /// Internal identifier for this installment option, used when building the
  /// payment request body.
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

  /// Payment method identifier this plan applies to (e.g. `"visa"`).
  final String paymentMethodId;

  /// Payment type category (e.g. `"credit_card"`).
  final String paymentTypeId;

  /// Issuing bank associated with this installment plan.
  final InstallmentIssuer issuer;

  /// Processing model: `"aggregator"` or `"gateway"`.
  final String processingMode;

  /// Merchant account identifier when operating in gateway mode, `null`
  /// in aggregator mode.
  final String? merchantAccountId;

  /// Available installment options, sorted from lowest to highest
  /// number of payments.
  final List<PayerCost> payerCosts;
}

/// Issuing bank associated with an [Installment] plan.
class InstallmentIssuer {
  const InstallmentIssuer({
    required this.id,
    required this.name,
    required this.secureThumbnail,
    required this.thumbnail,
  });

  /// Unique bank identifier.
  final String id;

  /// Human-readable bank name.
  final String name;

  /// URL of the bank logo (served over HTTPS).
  final String secureThumbnail;

  /// URL of the bank logo (standard resolution).
  final String thumbnail;
}
