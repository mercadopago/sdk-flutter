import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/src/data/dtos/payment_method_dto.dart';

void main() {
  group('PaymentMethodDto.fromJson', () {
    test('parses real /payment_methods response shape (card.bin is Int)', () {
      // Shape captured from sdk-ios PaymentMethodsResponse.swift and
      // sdk-android PaymentMethodResponse.kt — both authoritative sources
      // declare card.bin as a scalar Int (NOT a {min, max} object).
      final json = <String, dynamic>{
        'id': 'visa',
        'name': 'Visa',
        'payment_type_id': 'credit_card',
        'status': 'active',
        'thumbnail': 'https://example/visa.png',
        'secure_thumbnail': 'https://example/visa-secure.png',
        'min_allowed_amount': 1,
        'max_allowed_amount': 250000,
        'accreditation_time': 0,
        'additional_info_needed': ['cardholder_name'],
        'card': {
          'bin': 450995, // <-- the scalar bin that previously triggered
          //     'int is not a subtype of Map' crash
          'length': {'min': 13, 'max': 19},
          'validation': 'luhn',
          'security_code': {
            'mode': 'mandatory',
            'location': 'back',
            'length': 3,
          },
        },
      };

      final dto = PaymentMethodDto.fromJson(json);
      final method = dto.toDomain();

      expect(method.id, 'visa');
      expect(method.cardNumberLengthMin, 13);
      expect(method.cardNumberLengthMax, 19);
      expect(method.securityCodeLength, 3);
      expect(method.securityCodeLocation, 'back');
    });

    test('rejects a response with missing required fields', () {
      expect(
        () => PaymentMethodDto.fromJson({'id': 'visa'}),
        throwsFormatException,
      );
    });

    test(
      'tolerates string-typed numbers (some MP accounts return strings)',
      () {
        final method = PaymentMethodDto.fromJson({
          'id': 'visa',
          'name': 'Visa',
          'payment_type_id': 'credit_card',
          'status': 'active',
          'thumbnail': 'https://example/visa.png',
          'secure_thumbnail': 'https://example/visa-secure.png',
          'payer_costs': [
            {'min_allowed_amount': '1.5', 'max_allowed_amount': '9999.99'},
          ],
          'accreditation_time': '120',
          'additional_info_needed': <String>[],
          'card': {
            'length': {'min': '13', 'max': '19'},
            'security_code': {'length': '4', 'location': 'front'},
          },
        }).toDomain();
        expect(method.minAllowedAmount, 1.5);
        expect(method.maxAllowedAmount, 9999.99);
        expect(method.accreditationTime, 120);
        expect(method.cardNumberLengthMin, 13);
        expect(method.cardNumberLengthMax, 19);
        expect(method.securityCodeLength, 4);
        expect(method.securityCodeLocation, 'front');
      },
    );

    test('preserves card metadata without enforcing tokenization rules', () {
      final json = <String, dynamic>{
        'id': 'visa',
        'name': 'Visa',
        'payment_type_id': 'credit_card',
        'status': 'active',
        'thumbnail': 'https://example/visa.png',
        'secure_thumbnail': 'https://example/visa-secure.png',
        'min_allowed_amount': 1,
        'max_allowed_amount': 250000,
        'accreditation_time': 0,
        'additional_info_needed': <String>[],
        'card': {
          'length': {'min': 6, 'max': 19},
          'security_code': {'location': 'back', 'length': 5},
        },
      };

      final method = PaymentMethodDto.fromJson(json).toDomain();

      expect(method.cardNumberLengthMin, 6);
      expect(method.cardNumberLengthMax, 19);
      expect(method.securityCodeLength, 5);
      expect(method.securityCodeLocation, 'back');
    });

    test('accepts partial PAN and CVV metadata from the native contract', () {
      final method = PaymentMethodDto.fromJson(const {
        'id': 'visa',
        'payment_type_id': 'credit_card',
        'status': 'active',
        'card': {
          'length': {'min': 13},
          'security_code': {'mode': 'mandatory'},
        },
      }).toDomain();

      expect(method.cardNumberLengthMin, 13);
      expect(method.cardNumberLengthMax, isNull);
      expect(method.securityCodeLength, isNull);
      expect(method.securityCodeLocation, isNull);
      expect(method.card?.securityCode?.mode, 'mandatory');
    });

    test('still rejects a present card value with the wrong type', () {
      expect(
        () => PaymentMethodDto.fromJson(const {
          'id': 'visa',
          'payment_type_id': 'credit_card',
          'status': 'active',
          'card': false,
        }),
        throwsFormatException,
      );
    });

    test('rejects inconsistent allowed amounts inside payer_costs', () {
      // Allowed amounts live in payer_costs[] per the native contract, so the
      // range check applies to the values derived from there.
      final json = <String, dynamic>{
        'id': 'visa',
        'payment_type_id': 'credit_card',
        'status': 'active',
        'accreditation_time': 0,
        'payer_costs': [
          {'min_allowed_amount': 100, 'max_allowed_amount': 10},
        ],
        'card': {
          'length': {'min': 13, 'max': 19},
          'security_code': {'location': 'back', 'length': 3},
        },
      };

      expect(() => PaymentMethodDto.fromJson(json), throwsFormatException);
    });
  });
}
