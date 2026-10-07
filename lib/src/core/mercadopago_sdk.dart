import 'package:flutter/foundation.dart' show kDebugMode;

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import '../core_methods/core_methods.dart';
import '../data/repositories/identification_repository_impl.dart';
import '../data/repositories/installment_repository_impl.dart';
import '../data/repositories/issuer_repository_impl.dart';
import '../data/repositories/payment_method_repository_impl.dart';
import '../fingerprint/fingerprint_service.dart';
import '../pci/pci.dart';
import 'api_client.dart';
import 'configuration.dart';
import 'constants.dart';
import 'sdk_error.dart';
import 'session_manager.dart';

/// Public entry point of the MercadoPago Flutter SDK.
///
/// Call [initialize] on [shared] once at startup, then access [coreMethods] to
/// interact with the API.
class MercadoPagoSDK {
  MercadoPagoSDK._internal();

  static final MercadoPagoSDK shared = MercadoPagoSDK._internal();

  Configuration? _configuration;
  SessionManager? _sessionManager;
  ApiClient? _apiClient;
  CoreMethods? _coreMethods;
  AnalyticsService? _analytics;

  bool get isInitialized => _configuration != null;

  Configuration get configuration {
    final c = _configuration;
    if (c == null) throw const SDKNotInitializedError();
    return c;
  }

  /// UUID for the current session. Sent in the `Meli-Session-id` header on
  /// every request.
  String get sessionId {
    final s = _sessionManager;
    if (s == null) throw const SDKNotInitializedError();
    return s.sessionId;
  }

  CoreMethods get coreMethods {
    final c = _coreMethods;
    if (c == null) throw const SDKNotInitializedError();
    return c;
  }

  /// Initializes the SDK with the given credentials.
  ///
  /// Throws:
  /// * [SDKAlreadyInitializedError] if called twice without first calling
  ///   [setNewConfiguration].
  /// * [SDKInvalidPublicKeyError] for a malformed [publicKey].
  /// * [SDKInvalidCountryError] for an unsupported [countryCode].
  ///
  /// Set [analyticsEnabled] to `false` to prevent analytics events from being
  /// queued or sent. It defaults to `true` for native-SDK parity.
  void initialize({
    required String publicKey,
    required String countryCode,
    String? locale,
    bool analyticsEnabled = true,
  }) {
    if (isInitialized) throw const SDKAlreadyInitializedError();
    _bootstrap(
      Configuration.fromValues(
        publicKey: publicKey,
        countryCode: countryCode,
        locale: locale,
        analyticsEnabled: analyticsEnabled,
      ),
    );
    _trackInitialize();
  }

  /// Replaces the active configuration. A new session UUID is generated and
  /// cached GET responses are cleared.
  ///
  /// Set [analyticsEnabled] explicitly to `false` when the replacement
  /// configuration must remain opted out of analytics.
  void setNewConfiguration({
    required String publicKey,
    required String countryCode,
    String? locale,
    bool analyticsEnabled = true,
  }) {
    final configuration = Configuration.fromValues(
      publicKey: publicKey,
      countryCode: countryCode,
      locale: locale,
      analyticsEnabled: analyticsEnabled,
    );
    _tearDown();
    _bootstrap(configuration);
    _trackInitialize();
  }

  void _trackInitialize() {
    final c = configuration;
    _analytics?.track(
      AnalyticsEvent.sdkInitialize(
        locale: c.locale,
        publicKey: c.publicKey,
        developerMode: kDebugMode,
        sdkVersion: kSdkVersion,
      ),
    );
  }

  /// Releases held resources. The SDK becomes uninitialized after this call.
  /// Intended for tests; production apps generally do not need to call it.
  void dispose() {
    _tearDown();
  }

  void _bootstrap(Configuration configuration) {
    final sessionManager = SessionManager();
    final apiClient = ApiClient(
      sessionManager: sessionManager,
      publicKey: configuration.publicKey,
    );
    final fingerprint = FingerprintService();
    final analytics = AnalyticsService(
      sessionManager: sessionManager,
      publicKey: configuration.publicKey,
      siteId: configuration.country.siteId,
      enabled: configuration.analyticsEnabled,
    );

    final tokenizer = PciTokenizer(api: apiClient);
    final paymentMethodRepo = PaymentMethodRepositoryImpl(apiClient);
    final installmentRepo = InstallmentRepositoryImpl(apiClient);
    final issuerRepo = IssuerRepositoryImpl(apiClient);
    final identificationRepo = IdentificationRepositoryImpl(apiClient);

    _configuration = configuration;
    _sessionManager = sessionManager;
    _apiClient = apiClient;
    _analytics = analytics;
    _coreMethods = CoreMethods(
      tokenizer: tokenizer,
      paymentMethodRepository: paymentMethodRepo,
      installmentRepository: installmentRepo,
      issuerRepository: issuerRepo,
      identificationRepository: identificationRepo,
      fingerprintService: fingerprint,
      analytics: analytics,
    );
  }

  void _tearDown() {
    _apiClient?.close();
    _analytics?.close();
    _configuration = null;
    _sessionManager = null;
    _apiClient = null;
    _coreMethods = null;
    _analytics = null;
  }
}
