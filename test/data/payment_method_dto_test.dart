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
          'bin': 45099535, // <-- the scalar bin that previously triggered
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
      expect(method.binLengthMin, 13);
      expect(method.binLengthMax, 19);
      expect(method.securityCodeLength, 3);
      expect(method.securityCodeLocation, 'back');
    });

    test('returns defaults when card is missing', () {
      final method = PaymentMethodDto.fromJson({'id': 'visa'}).toDomain();
      expect(method.binLengthMin, 6);
      expect(method.binLengthMax, 19);
      expect(method.securityCodeLength, 3);
      expect(method.securityCodeLocation, 'back');
    });

    test('tolerates string-typed numbers (some MP accounts return strings)',
        () {
      final method = PaymentMethodDto.fromJson({
        'id': 'visa',
        'min_allowed_amount': '1.5',
        'max_allowed_amount': '9999.99',
        'accreditation_time': '120',
        'card': {
          'length': {'min': '13', 'max': '19'},
          'security_code': {'length': '4', 'location': 'front'},
        },
      }).toDomain();
      expect(method.minAllowedAmount, 1.5);
      expect(method.maxAllowedAmount, 9999.99);
      expect(method.accreditationTime, 120);
      expect(method.binLengthMin, 13);
      expect(method.binLengthMax, 19);
      expect(method.securityCodeLength, 4);
      expect(method.securityCodeLocation, 'front');
    });
  });
}
