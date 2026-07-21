/// Melidata track type. The tracks endpoint distinguishes user-facing screen
/// views (`view`) from discrete actions (`event`). Serialized lowercase to
/// match the native Android contract (`MetricToAnalyticsRemoteMapper`).
enum TrackType { event, view }

/// A single melidata track.
///
/// Each event carries the exact `path` and `event_data` shape used by the
/// native Android/iOS SDKs so Flutter tokenizations land in the same Data
/// Studio dashboard. The `path` values are ported verbatim from the native
/// `*AnalyticsPath` definitions (base `/checkout_api_native`).
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.path,
    this.type = TrackType.event,
    this.data = const {},
  });

  /// `SDK.initialize()` — `/checkout_api_native/initialize`.
  ///
  /// Only the fields the Flutter SDK can source faithfully are sent
  /// (`distribution`/`min_version` are omitted rather than invented).
  factory AnalyticsEvent.sdkInitialize({
    String? locale,
    required String publicKey,
    required bool developerMode,
    required String sdkVersion,
  }) =>
      AnalyticsEvent(
        path: '$_base/initialize',
        data: {
          if (locale != null) 'locale': locale,
          'public_key': publicKey,
          'sdk_version': sdkVersion,
          'developer_mode': developerMode,
        },
      );

  /// Successful tokenization — `/checkout_api_native/core_methods/tokenization`.
  factory AnalyticsEvent.tokenizeSuccess({
    required bool isSavedCard,
    String? identityDocumentType,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/tokenization',
        data: {
          'is_saved_card': isSavedCard,
          if (identityDocumentType != null)
            'identity_document_type': identityDocumentType,
          'type_wallet': 'coremethods',
        },
      );

  /// Failed tokenization —
  /// `/checkout_api_native/core_methods/tokenization/error`.
  factory AnalyticsEvent.tokenizeFailed({
    required bool isSavedCard,
    String? identityDocumentType,
    String? errorType,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/tokenization/error',
        data: {
          if (errorType != null) 'error_type': errorType,
          'is_saved_card': isSavedCard,
          if (identityDocumentType != null)
            'identity_document_type': identityDocumentType,
          'type_wallet': 'coremethods',
        },
      );

  /// Card-form opened —
  /// `/checkout_api_native/checkout/card_form/initialize`.
  factory AnalyticsEvent.checkoutStart({
    required String checkoutType,
    List<String> excludedPaymentTypes = const [],
    List<String> excludedPaymentMethods = const [],
    String? orderId,
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/initialize',
        data: {
          'checkout_type': checkoutType,
          if (excludedPaymentTypes.isNotEmpty)
            'excluded_payment_types': excludedPaymentTypes,
          if (excludedPaymentMethods.isNotEmpty)
            'excluded_payment_methods': excludedPaymentMethods,
          if (orderId != null) 'order_id': orderId,
        },
      );

  /// Card-form initialization failed —
  /// `/checkout_api_native/checkout/card_form/initialize_error`.
  factory AnalyticsEvent.checkoutInitializeError({required String errorType}) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/initialize_error',
        data: {'error_type': errorType},
      );

  /// Card-form submitted — `/checkout_api_native/checkout/card_form/submit`.
  factory AnalyticsEvent.checkoutComplete({
    String? cardBrand,
    double? transactionAmount,
    String? issuer,
    String? paymentType,
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/submit',
        data: {
          if (cardBrand != null) 'card_brand': cardBrand,
          if (transactionAmount != null) 'transaction_amount': transactionAmount,
          if (issuer != null) 'issuer': issuer,
          if (paymentType != null) 'payment_type': paymentType,
        },
      );

  /// Card-form submit failed —
  /// `/checkout_api_native/checkout/card_form/submit_error`.
  factory AnalyticsEvent.checkoutError({required String errorType}) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/submit_error',
        data: {'error_type': errorType},
      );

  /// Checkout cancelled by the user —
  /// `/checkout_api_native/checkout/card_form/user_canceled_error`.
  factory AnalyticsEvent.checkoutCancel({String errorType = 'user_canceled'}) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/user_canceled_error',
        data: {'error_type': errorType},
      );

  /// Installment option selected —
  /// `/checkout_api_native/checkout/installments/selected`.
  factory AnalyticsEvent.installmentSelected({required int installments}) =>
      AnalyticsEvent(
        path: '$_base/checkout/installments/selected',
        data: {'installments': installments},
      );

  /// A dropdown (e.g. issuer or document type) was selected —
  /// `/checkout_api_native/checkout/card_form/dropdown_selection`.
  factory AnalyticsEvent.dropdownSelection({
    required String dropdownSelectionType,
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/dropdown_selection',
        data: {'dropdown_selection_type': dropdownSelectionType},
      );

  static const String _base = '/checkout_api_native';

  /// Full melidata path (base `/checkout_api_native`).
  final String path;

  /// Track type — `event` for actions, `view` for screen views.
  final TrackType type;

  /// Non-sensitive contextual payload for this event.
  final Map<String, Object?> data;
}
