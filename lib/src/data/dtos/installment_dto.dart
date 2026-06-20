import '../../domain/models/installment.dart';

class InstallmentDto {
  const InstallmentDto({
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuer,
    required this.processingMode,
    required this.merchantAccountId,
    required this.payerCosts,
  });

  factory InstallmentDto.fromJson(Map<String, dynamic> json) {
    final issuerJson = (json['issuer'] as Map<String, dynamic>?) ?? const {};
    final payerCostsJson =
        (json['payer_costs'] as List<dynamic>? ?? const []);

    return InstallmentDto(
      paymentMethodId: json['payment_method_id'] as String? ?? '',
      paymentTypeId: json['payment_type_id'] as String? ?? '',
      issuer: InstallmentIssuerDto.fromJson(issuerJson),
      processingMode: json['processing_mode'] as String? ?? 'aggregator',
      merchantAccountId: json['merchant_account_id'] as String?,
      payerCosts: payerCostsJson
          .whereType<Map<String, dynamic>>()
          .map(PayerCostDto.fromJson)
          .toList(growable: false),
    );
  }

  final String paymentMethodId;
  final String paymentTypeId;
  final InstallmentIssuerDto issuer;
  final String processingMode;
  final String? merchantAccountId;
  final List<PayerCostDto> payerCosts;

  Installment toDomain() => Installment(
        paymentMethodId: paymentMethodId,
        paymentTypeId: paymentTypeId,
        issuer: issuer.toDomain(),
        processingMode: processingMode,
        merchantAccountId: merchantAccountId,
        payerCosts: payerCosts.map((p) => p.toDomain()).toList(growable: false),
      );
}

class InstallmentIssuerDto {
  const InstallmentIssuerDto({
    required this.id,
    required this.name,
    required this.secureThumbnail,
    required this.thumbnail,
  });

  factory InstallmentIssuerDto.fromJson(Map<String, dynamic> json) =>
      InstallmentIssuerDto(
        id: (json['id'] ?? '').toString(),
        name: json['name'] as String? ?? '',
        secureThumbnail: json['secure_thumbnail'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
      );

  final String id;
  final String name;
  final String secureThumbnail;
  final String thumbnail;

  InstallmentIssuer toDomain() => InstallmentIssuer(
        id: id,
        name: name,
        secureThumbnail: secureThumbnail,
        thumbnail: thumbnail,
      );
}

class PayerCostDto {
  const PayerCostDto({
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

  factory PayerCostDto.fromJson(Map<String, dynamic> json) => PayerCostDto(
        installments: (json['installments'] as num?)?.toInt() ?? 1,
        installmentRate:
            (json['installment_rate'] as num?)?.toDouble() ?? 0,
        discountRate: (json['discount_rate'] as num?)?.toDouble() ?? 0,
        minAllowedAmount:
            (json['min_allowed_amount'] as num?)?.toDouble() ?? 0,
        maxAllowedAmount: (json['max_allowed_amount'] as num?)?.toDouble() ??
            double.infinity,
        installmentAmount:
            (json['installment_amount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        labels: (json['labels'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        paymentMethodOptionId:
            json['payment_method_option_id'] as String? ?? '',
      );

  final int installments;
  final double installmentRate;
  final double discountRate;
  final double minAllowedAmount;
  final double maxAllowedAmount;
  final double installmentAmount;
  final double totalAmount;
  final List<String> labels;
  final String paymentMethodOptionId;

  PayerCost toDomain() => PayerCost(
        installments: installments,
        installmentRate: installmentRate,
        discountRate: discountRate,
        minAllowedAmount: minAllowedAmount,
        maxAllowedAmount: maxAllowedAmount,
        installmentAmount: installmentAmount,
        totalAmount: totalAmount,
        labels: labels,
        paymentMethodOptionId: paymentMethodOptionId,
      );
}
