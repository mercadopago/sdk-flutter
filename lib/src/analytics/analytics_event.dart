/// Event types tracked by the SDK.
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.data = const {}});

  const AnalyticsEvent.sdkInitialize() : this(name: 'sdk_initialize');
  const AnalyticsEvent.tokenizeSuccess()
      : this(name: 'core_methods_tokenize_success');
  const AnalyticsEvent.tokenizeFailed()
      : this(name: 'core_methods_tokenize_failed');
  const AnalyticsEvent.checkoutStart() : this(name: 'checkout_start');
  const AnalyticsEvent.checkoutComplete() : this(name: 'checkout_complete');
  const AnalyticsEvent.checkoutCancel() : this(name: 'checkout_cancel');
  const AnalyticsEvent.checkoutError() : this(name: 'checkout_error');

  factory AnalyticsEvent.installmentSelected({required int installments}) =>
      AnalyticsEvent(
        name: 'installment_selected',
        data: {'installments': installments},
      );

  factory AnalyticsEvent.issuerSelected({required String issuerId}) =>
      AnalyticsEvent(
        name: 'issuer_selected',
        data: {'issuer_id': issuerId},
      );

  final String name;
  final Map<String, Object?> data;
}
