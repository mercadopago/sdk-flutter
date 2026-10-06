/// Agreement associated with a payment method or installment option.
class PaymentAgreement {
  const PaymentAgreement({this.merchantAccounts = const [], this.timeFrame});

  /// Merchant accounts covered by this agreement.
  final List<AgreementMerchantAccount> merchantAccounts;

  /// Period during which the agreement is valid, when supplied by the API.
  final AgreementTimeFrame? timeFrame;
}

/// Merchant account referenced by a [PaymentAgreement].
class AgreementMerchantAccount {
  const AgreementMerchantAccount({this.id, this.paymentMethodOptionId});

  final String? id;
  final String? paymentMethodOptionId;
}

/// API-provided validity range for a [PaymentAgreement].
///
/// Dates remain strings because both native SDKs expose the wire values and
/// do not share a stricter cross-platform date type.
class AgreementTimeFrame {
  const AgreementTimeFrame({this.startDate, this.endDate});

  final String? startDate;
  final String? endDate;
}
