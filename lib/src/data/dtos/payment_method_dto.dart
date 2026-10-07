import '../../domain/models/payment_method.dart';
import 'json_value.dart';
import 'payment_agreement_dto.dart';

class PaymentMethodDto {
  const PaymentMethodDto({
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
    required this.cardNumberLengthMin,
    required this.cardNumberLengthMax,
    required this.securityCodeLength,
    required this.securityCodeLocation,
    required this.processingMode,
    required this.merchantAccountId,
    required this.siteId,
    required this.minAccreditationDays,
    required this.maxAccreditationDays,
    required this.totalFinancialCost,
    required this.financialInstitutions,
    required this.issuer,
    required this.card,
    required this.bins,
    required this.marketplace,
    required this.deferredCapture,
    required this.agreements,
    required this.payerCosts,
    required this.labels,
  });

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    // The native CoreMethods contract allows both `card` and its validation
    // metadata to be absent. Discovery must preserve that response instead of
    // turning a successful native payload into a parsing error. The
    // tokenization path applies PAN/CVV constraints when metadata is present.
    final cardJson = optionalMap(json, 'card');
    final card = cardJson == null
        ? null
        : PaymentMethodCardDto.fromJson(cardJson);
    final minLength = card?.length?.min;
    final maxLength = card?.length?.max;
    final cvvLength = card?.securityCode?.length;
    final cvvLocation = card?.securityCode?.location;

    final payerCosts = json['payer_costs'] == null
        ? const <PaymentMethodPayerCostDto>[]
        : requiredObjectList(
            json,
            'payer_costs',
            PaymentMethodPayerCostDto.fromJson,
          );
    final (minAllowedAmount, maxAllowedAmount) = _allowedAmountRange(
      payerCosts,
    );
    final accreditationTime =
        optionalInt(json, 'accreditation_time', allowNumericString: true) ?? 0;
    if (accreditationTime < 0) {
      throw const FormatException(
        'Response accreditation_time must not be negative.',
      );
    }

