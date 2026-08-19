import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/src/data/dtos/card_bin_dto.dart';
import 'package:mercadopago/src/data/dtos/card_form_init_dto.dart';

void main() {
  group('CardFormInitDto.parse', () {
    final json = <String, dynamic>{
      'identification_types': [
        {'id': 'DNI', 'name': 'DNI', 'min_length': 7, 'max_length': 8, 'type': 'number'},
      ],
      'card_number': {
        'type': 'number',
        'length': {'min': 16, 'max': 16},
        'mask': r'$$$$ $$$$ $$$$ $$$$',
      },
      'security_code': {'type': 'number', 'length': 3, 'card_location': 'back'},
      'holder_name': {
        'type': 'string',
        'length': {'min': 1, 'max': 25},
      },
      'expiration_date': {
        'type': 'number',
        'mask': 'MM/YY',
        'length': {'min': 4, 'max': 4},
      },
      'translations': {
        'card_form_title': 'Enter your card',
        'card_form_footer_button_label': 'Continue',
        'currency_symbol': r'$',
        'card_number': {'label': 'Card number', 'placeholder': '1234'},
        'holder_name': {'label': 'Name'},
        'expiration_date': {'label': 'Expiry'},
        'security_code': {'label': 'CVV', 'tooltip': '3 digits'},
        'document': {'label': 'Document', 'error_empty_field': 'required'},
        'installments': {
          'header': {'title': 'Installments'},
          'total_label': 'Total',
          'pay_button_label': 'Pay',
        },
      },
      'amount': 1500.5,
    };

    test('parses field specs, translations, doc types and amount', () {
      final config = CardFormInitDto.parse(json);

      expect(config.cardNumber.maxLength, 16);
      expect(config.cardNumber.mask, r'$$$$ $$$$ $$$$ $$$$');
      expect(config.securityCode.length, 3);
      expect(config.securityCode.cardLocation, 'back');
      expect(config.expirationDate.mask, 'MM/YY');
      expect(config.identificationTypes, hasLength(1));
      expect(config.identificationTypes.first.id, 'DNI');
      expect(config.translations.title, 'Enter your card');
      expect(config.translations.footerButtonLabel, 'Continue');
      expect(config.translations.cardNumber.placeholder, '1234');
      expect(config.translations.installmentsHeaderTitle, 'Installments');
      expect(config.amount, 1500.5);
    });

    test('tolerates a minimal payload with missing optional blocks', () {
      final config = CardFormInitDto.parse(const {});
      expect(config.identificationTypes, isEmpty);
      expect(config.amount, isNull);
      expect(config.cardNumber.maxLength, 0);
      expect(config.translations.title, isEmpty);
    });
  });

  group('CardBinDto.parse', () {
    test('parses aggregated methods, issuers, CVV and installment quotas', () {
      final json = <String, dynamic>{
        'payment_methods': [
          {
            'id': 'visa',
            'payment_type_id': 'credit_card',
            'card_number': {
              'type': 'number',
              'length': {'min': 16, 'max': 16},
              'mask': '',
            },
            'security_code': {
              'mode': 'mandatory',
              'length': 3,
              'type': 'number',
              'tooltip': 't',
              'placeholder': '123',
            },
            'issuers': [
              {'id': '1', 'name': 'Bank A'},
            ],
          },
        ],
        'installment': {
          'selection_type': 'chevron',
          'quotas': [
            {
              'installments': 1,
              'installment_amount': 1500,
              'total_amount': 1500,
              'primary_label': '1x 1500',
              'secondary_label': 'Total 1500',
              'state': 'success',
            },
            {
              'installments': 3,
              'installment_amount': 520,
              'total_amount': 1560,
              'primary_label': '3x 520',
              'secondary_label': 'Total 1560',
            },
          ],
        },
      };

      final data = CardBinDto.parse(json);

      expect(data.paymentMethods, hasLength(1));
      final method = data.paymentMethods.first;
      expect(method.id, 'visa');
      expect(method.paymentTypeId, 'credit_card');
      expect(method.securityCode?.length, 3);
      expect(method.issuers.first.id, '1');

      expect(data.installments, hasLength(2));
      expect(data.installments.first.installments, 1);
      expect(data.installments.first.totalAmount, 1500);
      // state "success" pre-selects the option.
      expect(data.installments.first.selected, isTrue);
      expect(data.installments[1].selected, isFalse);
    });

    test('treats an absent security_code as "CVV not required"', () {
      final json = <String, dynamic>{
        'payment_methods': [
          {'id': 'elo', 'payment_type_id': 'debit_card'},
        ],
      };
      final data = CardBinDto.parse(json);
      expect(data.paymentMethods.first.securityCode, isNull);
      expect(data.paymentMethods.first.issuers, isEmpty);
      expect(data.installments, isEmpty);
    });
  });
}
