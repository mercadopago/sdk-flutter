import '../../domain/models/installment.dart';
import 'json_value.dart';
import 'payment_agreement_dto.dart';

class InstallmentDto {
  const InstallmentDto({
    required this.paymentMethodId,
    required this.paymentTypeId,
    required this.issuer,
    required this.processingMode,
    required this.merchantAccountId,
    required this.payerCosts,
    required this.thumbnail,
    required this.agreements,
  });

  /// Parses a `/cho-off/v1/installments` entry.
  ///
  /// Contract: Android `InstallmentsResponse.kt` declares **every** field
  /// nullable — including `issuer` and `payer_costs` — so requiring any of them
  /// rejected responses the native SDKs accept.
  factory InstallmentDto.fromJson(Map<String, dynamic> json) {
    final issuerJson = optionalMap(json, 'issuer');

    return InstallmentDto(
      paymentMethodId: optionalString(json, 'payment_method_id') ?? '',
      paymentTypeId: optionalString(json, 'payment_type_id') ?? '',
      thumbnail: optionalStringOrNullWhenBlank(json, 'thumbnail') ?? '',
      issuer: InstallmentIssuerDto.fromJson(issuerJson ?? const {}),
      processingMode: optionalString(json, 'processing_mode') ?? '',
      merchantAccountId: optionalStringOrNullWhenBlank(
        json,
        'merchant_account_id',
      ),
      payerCosts: json['payer_costs'] == null
          ? const []
          : requiredObjectList(json, 'payer_costs', PayerCostDto.fromJson),
      agreements: json['agreements'] == null
          ? const []
          : requiredObjectList(
              json,
              'agreements',
              PaymentAgreementDto.fromJson,
            ),
    );
  }

  final String paymentMethodId;
  final String paymentTypeId;
  final String thumbnail;
  final InstallmentIssuerDto issuer;
  final String processingMode;
  final String? merchantAccountId;
  final List<PayerCostDto> payerCosts;
  final List<PaymentAgreementDto> agreements;

  Installment toDomain() => Installment(
    paymentMethodId: paymentMethodId,
    paymentTypeId: paymentTypeId,
    thumbnail: thumbnail,
    issuer: issuer.toDomain(),
    processingMode: processingMode,
    merchantAccountId: merchantAccountId,
    payerCosts: payerCosts.map((p) => p.toDomain()).toList(growable: false),
    agreements: agreements
        .map((agreement) => agreement.toDomain())
        .toList(growable: false),
  );
}

class InstallmentIssuerDto {
  const InstallmentIssuerDto({
    required this.id,
    required this.name,
    required this.secureThumbnail,
    required this.thumbnail,
    required this.isDefault,
  });

  /// Contract: the issuer embedded in an installments entry carries only
  /// `id`, `thumbnail` and `default` (Android `IssuerResponse`, all nullable).
  /// `name` and `secure_thumbnail` are **not** part of it, so requiring them
  /// rejected every valid response.
  factory InstallmentIssuerDto.fromJson(
    Map<String, dynamic> json,
  ) => InstallmentIssuerDto(
    id: optionalStringOrNullWhenBlank(json, 'id', fieldName: 'issuer.id') ?? '',
    name:
        optionalStringOrNullWhenBlank(json, 'name', fieldName: 'issuer.name') ??
        '',
    secureThumbnail:
        optionalStringOrNullWhenBlank(
          json,
          'secure_thumbnail',
          fieldName: 'issuer.secure_thumbnail',
        ) ??
        '',
    thumbnail:
        optionalStringOrNullWhenBlank(
          json,
          'thumbnail',
          fieldName: 'issuer.thumbnail',
        ) ??
        '',
    isDefault: optionalBool(json, 'default', fieldName: 'issuer.default'),
  );

  final String id;
  final String name;
  final String secureThumbnail;
  final String thumbnail;
  final bool? isDefault;

  InstallmentIssuer toDomain() => InstallmentIssuer(
    id: id,
    name: name,
    secureThumbnail: secureThumbnail,
    thumbnail: thumbnail,
    isDefault: isDefault,
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
    required this.installmentRateCollector,
    required this.reimbursementRate,
  });

  /// Contract: Android `PayerCostResponse` declares every field nullable.
  /// Absent fields fall back to neutral values; **present** ones are still
  /// validated, so a corrupt payload fails instead of silently degrading.
  factory PayerCostDto.fromJson(Map<String, dynamic> json) {
    final installments = optionalInt(json, 'installments');
    final minAllowedAmount = optionalDouble(json, 'min_allowed_amount');
    final maxAllowedAmount = optionalDouble(json, 'max_allowed_amount');
    final installmentAmount = optionalDouble(json, 'installment_amount');
    final totalAmount = optionalDouble(json, 'total_amount');
    if (installments != null && installments <= 0) {
      throw const FormatException(
        'Response payer_costs.installments must be greater than zero.',
      );
    }
    if ((minAllowedAmount != null && minAllowedAmount < 0) ||
        (minAllowedAmount != null &&
            maxAllowedAmount != null &&
            maxAllowedAmount < minAllowedAmount)) {
      throw const FormatException(
        'Response payer_costs allowed amounts must define a non-negative range.',
      );
    }
    if ((installmentAmount != null && installmentAmount < 0) ||
        (totalAmount != null && totalAmount < 0)) {
      throw const FormatException(
        'Response payer_costs amounts must not be negative.',
      );
    }
    return PayerCostDto(
      installments: installments ?? 0,
      installmentRate: optionalDouble(json, 'installment_rate') ?? 0,
      installmentRateCollector: optionalStringList(
        json,
        'installment_rate_collector',
      ),
      discountRate: optionalDouble(json, 'discount_rate') ?? 0,
      reimbursementRate: optionalDouble(json, 'reimbursement_rate') ?? 0,
      minAllowedAmount: minAllowedAmount ?? 0,
      maxAllowedAmount: maxAllowedAmount ?? double.infinity,
      installmentAmount: installmentAmount ?? 0,
      totalAmount: totalAmount ?? 0,
      labels: optionalStringList(json, 'labels'),
      paymentMethodOptionId:
          optionalString(json, 'payment_method_option_id') ?? '',
    );
  }

  final int installments;
  final double installmentRate;
  final List<String> installmentRateCollector;
  final double discountRate;
  final double reimbursementRate;
  final double minAllowedAmount;
  final double maxAllowedAmount;
  final double installmentAmount;
  final double totalAmount;
  final List<String> labels;
  final String paymentMethodOptionId;

  PayerCost toDomain() => PayerCost(
    installments: installments,
    installmentRate: installmentRate,
    installmentRateCollector: installmentRateCollector,
    discountRate: discountRate,
    reimbursementRate: reimbursementRate,
    minAllowedAmount: minAllowedAmount,
    maxAllowedAmount: maxAllowedAmount,
    installmentAmount: installmentAmount,
    totalAmount: totalAmount,
    labels: labels,
    paymentMethodOptionId: paymentMethodOptionId,
  );
}
