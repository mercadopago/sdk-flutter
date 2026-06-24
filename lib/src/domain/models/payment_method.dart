/// Describes a card brand or payment method supported for a given BIN.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.paymentTypeId,
    required this.status,
    required this.thumbnail,
    required this.secureThumbnail,
    required this.minAllowedAmount,
    required this.maxAllowedAmount,
    required this.accreditationTime,
    required this.additionalInfoNeeded,
    required this.binLengthMin,
    required this.binLengthMax,
    required this.securityCodeLength,
    required this.securityCodeLocation,
  });

  /// Payment method identifier (e.g. `"visa"`, `"master"`, `"amex"`).
  final String id;

  /// Human-readable name (e.g. `"Visa"`, `"Mastercard"`).
  final String name;

  /// Category of this payment method (e.g. `"credit_card"`, `"debit_card"`).
  final String paymentTypeId;

  /// Whether this method is currently available (`"active"` or `"inactive"`).
  final String status;

  /// URL of the card-brand logo (standard resolution).
  final String thumbnail;

  /// URL of the card-brand logo (served over HTTPS).
  final String secureThumbnail;

  /// Minimum transaction amount accepted for this method, in the integrator's
  /// account currency.
  final double minAllowedAmount;

  /// Maximum transaction amount accepted for this method, in the integrator's
  /// account currency. `double.infinity` when there is no cap.
  final double maxAllowedAmount;

  /// Typical number of minutes until the payment is credited once approved.
  final int accreditationTime;

  /// Extra fields the cardholder must supply (e.g. `"cardholder_name"`,
  /// `"cardholder_identification_type"`).
  final List<String> additionalInfoNeeded;

  /// Minimum number of digits in a valid card number for this method.
  final int binLengthMin;

  /// Maximum number of digits in a valid card number for this method.
  final int binLengthMax;

  /// Expected length of the security code (CVV/CVC) for this method.
  final int securityCodeLength;

  /// Where the security code is printed on the card: `"back"` or `"front"`.
  final String securityCodeLocation;
}
