import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  test('native CoreMethods contract types are exported publicly', () {
    const agreement = PaymentAgreement(
      merchantAccounts: [
        AgreementMerchantAccount(
          id: 'merchant-1',
          paymentMethodOptionId: 'option-1',
        ),
      ],
      timeFrame: AgreementTimeFrame(
        startDate: '2026-01-01',
        endDate: '2026-12-31',
      ),
    );
    const card = PaymentMethodCard(
      bin: 450995,
      length: PaymentMethodCardLength(min: 16, max: 16),
      validation: 'standard',
      securityCode: PaymentMethodSecurityCode(
        mode: 'mandatory',
        location: 'back',
        length: 3,
      ),
    );

    expect(agreement.merchantAccounts.single.id, 'merchant-1');
    expect(card.securityCode?.length, 3);
  });
}
