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
          // Always sent (empty when absent) to keep the track valid, matching iOS.
          'identity_document_type': identityDocumentType ?? '',
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
          'identity_document_type': identityDocumentType ?? '',
          'type_wallet': 'coremethods',
        },
      );

  /// Card-form opened —
  /// `/checkout_api_native/checkout/card_form/initialize`.
  factory AnalyticsEvent.checkoutStart({
    required String checkoutType,
    required String appearance,
    List<String> sellerCustomization = const [],
    List<String> excludedPaymentTypes = const [],
    List<String> excludedPaymentMethods = const [],
    String? orderId,
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/card_form/initialize',
        data: {
          'checkout_type': checkoutType,
          'appearance': appearance,
          'seller_customization': sellerCustomization,
          if (excludedPaymentTypes.isNotEmpty)
            'excluded_payment_types': excludedPaymentTypes,
          if (excludedPaymentMethods.isNotEmpty)
            'excluded_payment_methods': excludedPaymentMethods,
          'order_id': orderId ?? 'NOT_APPLY',
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

  // ---- CoreMethods query tracks (fired by the low-level getters) ----

  /// `getPaymentMethods` succeeded — `/core_methods/payment_methods`.
  factory AnalyticsEvent.paymentMethods({
    String issuer = '',
    String cardBrand = '',
    String paymentType = '',
    int securityLength = 0,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/payment_methods',
        data: {
          'issuer': issuer,
          'card_brand': cardBrand,
          'payment_type': paymentType,
          'security_length': securityLength,
        },
      );

  /// `getPaymentMethods` failed — `/core_methods/payment_methods/error`.
  factory AnalyticsEvent.paymentMethodsError({required String errorType}) =>
      AnalyticsEvent(
        path: '$_base/core_methods/payment_methods/error',
        data: {'error_type': errorType, 'issuer': '', 'card_brand': ''},
      );

  /// `getInstallments` succeeded — `/core_methods/installments`.
  factory AnalyticsEvent.installments({
    String paymentType = '',
    required double transactionAmount,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/installments',
        data: {
          'payment_type': paymentType,
          'transaction_amount': transactionAmount,
        },
      );

  /// `getInstallments` failed — `/core_methods/installments/error`.
  factory AnalyticsEvent.installmentsError({
    required String errorType,
    required double transactionAmount,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/installments/error',
        data: {'error_type': errorType, 'transaction_amount': transactionAmount},
      );

  /// `getIssuers` succeeded — `/core_methods/issuers`.
  factory AnalyticsEvent.issuers({required List<String> issuers}) =>
      AnalyticsEvent(
        path: '$_base/core_methods/issuers',
        data: {'issuers': issuers},
      );

  /// `getIssuers` failed — `/core_methods/issuers/error`.
  factory AnalyticsEvent.issuersError({required String errorType}) =>
      AnalyticsEvent(
        path: '$_base/core_methods/issuers/error',
        data: {'error_type': errorType, 'issuers': <String>[]},
      );

  /// `getIdentificationTypes` succeeded — `/core_methods/identification_types`.
  factory AnalyticsEvent.identificationTypes({
    required List<String> documentTypes,
  }) =>
      AnalyticsEvent(
        path: '$_base/core_methods/identification_types',
        data: {'document_types': documentTypes},
      );

  /// `getIdentificationTypes` failed — `.../identification_types/error`.
  factory AnalyticsEvent.identificationTypesError({required String errorType}) =>
      AnalyticsEvent(
        path: '$_base/core_methods/identification_types/error',
        data: {'error_type': errorType, 'document_types': <String>[]},
      );

  // ---- Installments screen tracks ----

  /// Installments screen shown — `/checkout/installments/initialize` (a view).
  factory AnalyticsEvent.installmentsInitialize({
    required String checkoutType,
    required String paymentMethodId,
    required String paymentType,
    required String selectionType,
    required int quotasCount,
    required double transactionAmount,
    String? orderId,
  }) =>
      AnalyticsEvent(
        type: TrackType.view,
        path: '$_base/checkout/installments/initialize',
        data: {
          'checkout_type': checkoutType,
          'payment_method_id': paymentMethodId,
          'payment_type': paymentType,
          'selection_type': selectionType,
          'quotas_count': quotasCount,
          'transaction_amount': transactionAmount,
          'order_id': orderId ?? 'NOT_APPLY',
        },
      );

  /// Installments confirmed — `/checkout/installments/submit`.
  factory AnalyticsEvent.installmentsSubmit({
    required int installments,
    required double installmentAmount,
    required double totalAmount,
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/installments/submit',
        data: {
          'installments': installments,
          'installment_amount': installmentAmount,
          'total_amount': totalAmount,
        },
      );

  /// Installments screen cancelled —
  /// `/checkout/installments/user_canceled_error`. [reason] is
  /// `back_pressed` or `user_dismissed`.
  factory AnalyticsEvent.installmentsCancel({
    String reason = 'user_dismissed',
  }) =>
      AnalyticsEvent(
        path: '$_base/checkout/installments/user_canceled_error',
        data: {'error_type': reason},
      );

  static const String _base = '/checkout_api_native';

  /// Full melidata path (base `/checkout_api_native`).
  final String path;

  /// Track type — `event` for actions, `view` for screen views.
  final TrackType type;

  /// Non-sensitive contextual payload for this event.
  final Map<String, Object?> data;
}
