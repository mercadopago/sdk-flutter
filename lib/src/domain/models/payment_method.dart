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

  final String id;
  final String name;
  final String paymentTypeId;
  final String status;
  final String thumbnail;
  final String secureThumbnail;
  final double minAllowedAmount;
  final double maxAllowedAmount;
  final int accreditationTime;
  final List<String> additionalInfoNeeded;
  final int binLengthMin;
  final int binLengthMax;
  final int securityCodeLength;
  final String securityCodeLocation;
}
