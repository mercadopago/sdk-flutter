import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/session_manager.dart';
import 'analytics_event.dart';

/// Fire-and-forget analytics dispatcher.
///
/// Network failures are intentionally swallowed — analytics must never break
/// the integrator's payment flow.
///
/// **Security note**: [AnalyticsEvent.data] must never contain PCI data
/// (card numbers, CVVs, expiration dates) or personal data. The map is
/// serialized verbatim and sent to the MercadoLibre tracks endpoint. Stick
/// to non-sensitive contextual values (installment count, issuer ID, etc.).
class AnalyticsService {
  AnalyticsService({
    required SessionManager sessionManager,
    http.Client? httpClient,
  })  : _sessionManager = sessionManager,
        _client = httpClient ?? http.Client();

  final SessionManager _sessionManager;
  final http.Client _client;

  void track(AnalyticsEvent event) {
    unawaited(_send(event));
  }

  Future<void> _send(AnalyticsEvent event) async {
    try {
      await _client
          .post(
            Uri.parse(kTracksUrl),
            headers: const {
              kHeaderContentType: kContentTypeJson,
              kHeaderProductId: kProductId,
              kHeaderSdkVersion: kSdkVersion,
            },
            body: jsonEncode({
              'event_name': event.name,
              'session_id': _sessionManager.sessionId,
              'sdk_version': kSdkVersion,
              'product_id': kProductId,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
              'event_data': event.data,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Swallow — analytics never break the host flow.
    }
  }

  void close() => _client.close();
}
