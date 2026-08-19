import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/mercadopago.dart';

void main() {
  group('MPPaymentMethodConfig.card', () {
    test('defaults: no exclusions, installments 1..180', () {
      const config = MPCardConfig();
      expect(config.excludedTypes, isEmpty);
      expect(config.excludedBrands, isEmpty);
      expect(config.installment?.minInstallments, 1);
      expect(config.installment?.maxInstallments, 180);
    });

    test('factory builds an MPCardConfig with the given fields', () {
      const config = MPPaymentMethodConfig.card(
        excludedTypes: [MPCardType.debit],
        excludedBrands: [MPCardBrand.amex],
        installment: MPInstallment(maxInstallments: 3),
      );
      expect(config, isA<MPCardConfig>());
      const card = config as MPCardConfig;
      expect(card.excludedTypes, [MPCardType.debit]);
      expect(card.excludedBrands.single, MPCardBrand.amex);
      expect(card.installment?.maxInstallments, 3);
    });
  });

  group('MPCardConfig.from', () {
    test('returns the card config when present', () {
      const card = MPCardConfig(excludedTypes: [MPCardType.credit]);
      expect(MPCardConfig.from(const [card]).excludedTypes, [MPCardType.credit]);
    });

    test('returns a permissive default when absent', () {
      final config = MPCardConfig.from(const []);
      expect(config.excludedTypes, isEmpty);
      expect(config.excludedBrands, isEmpty);
      expect(config.installment?.minInstallments, 1);
    });
  });

  group('wire values', () {
    test('MPCardType maps to the API strings', () {
      expect(MPCardType.credit.value, 'credit_card');
      expect(MPCardType.debit.value, 'debit_card');
      expect(MPCardType.prepaid.value, 'prepaid_card');
    });

    test('MPCardBrand exposes brand ids and a custom escape hatch', () {
      expect(MPCardBrand.visa.value, 'visa');
      expect(const MPCardBrand.custom('some_brand').value, 'some_brand');
      // Equality is by wire value.
      expect(MPCardBrand.amex, const MPCardBrand.custom('amex'));
    });
  });
}