    final issuerJson = optionalMap(json, 'issuer');
    return PaymentMethodDto(
      id: requiredString(json, 'id'),
      name: optionalStringOrNullWhenBlank(json, 'name') ?? '',
      paymentTypeId: requiredString(json, 'payment_type_id'),
      status: requiredString(json, 'status'),
      thumbnail: optionalStringOrNullWhenBlank(json, 'thumbnail') ?? '',
      secureThumbnail:
          optionalStringOrNullWhenBlank(json, 'secure_thumbnail') ?? '',
      minAllowedAmount: minAllowedAmount,
      maxAllowedAmount: maxAllowedAmount,
      accreditationTime: accreditationTime,
      additionalInfoNeeded: optionalStringList(json, 'additional_info_needed'),
      cardNumberLengthMin: minLength,
      cardNumberLengthMax: maxLength,
      securityCodeLength: cvvLength,
      securityCodeLocation: cvvLocation,
      processingMode: optionalStringOrNullWhenBlank(json, 'processing_mode'),
      merchantAccountId: optionalStringOrNullWhenBlank(
        json,
        'merchant_account_id',
      ),
      siteId: optionalStringOrNullWhenBlank(json, 'site_id'),
      minAccreditationDays: optionalInt(
        json,
        'min_accreditation_days',
        allowNumericString: true,
      ),
      maxAccreditationDays: optionalInt(
        json,
        'max_accreditation_days',
        allowNumericString: true,
      ),
      totalFinancialCost: optionalDouble(
        json,
        'total_financial_cost',
        allowNumericString: true,
      ),
      financialInstitutions: json['financial_institutions'] == null
          ? const []
          : requiredObjectList(
              json,
              'financial_institutions',
              PaymentMethodFinancialInstitutionDto.fromJson,
            ),
      issuer: issuerJson == null
          ? null
          : PaymentMethodIssuerDto.fromJson(issuerJson),
      card: card,
      bins: optionalIntList(json, 'bins'),
      marketplace: optionalStringOrNullWhenBlank(json, 'marketplace'),
      deferredCapture: optionalStringOrNullWhenBlank(json, 'deferred_capture'),
      agreements: json['agreements'] == null
          ? const []
          : requiredObjectList(
              json,
              'agreements',
              PaymentAgreementDto.fromJson,
            ),
      payerCosts: payerCosts,
      labels: optionalStringList(json, 'labels'),
    );
  }

  static (double, double) _allowedAmountRange(
    List<PaymentMethodPayerCostDto> costs,
  ) {
    final mins = <double>[];
    final maxs = <double>[];
    for (final cost in costs) {
      final min = cost.minAllowedAmount;
      final max = cost.maxAllowedAmount;
      if (min != null) mins.add(min);
      if (max != null) maxs.add(max);
    }
    final min = mins.isEmpty ? 0.0 : mins.reduce((a, b) => a < b ? a : b);
    final max = maxs.isEmpty
        ? double.infinity
        : maxs.reduce((a, b) => a > b ? a : b);
    if (min < 0 || max < min) {
      throw const FormatException(
        'Response allowed amounts must define a non-negative range.',
      );
    }
    return (min, max);
  }

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
  final int? cardNumberLengthMin;
  final int? cardNumberLengthMax;
  final int? securityCodeLength;
  final String? securityCodeLocation;
  final String? processingMode;
  final String? merchantAccountId;
  final String? siteId;
  final int? minAccreditationDays;
  final int? maxAccreditationDays;
  final double? totalFinancialCost;
  final List<PaymentMethodFinancialInstitutionDto> financialInstitutions;
  final PaymentMethodIssuerDto? issuer;
  final PaymentMethodCardDto? card;
  final List<int> bins;
  final String? marketplace;
  final String? deferredCapture;
  final List<PaymentAgreementDto> agreements;
  final List<PaymentMethodPayerCostDto> payerCosts;
  final List<String> labels;

  PaymentMethod toDomain() => PaymentMethod(
    id: id,
    name: name,
    paymentTypeId: paymentTypeId,
    status: status,
    thumbnail: thumbnail,
    secureThumbnail: secureThumbnail,
    minAllowedAmount: minAllowedAmount,
    maxAllowedAmount: maxAllowedAmount,
    accreditationTime: accreditationTime,
    additionalInfoNeeded: additionalInfoNeeded,
    cardNumberLengthMin: cardNumberLengthMin,
    cardNumberLengthMax: cardNumberLengthMax,
    securityCodeLength: securityCodeLength,
    securityCodeLocation: securityCodeLocation,
    processingMode: processingMode,
    merchantAccountId: merchantAccountId,
    siteId: siteId,
    minAccreditationDays: minAccreditationDays,
    maxAccreditationDays: maxAccreditationDays,
    totalFinancialCost: totalFinancialCost,
    financialInstitutions: financialInstitutions
        .map((value) => value.toDomain())
        .toList(growable: false),
    issuer: issuer?.toDomain(),
    card: card?.toDomain(),
    bins: bins,
    marketplace: marketplace,
    deferredCapture: deferredCapture,
    agreements: agreements
        .map((value) => value.toDomain())
        .toList(growable: false),
    payerCosts: payerCosts
        .map((value) => value.toDomain())
        .toList(growable: false),
    labels: labels,
  );
}

class PaymentMethodFinancialInstitutionDto {
  const PaymentMethodFinancialInstitutionDto({
    required this.id,
    required this.description,
  });

  factory PaymentMethodFinancialInstitutionDto.fromJson(
    Map<String, dynamic> json,
  ) => PaymentMethodFinancialInstitutionDto(
    id: optionalStringOrNullWhenBlank(json, 'id'),
    description: optionalStringOrNullWhenBlank(json, 'description') ?? '',
  );

  final String? id;
  final String description;

  PaymentMethodFinancialInstitution toDomain() =>
      PaymentMethodFinancialInstitution(id: id, description: description);
}

class PaymentMethodIssuerDto {
  const PaymentMethodIssuerDto({
    required this.id,
    required this.isDefault,
    required this.thumbnail,
  });

  factory PaymentMethodIssuerDto.fromJson(Map<String, dynamic> json) =>
      PaymentMethodIssuerDto(
        id: optionalStringOrInteger(json, 'id'),
        isDefault: optionalBool(json, 'default'),
        thumbnail: optionalStringOrNullWhenBlank(json, 'thumbnail'),
      );

  final String? id;
  final bool? isDefault;
  final String? thumbnail;

  PaymentMethodIssuer toDomain() =>
      PaymentMethodIssuer(id: id, isDefault: isDefault, thumbnail: thumbnail);
}

class PaymentMethodCardDto {
  const PaymentMethodCardDto({
    required this.bin,
    required this.length,
    required this.validation,
    required this.securityCode,
  });

  factory PaymentMethodCardDto.fromJson(Map<String, dynamic> json) {
    final length = optionalMap(json, 'length');
    final securityCode = optionalMap(json, 'security_code');
    return PaymentMethodCardDto(
      bin: optionalInt(json, 'bin', allowNumericString: true),
      length: length == null
          ? null
          : PaymentMethodCardLengthDto.fromJson(length),
      validation: optionalStringOrNullWhenBlank(json, 'validation'),
      securityCode: securityCode == null
          ? null
          : PaymentMethodSecurityCodeDto.fromJson(securityCode),
    );
  }

