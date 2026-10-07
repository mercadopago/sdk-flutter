import 'payment_agreement.dart';

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
    this.cardNumberLengthMin,
    this.cardNumberLengthMax,
    this.securityCodeLength,
    this.securityCodeLocation,
    this.processingMode,
    this.merchantAccountId,
    this.siteId,
    this.minAccreditationDays,
    this.maxAccreditationDays,
    this.totalFinancialCost,
    this.financialInstitutions = const [],
    this.issuer,
    this.card,
    this.bins = const [],
    this.marketplace,
    this.deferredCapture,
    this.agreements = const [],
    this.payerCosts = const [],
    this.labels = const [],
  });

  /// Payment method identifier (for example, `visa`).
  final String id;

  /// Human-readable name when the response supplies one.
  final String name;

  /// Category of this payment method (for example, `credit_card`).
  final String paymentTypeId;

  /// Whether this method is currently available.
  final String status;

  /// URL of the card-brand logo.
  final String thumbnail;

  /// Legacy secure-thumbnail projection kept for API compatibility.
  final String secureThumbnail;

  /// Minimum transaction amount across [payerCosts].
  final double minAllowedAmount;

  /// Maximum transaction amount across [payerCosts].
  final double maxAllowedAmount;

  /// Typical number of minutes until an approved payment is credited.
  final int accreditationTime;

  /// Extra payer fields required for this method.
  final List<String> additionalInfoNeeded;

  /// Compatibility projection of [card]'s minimum PAN length.
  final int? cardNumberLengthMin;

  /// Compatibility projection of [card]'s maximum PAN length.
  final int? cardNumberLengthMax;

  /// Compatibility projection of [card]'s security-code length.
  final int? securityCodeLength;

  /// Compatibility projection of [card]'s security-code location.
  final String? securityCodeLocation;

  /// Processing model returned by CoreMethods.
  final String? processingMode;

  /// Merchant account selected for gateway processing.
  final String? merchantAccountId;

  final String? siteId;
  final int? minAccreditationDays;
  final int? maxAccreditationDays;
  final double? totalFinancialCost;
  final List<PaymentMethodFinancialInstitution> financialInstitutions;
  final PaymentMethodIssuer? issuer;
  final PaymentMethodCard? card;
  final List<int> bins;
  final String? marketplace;
  final String? deferredCapture;
  final List<PaymentAgreement> agreements;
  final List<PaymentMethodPayerCost> payerCosts;
  final List<String> labels;
}

class PaymentMethodFinancialInstitution {
  const PaymentMethodFinancialInstitution({this.id, required this.description});

  final String? id;
  final String description;
}

class PaymentMethodIssuer {
  const PaymentMethodIssuer({this.id, this.isDefault, this.thumbnail});

  /// Lossless issuer identifier. Native SDKs expose this as either a string or
  /// an integer, so the Flutter contract normalizes both forms to a string.
  final String? id;
  final bool? isDefault;
  final String? thumbnail;
}

class PaymentMethodCard {
  const PaymentMethodCard({
    this.bin,
    this.length,
    this.validation,
    this.securityCode,
  });

  final int? bin;
  final PaymentMethodCardLength? length;
  final String? validation;
  final PaymentMethodSecurityCode? securityCode;
}

class PaymentMethodCardLength {
  const PaymentMethodCardLength({this.min, this.max});

  final int? min;
  final int? max;
}

class PaymentMethodSecurityCode {
  const PaymentMethodSecurityCode({this.mode, this.location, this.length});

  final String? mode;
  final String? location;
  final int? length;
}

class PaymentMethodPayerCost {
  const PaymentMethodPayerCost({
    this.installments,
    this.installmentAmount,
    this.installmentRate,
    this.installmentRateCollector = const [],
    this.totalAmount,
    this.discountRate,
    this.reimbursementRate,
    this.minAllowedAmount,
    this.maxAllowedAmount,
    this.paymentMethodOptionId,
    this.labels = const [],
  });

  final int? installments;
  final double? installmentAmount;
  final double? installmentRate;
  final List<String> installmentRateCollector;
  final double? totalAmount;
  final double? discountRate;
  final double? reimbursementRate;
  final double? minAllowedAmount;
  final double? maxAllowedAmount;
  final String? paymentMethodOptionId;
  final List<String> labels;
}
