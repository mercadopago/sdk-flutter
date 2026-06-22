import '../../domain/models/payment_method.dart';

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
    required this.binLengthMin,
    required this.binLengthMax,
    required this.securityCodeLength,
    required this.securityCodeLocation,
  });

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    final card = (json['card'] as Map<String, dynamic>?) ?? const {};
    final bin = (card['bin'] as Map<String, dynamic>?) ?? const {};
    final length = (card['length'] as Map<String, dynamic>?) ?? const {};
    final securityCode =
        (card['security_code'] as Map<String, dynamic>?) ?? const {};

    return PaymentMethodDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      paymentTypeId: json['payment_type_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      thumbnail: json['thumbnail'] as String? ?? '',
      secureThumbnail: json['secure_thumbnail'] as String? ?? '',
      minAllowedAmount:
          (json['min_allowed_amount'] as num?)?.toDouble() ?? 0,
      maxAllowedAmount: (json['max_allowed_amount'] as num?)?.toDouble() ??
          double.infinity,
      accreditationTime:
          (json['accreditation_time'] as num?)?.toInt() ?? 0,
      additionalInfoNeeded:
          (json['additional_info_needed'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      binLengthMin: (bin['min'] as num?)?.toInt() ?? 6,
      binLengthMax: (length['max'] as num?)?.toInt() ?? 19,
      securityCodeLength: (securityCode['length'] as num?)?.toInt() ?? 3,
      securityCodeLocation:
          securityCode['card_location'] as String? ?? 'back',
    );
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
  final int binLengthMin;
  final int binLengthMax;
  final int securityCodeLength;
  final String securityCodeLocation;

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
        binLengthMin: binLengthMin,
        binLengthMax: binLengthMax,
        securityCodeLength: securityCodeLength,
        securityCodeLocation: securityCodeLocation,
      );
}
