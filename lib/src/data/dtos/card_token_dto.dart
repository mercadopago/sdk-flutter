import '../../domain/models/card_token.dart';

class CardTokenDto {
  const CardTokenDto({
    required this.id,
    required this.cardholderName,
    required this.firstSixDigits,
    required this.lastFourDigits,
    required this.expirationMonth,
    required this.expirationYear,
    required this.status,
    required this.dateCreated,
    required this.dateDue,
    required this.luhnValidation,
    required this.liveMode,
    required this.requireEsc,
    required this.cardNumberLength,
    required this.securityCodeLength,
  });

  factory CardTokenDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException("CardToken response missing required 'id' field.");
    }
    final dateCreated =
        DateTime.tryParse(json['date_created'] as String? ?? '');
    final dateDue = DateTime.tryParse(json['date_due'] as String? ?? '');

    return CardTokenDto(
      id: id,
      cardholderName:
          (json['cardholder'] as Map<String, dynamic>?)?['name'] as String? ??
              '',
      firstSixDigits: json['first_six_digits'] as String? ?? '',
      lastFourDigits: json['last_four_digits'] as String? ?? '',
      expirationMonth: (json['expiration_month'] as num?)?.toInt() ?? 0,
      expirationYear: (json['expiration_year'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      dateCreated: dateCreated ??
          DateTime.now().toUtc(), // fallback; token is still usable
      dateDue: dateDue ??
          DateTime.now().toUtc().add(const Duration(minutes: 15)),
      luhnValidation: json['luhn_validation'] as bool? ?? true,
      liveMode: json['live_mode'] as bool? ?? false,
      requireEsc: json['require_esc'] as bool? ?? false,
      cardNumberLength: (json['card_number_length'] as num?)?.toInt() ?? 16,
      securityCodeLength: (json['security_code_length'] as num?)?.toInt() ?? 3,
    );
  }

  final String id;
  final String cardholderName;
  final String firstSixDigits;
  final String lastFourDigits;
  final int expirationMonth;
  final int expirationYear;
  final String status;
  final DateTime dateCreated;
  final DateTime dateDue;
  final bool luhnValidation;
  final bool liveMode;
  final bool requireEsc;
  final int cardNumberLength;
  final int securityCodeLength;

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