  final int? bin;
  final PaymentMethodCardLengthDto? length;
  final String? validation;
  final PaymentMethodSecurityCodeDto? securityCode;

  PaymentMethodCard toDomain() => PaymentMethodCard(
    bin: bin,
    length: length?.toDomain(),
    validation: validation,
    securityCode: securityCode?.toDomain(),
  );
}

class PaymentMethodCardLengthDto {
  const PaymentMethodCardLengthDto({required this.min, required this.max});

  factory PaymentMethodCardLengthDto.fromJson(Map<String, dynamic> json) =>
      PaymentMethodCardLengthDto(
        min: optionalInt(json, 'min', allowNumericString: true),
        max: optionalInt(json, 'max', allowNumericString: true),
      );

  final int? min;
  final int? max;

  PaymentMethodCardLength toDomain() =>
      PaymentMethodCardLength(min: min, max: max);
}

class PaymentMethodSecurityCodeDto {
  const PaymentMethodSecurityCodeDto({
    required this.mode,
    required this.location,
    required this.length,
  });

  factory PaymentMethodSecurityCodeDto.fromJson(Map<String, dynamic> json) =>
      PaymentMethodSecurityCodeDto(
        mode: optionalStringOrNullWhenBlank(json, 'mode'),
        location: optionalStringOrNullWhenBlank(json, 'location'),
        length: optionalInt(json, 'length', allowNumericString: true),
      );

  final String? mode;
  final String? location;
  final int? length;

  PaymentMethodSecurityCode toDomain() =>
      PaymentMethodSecurityCode(mode: mode, location: location, length: length);
}

class PaymentMethodPayerCostDto {
  const PaymentMethodPayerCostDto({
    required this.installments,
    required this.installmentAmount,
    required this.installmentRate,
    required this.installmentRateCollector,
    required this.totalAmount,
    required this.discountRate,
    required this.reimbursementRate,
    required this.minAllowedAmount,
    required this.maxAllowedAmount,
    required this.paymentMethodOptionId,
    required this.labels,
  });

  factory PaymentMethodPayerCostDto.fromJson(Map<String, dynamic> json) {
    final installments = optionalInt(
      json,
      'installments',
      allowNumericString: true,
    );
    final min = optionalDouble(
      json,
      'min_allowed_amount',
      allowNumericString: true,
    );
    final max = optionalDouble(
      json,
      'max_allowed_amount',
      allowNumericString: true,
    );
    final installmentAmount = optionalDouble(
      json,
      'installment_amount',
      allowNumericString: true,
    );
    final totalAmount = optionalDouble(
      json,
      'total_amount',
      allowNumericString: true,
    );
    if ((installments != null && installments <= 0) ||
        (installmentAmount != null && installmentAmount < 0) ||
        (totalAmount != null && totalAmount < 0) ||
        (min != null && min < 0) ||
        (max != null && min != null && max < min)) {
      throw const FormatException(
        'Response payer_costs contains an invalid installment or amount range.',
      );
    }
    return PaymentMethodPayerCostDto(
      installments: installments,
      installmentAmount: installmentAmount,
      installmentRate: optionalDouble(
        json,
        'installment_rate',
        allowNumericString: true,
      ),
      installmentRateCollector: optionalStringList(
        json,
        'installment_rate_collector',
      ),
      totalAmount: totalAmount,
      discountRate: optionalDouble(
        json,
        'discount_rate',
        allowNumericString: true,
      ),
      reimbursementRate: optionalDouble(
        json,
        'reimbursement_rate',
        allowNumericString: true,
      ),
      minAllowedAmount: min,
      maxAllowedAmount: max,
      paymentMethodOptionId: optionalStringOrNullWhenBlank(
        json,
        'payment_method_option_id',
      ),
      labels: optionalStringList(json, 'labels'),
    );
  }

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

  PaymentMethodPayerCost toDomain() => PaymentMethodPayerCost(
    installments: installments,
    installmentAmount: installmentAmount,
    installmentRate: installmentRate,
    installmentRateCollector: installmentRateCollector,
    totalAmount: totalAmount,
    discountRate: discountRate,
    reimbursementRate: reimbursementRate,
    minAllowedAmount: minAllowedAmount,
    maxAllowedAmount: maxAllowedAmount,
    paymentMethodOptionId: paymentMethodOptionId,
    labels: labels,
  );
}
