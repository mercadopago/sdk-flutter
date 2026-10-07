import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/session_manager.dart';
import 'analytics_event.dart';

/// Fire-and-forget analytics dispatcher.
///
/// Emits the melidata `tracks[]` schema used by the native Android/iOS SDKs so
/// Flutter events land in the shared Data Studio dashboard. The wire contract
/// is aligned with Android (lowercase `type`, `user_time` as an epoch-ms
/// string, `null`s omitted, `public_key` as a query param) and reports the new
/// platform dimension `/mobile/flutter`.
///
/// Network failures are intentionally swallowed — analytics must never break
/// the integrator's payment flow.
///
/// When constructed with `enabled: false`, [track] is a no-op: events are
/// neither added to the in-memory queue nor sent over the network.
///
/// **Security note**: [AnalyticsEvent.data] must never contain PCI data
/// (card numbers, CVVs, expiration dates) or personal data. The map is
/// serialized verbatim and sent to the MercadoLibre tracks endpoint. Stick
/// to non-sensitive contextual values (installment count, issuer ID, etc.).
class AnalyticsService {
  AnalyticsService({
    required SessionManager sessionManager,
    required String publicKey,
    required String siteId,
    http.Client? httpClient,
    Uuid? uuid,
    int maxPendingEvents = 20,
    this.enabled = true,
  }) : assert(maxPendingEvents > 0, 'maxPendingEvents must be positive'),
       _sessions = sessionManager,
       _key = publicKey,
       _site = siteId,
       _client = httpClient ?? http.Client(),
       _uuid = uuid ?? const Uuid(),
       _maxPendingEvents = maxPendingEvents;

  /// Stable per-process install identifier used as the melidata `uid`.
  ///
  /// Generated once for the lifetime of the process and held in memory only —
  /// the SDK never persists it (matching its "no on-device storage" policy).
  /// The native Android SDK persists a random UUID here; a per-process id is a
  /// deliberate, privacy-preserving simplification that survives
  /// `setNewConfiguration` (which rotates the session id, not the uid).
  static final String _installId = const Uuid().v4();

  final SessionManager _sessions;
  final String _key;
  final String _site;
  final http.Client _client;
  final Uuid _uuid;
  final int _maxPendingEvents;
  final bool enabled;
  Future<void> _queue = Future<void>.value();
  int _pendingEvents = 0;
  bool _closed = false;

  void track(AnalyticsEvent event) {
    if (!enabled || _closed || _pendingEvents >= _maxPendingEvents) return;
    _pendingEvents++;
    _queue = _queue
        .then((_) => _send(event))
        .whenComplete(() => _pendingEvents--);
    unawaited(_queue);
  }

  Future<void> _send(AnalyticsEvent event) async {
    if (!enabled || _closed) return;
    try {
      final track = _stripNulls({
        'path': event.path,
        'type': 'event',
        'id': _uuid.v4(),
        'user_time': DateTime.now().millisecondsSinceEpoch.toString(),
        'event_data': _stripNulls(event.data),
        'user': {'uid': _installId, 'melidata_session_id': _sessions.sessionId},
        'application': {
          'business': 'mercadopago',
          'site_id': _site,
          'version': kSdkVersion,
        },
        'device': {
          'platform': kAnalyticsPlatform,
          'os_version': Platform.operatingSystemVersion,
        },
      });

      final uri = Uri.parse(
        kTracksUrl,
      ).replace(queryParameters: {'public_key': _key});
      await _client
          .post(
            uri,
            headers: const {kHeaderContentType: kContentTypeJson},
            body: jsonEncode({
              'tracks': [track],
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Swallow — analytics never break the host flow.
    }
  }

  /// Removes `null` values so the payload matches the native contract, which
  /// omits absent fields rather than sending explicit nulls.
  Map<String, Object?> _stripNulls(Map<String, Object?> map) {
    final result = <String, Object?>{};
    map.forEach((key, value) {
      if (value == null) return;
      result[key] = value is Map<String, Object?> ? _stripNulls(value) : value;
    });
    return result;
  }

  void close() {
    _closed = true;
    _client.close();
  }
}
