import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/src/data/dtos/card_token_dto.dart';

Map<String, dynamic> validCardTokenJson() => {
  'id': 'tok_test_123',
  'cardholder': {'name': 'JOHN DOE'},
  'first_six_digits': '411111',
  'last_four_digits': '1111',
  'expiration_month': 12,
  'expiration_year': 2030,
  'status': 'active',
  'date_created': '2026-01-01T00:00:00.000Z',
  'date_due': '2026-01-01T00:15:00.000Z',
  'luhn_validation': true,
  'live_mode': false,
  'require_esc': false,
  'card_number_length': 16,
  'security_code_length': 3,
};

void main() {
  group('CardTokenDto.fromJson', () {
    test('maps a complete card-token response without synthesized values', () {
      final token = CardTokenDto.fromJson(validCardTokenJson()).toDomain();

      expect(token.token, 'tok_test_123');
      expect(token.cardholderName, 'JOHN DOE');
      expect(token.dateCreated, DateTime.utc(2026, 1, 1));
      expect(token.dateDue, DateTime.utc(2026, 1, 1, 0, 15));
      expect(token.luhnValidation, isTrue);
      expect(token.cardNumberLength, 16);
      expect(token.securityCodeLength, 3);
    });

    test('accepts the canonical response with only token id', () {
      final token = CardTokenDto.fromJson({'id': 'tok_test_123'}).toDomain();

      expect(token.token, 'tok_test_123');
      expect(token.firstSixDigits, isNull);
      expect(token.cardholderName, isNull);
      expect(token.liveMode, isNull);
      expect(token.requireEsc, isNull);
    });

    test('keeps an omitted boolean absent instead of inventing a default', () {
      final json = validCardTokenJson()..remove('luhn_validation');

      final token = CardTokenDto.fromJson(json).toDomain();

      expect(token.luhnValidation, isNull);
    });

    test('keeps missing require_esc absent', () {
      final json = validCardTokenJson()..remove('require_esc');

      final token = CardTokenDto.fromJson(json).toDomain();

      expect(token.requireEsc, isNull);
    });

    test('rejects require_esc when present with an invalid type', () {
      final json = validCardTokenJson()..['require_esc'] = 'false';

      expect(
        () => CardTokenDto.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message.toString(),
            'message',
            contains('require_esc'),
          ),
        ),
      );
    });

    test('rejects an invalid date instead of synthesizing token lifetime', () {
      final json = validCardTokenJson()..['date_due'] = 'not-a-date';

      expect(
        () => CardTokenDto.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message.toString(),
            'message',
            contains('date_due'),
          ),
        ),
      );
    });
  });
}
