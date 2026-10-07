import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/src/data/dtos/identification_type_dto.dart';
import 'package:mercadopago/src/data/dtos/installment_dto.dart';
import 'package:mercadopago/src/data/dtos/issuer_dto.dart';

void main() {
  group('IdentificationTypeDto', () {
    test('parses a complete response', () {
      final value = IdentificationTypeDto.fromJson({
        'id': 'DNI',
        'name': 'DNI',
        'type': 'number',
        'min_length': 7,
        'max_length': 8,
      }).toDomain();

      expect(value.id, 'DNI');
      expect(value.minLength, 7);
      expect(value.maxLength, 8);
    });

    test('rejects missing fields and invalid ranges', () {
      expect(
        () => IdentificationTypeDto.fromJson({
          'id': 'DNI',
          'name': 'DNI',
          'type': 'number',
          'min_length': 9,
          'max_length': 8,
        }),
        throwsFormatException,
      );
      expect(
        () => IdentificationTypeDto.fromJson({'id': 'DNI'}),
        throwsFormatException,
      );
    });
  });

  group('IssuerDto', () {
    test('parses a complete response', () {
      final value = IssuerDto.fromJson({
        'id': '123',
        'name': 'Bank',
        'thumbnail': 'https://example/bank.png',
        'secure_thumbnail': 'https://example/bank-secure.png',
        'processing_mode': 'aggregator',
        'status': 'active',
      }).toDomain();

      expect(value.id, '123');
      expect(value.processingMode, 'aggregator');
    });

    test('rejects responses without a critical identifier', () {
      expect(
        () => IssuerDto.fromJson({
          'name': 'Bank',
          'thumbnail': 'https://example/bank.png',
          'secure_thumbnail': 'https://example/bank-secure.png',
          'processing_mode': 'aggregator',
          'status': 'active',
        }),
        throwsFormatException,
      );
    });
  });

  group('InstallmentDto', () {
    Map<String, dynamic> completeResponse() => {
      'payment_method_id': 'visa',
      'payment_type_id': 'credit_card',
      'issuer': {
        'id': '123',
        'name': 'Bank',
        'thumbnail': 'https://example/bank.png',
        'secure_thumbnail': 'https://example/bank-secure.png',
      },
      'processing_mode': 'aggregator',
      'payer_costs': [
        {
          'installments': 1,
          'installment_rate': 0,
          'discount_rate': 0,
          'min_allowed_amount': 1,
          'max_allowed_amount': 250000,
          'installment_amount': 100,
          'total_amount': 100,
          'labels': <String>[],
          'payment_method_option_id': 'option-1',
        },
      ],
    };

    test(
      'parses a complete response with optional merchant account absent',
      () {
        final value = InstallmentDto.fromJson(completeResponse()).toDomain();

        expect(value.paymentMethodId, 'visa');
        expect(value.merchantAccountId, isNull);
        expect(value.payerCosts.single.installments, 1);
      },
    );

    test('rejects malformed payer-cost entries instead of discarding them', () {
      final json = completeResponse();
      json['payer_costs'] = [42];

      expect(() => InstallmentDto.fromJson(json), throwsFormatException);
    });

    test(
      'tolerates a missing monetary field (contract declares it nullable)',
      () {
        // Android `PayerCostResponse` declares every field nullable, so a payload
        // without `total_amount` is valid and the native SDKs accept it.
        final json = completeResponse();
        final payerCost =
            (json['payer_costs'] as List<dynamic>).single
                as Map<String, dynamic>;
        payerCost.remove('total_amount');

        final dto = InstallmentDto.fromJson(json);
        expect(dto.payerCosts.single.totalAmount, 0);
      },
    );

    test('still rejects a present-but-negative monetary field', () {
      // Absence is tolerated; corruption is not.
      final json = completeResponse();
      final payerCost =
          (json['payer_costs'] as List<dynamic>).single as Map<String, dynamic>;
      payerCost['total_amount'] = -1;

      expect(() => InstallmentDto.fromJson(json), throwsFormatException);
    });

    test('rejects inconsistent payer-cost amounts', () {
      final json = completeResponse();
      final payerCost =
          (json['payer_costs'] as List<dynamic>).single as Map<String, dynamic>;
      payerCost['min_allowed_amount'] = 200;
      payerCost['max_allowed_amount'] = 100;

      expect(() => InstallmentDto.fromJson(json), throwsFormatException);
    });
  });
}
