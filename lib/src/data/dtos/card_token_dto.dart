import '../../domain/models/card_token.dart';

class CardTokenDto {
  const CardTokenDto({
    required this.id,
    this.cardholderName,
    this.firstSixDigits,
    this.lastFourDigits,
    this.expirationMonth,
    this.expirationYear,
    this.status,
    this.dateCreated,
    this.dateDue,
    this.luhnValidation,
    this.liveMode,
    this.requireEsc,
    this.cardNumberLength,
    this.securityCodeLength,
  });

  factory CardTokenDto.fromJson(Map<String, dynamic> json) {
    final cardholder = _optionalMap(json, 'cardholder');

    return CardTokenDto(
      id: _requiredString(json, 'id'),
      cardholderName: cardholder == null
          ? null
          : _optionalString(cardholder, 'name', fieldName: 'cardholder.name'),
      firstSixDigits: _optionalString(json, 'first_six_digits'),
      lastFourDigits: _optionalString(json, 'last_four_digits'),
      expirationMonth: _optionalInt(json, 'expiration_month'),
      expirationYear: _optionalInt(json, 'expiration_year'),
      status: _optionalString(json, 'status'),
      dateCreated: _optionalDateTime(json, 'date_created'),
      dateDue: _optionalDateTime(json, 'date_due'),
      luhnValidation: _optionalBool(json, 'luhn_validation'),
      liveMode: _optionalBool(json, 'live_mode'),
      requireEsc: _optionalBool(json, 'require_esc'),
      cardNumberLength: _optionalInt(json, 'card_number_length'),
      securityCodeLength: _optionalInt(json, 'security_code_length'),
    );
  }

  static Map<String, dynamic>? _optionalMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    throw FormatException(
      "CardToken response field '$key' must be a JSON object.",
    );
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String key, {
    String? fieldName,
  }) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException(
      "CardToken response field '${fieldName ?? key}' must be a non-empty string.",
    );
  }

  static String? _optionalString(
    Map<String, dynamic> json,
    String key, {
    String? fieldName,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw FormatException(
      "CardToken response field '${fieldName ?? key}' must be a non-empty string when present.",
    );
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException(
      "CardToken response field '$key' must be an integer.",
    );
  }

  static bool? _optionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is bool) return value;
    throw FormatException(
      "CardToken response field '$key' must be a boolean when present.",
    );
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed != null) return parsed;
    throw FormatException(
      "CardToken response field '$key' must be an ISO-8601 date.",
    );
  }

  final String id;
  final String? cardholderName;
  final String? firstSixDigits;
  final String? lastFourDigits;
  final int? expirationMonth;
  final int? expirationYear;
  final String? status;
  final DateTime? dateCreated;
  final DateTime? dateDue;
  final bool? luhnValidation;
  final bool? liveMode;
  final bool? requireEsc;
  final int? cardNumberLength;
  final int? securityCodeLength;

  CardToken toDomain() => CardToken(
    token: id,
    bin: firstSixDigits,
    firstSixDigits: firstSixDigits,
    lastFourDigits: lastFourDigits,
    cardholderName: cardholderName,
    expirationMonth: expirationMonth,
    expirationYear: expirationYear,
    status: status,
    dateCreated: dateCreated,
    dateDue: dateDue,
    luhnValidation: luhnValidation,
    liveMode: liveMode,
    requireEsc: requireEsc,
    cardNumberLength: cardNumberLength,
    securityCodeLength: securityCodeLength,
  );
}
