import '../../domain/models/payment_agreement.dart';
import 'json_value.dart';

class PaymentAgreementDto {
  const PaymentAgreementDto({
    required this.merchantAccounts,
    required this.timeFrame,
  });

  factory PaymentAgreementDto.fromJson(Map<String, dynamic> json) {
    final timeFrame = optionalMap(json, 'time_frame');
    return PaymentAgreementDto(
      merchantAccounts: json['merchant_accounts'] == null
          ? const []
          : requiredObjectList(
              json,
              'merchant_accounts',
              AgreementMerchantAccountDto.fromJson,
            ),
      timeFrame: timeFrame == null
          ? null
          : AgreementTimeFrameDto.fromJson(timeFrame),
    );
  }

  final List<AgreementMerchantAccountDto> merchantAccounts;
  final AgreementTimeFrameDto? timeFrame;

  PaymentAgreement toDomain() => PaymentAgreement(
    merchantAccounts: merchantAccounts
        .map((account) => account.toDomain())
        .toList(growable: false),
    timeFrame: timeFrame?.toDomain(),
  );
}

class AgreementMerchantAccountDto {
  const AgreementMerchantAccountDto({
    required this.id,
    required this.paymentMethodOptionId,
  });

  factory AgreementMerchantAccountDto.fromJson(Map<String, dynamic> json) =>
      AgreementMerchantAccountDto(
        id: optionalStringOrNullWhenBlank(json, 'id'),
        paymentMethodOptionId: optionalStringOrNullWhenBlank(
          json,
          'payment_method_option_id',
        ),
      );

  final String? id;
  final String? paymentMethodOptionId;

  AgreementMerchantAccount toDomain() => AgreementMerchantAccount(
    id: id,
    paymentMethodOptionId: paymentMethodOptionId,
  );
}

class AgreementTimeFrameDto {
  const AgreementTimeFrameDto({required this.startDate, required this.endDate});

  factory AgreementTimeFrameDto.fromJson(Map<String, dynamic> json) =>
      AgreementTimeFrameDto(
        startDate: optionalStringOrNullWhenBlank(json, 'start_date'),
        endDate: optionalStringOrNullWhenBlank(json, 'end_date'),
      );

  final String? startDate;
  final String? endDate;

  AgreementTimeFrame toDomain() =>
      AgreementTimeFrame(startDate: startDate, endDate: endDate);
}
