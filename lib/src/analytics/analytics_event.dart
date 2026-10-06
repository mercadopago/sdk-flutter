/// A single melidata track.
///
/// Each event carries the exact `path` and `event_data` shape used by the
/// native Android/iOS SDKs so Flutter tokenizations land in the same Data
/// Studio dashboard. The `path` values are ported verbatim from the native
/// `*AnalyticsPath` definitions (base `/checkout_api_native`).
class AnalyticsEvent {
  const AnalyticsEvent({required this.path, this.data = const {}});

  /// `SDK.initialize()` — `/checkout_api_native/initialize`.
  ///
  /// Only the fields the Flutter SDK can source faithfully are sent
  /// (`distribution`/`min_version` are omitted rather than invented).
  factory AnalyticsEvent.sdkInitialize({
    String? locale,
    required String publicKey,
    required bool developerMode,
    required String sdkVersion,
  }) => AnalyticsEvent(
    path: '$_base/initialize',
    data: {
      'locale': ?locale,
      'public_key': publicKey,
      'sdk_version': sdkVersion,
      'developer_mode': developerMode,
    },
  );

  /// Successful tokenization — `/checkout_api_native/core_methods/tokenization`.
  factory AnalyticsEvent.tokenizeSuccess({
    required bool isSavedCard,
    String? identityDocumentType,
  }) => AnalyticsEvent(
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
  }) => AnalyticsEvent(
    path: '$_base/core_methods/tokenization/error',
    data: {
      'error_type': ?errorType,
      'is_saved_card': isSavedCard,
      'identity_document_type': identityDocumentType ?? '',
      'type_wallet': 'coremethods',
    },
  );

  // ---- CoreMethods query tracks (fired by the low-level getters) ----

  /// `getPaymentMethods` succeeded — `/core_methods/payment_methods`.
  factory AnalyticsEvent.paymentMethods({
    String issuer = '',
    String cardBrand = '',
    String paymentType = '',
    int securityLength = 0,
  }) => AnalyticsEvent(
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
  }) => AnalyticsEvent(
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
  }) => AnalyticsEvent(
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
  }) => AnalyticsEvent(
    path: '$_base/core_methods/identification_types',
    data: {'document_types': documentTypes},
  );

  /// `getIdentificationTypes` failed — `.../identification_types/error`.
  factory AnalyticsEvent.identificationTypesError({
    required String errorType,
  }) => AnalyticsEvent(
    path: '$_base/core_methods/identification_types/error',
    data: {'error_type': errorType, 'document_types': <String>[]},
  );

  static const String _base = '/checkout_api_native';

  /// Full melidata path (base `/checkout_api_native`).
  final String path;

  /// Non-sensitive contextual payload for this event.
  final Map<String, Object?> data;
}
