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
    // The /cho-off/v1/payment_methods response shape (verified against the
    // canonical iOS PaymentMethodsResponse.swift and Android
    // PaymentMethodResponse.kt):
    //
    //   card: {
    //     bin: Int            ← the BIN itself (NOT an object with min/max)
    //     length: { min, max }
    //     validation: String
    //     security_code: { mode, location, length }
    //   }
    //
    // Some MercadoPago account configurations omit numeric scalars or send
    // them as strings; treat every field defensively so a missing or wrongly
    // typed value never throws a cast error.
    final card = _asMap(json['card']);
    final length = _asMap(card['length']);
    final securityCode = _asMap(card['security_code']);

    return PaymentMethodDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      paymentTypeId: json['payment_type_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      thumbnail: json['thumbnail'] as String? ?? '',
      secureThumbnail: json['secure_thumbnail'] as String? ?? '',
      minAllowedAmount: _asDouble(json['min_allowed_amount']) ?? 0,
      maxAllowedAmount:
          _asDouble(json['max_allowed_amount']) ?? double.infinity,
      accreditationTime: _asInt(json['accreditation_time']) ?? 0,
      additionalInfoNeeded:
          (json['additional_info_needed'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      binLengthMin: _asInt(length['min']) ?? 6,
      binLengthMax: _asInt(length['max']) ?? 19,
      securityCodeLength: _asInt(securityCode['length']) ?? 3,
      securityCodeLocation: securityCode['location'] as String? ?? 'back',
    );
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
