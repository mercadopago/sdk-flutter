import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago/src/analytics/analytics_event.dart';
import 'package:mercadopago/src/analytics/analytics_service.dart';
import 'package:mercadopago/src/core/session_manager.dart';

void main() {
  group('AnalyticsService — tracks[] payload', () {
    late SessionManager session;

    setUp(() => session = SessionManager());

    Future<http.Request> capture(AnalyticsEvent event) {
      final completer = Completer<http.Request>();
      final client = MockClient((request) async {
        if (!completer.isCompleted) completer.complete(request);
        return http.Response('', 200);
      });
      AnalyticsService(
        sessionManager: session,
        publicKey: 'APP_USR-test',
        siteId: 'MCO',
        httpClient: client,
      ).track(event);
      return completer.future.timeout(const Duration(seconds: 2));
    }

    test(
      'wraps the event in a tracks[] array (Android-aligned contract)',
      () async {
        final req = await capture(
          AnalyticsEvent.tokenizeSuccess(isSavedCard: false),
        );
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final tracks = body['tracks'] as List<dynamic>;
        expect(tracks, hasLength(1));

        final track = tracks.single as Map<String, dynamic>;
        expect(track['path'], '/checkout_api_native/core_methods/tokenization');
        // type is lowercase (Android contract), not iOS's capitalized form.
        expect(track['type'], 'event');
        // user_time is an epoch-ms string (Android), not a number.
        expect(track['user_time'], isA<String>());
        expect(int.tryParse(track['user_time'] as String), isNotNull);
        expect(track['id'], isNotEmpty);
      },
    );

    test('reports application, device and user blocks', () async {
      final req = await capture(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: true),
      );
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final track = (body['tracks'] as List).single as Map<String, dynamic>;

      final application = track['application'] as Map<String, dynamic>;
      expect(application['business'], 'mercadopago');
      expect(application['site_id'], 'MCO');
      expect(application['version'], isNotEmpty);

      final device = track['device'] as Map<String, dynamic>;
      expect(device['platform'], '/mobile/flutter');

      final user = track['user'] as Map<String, dynamic>;
      expect(user['uid'], isNotEmpty);
      expect(user['melidata_session_id'], session.sessionId);
    });

    test('sends public_key as a query param on /tracks', () async {
      final req = await capture(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: false),
      );
      expect(req.url.queryParameters['public_key'], 'APP_USR-test');
      expect(req.url.path, '/tracks');
    });

    test('always sends identity_document_type (empty when absent)', () async {
      // The field is always present (empty string when no document) so the
      // track stays valid — matching iOS. See review point 13.
      final req = await capture(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: false),
      );
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final track = (body['tracks'] as List).single as Map<String, dynamic>;
      final data = track['event_data'] as Map<String, dynamic>;
      expect(data['identity_document_type'], '');
      expect(data['is_saved_card'], isFalse);
      expect(data['type_wallet'], 'coremethods');
    });

    test('uid is stable across events (process-lifetime install id)', () async {
      final first = await capture(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: false),
      );
      final second = await capture(
        AnalyticsEvent.tokenizeSuccess(isSavedCard: true),
      );
      String uid(http.Request r) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final track = (body['tracks'] as List).single as Map<String, dynamic>;
        final user = track['user'] as Map<String, dynamic>;
        return user['uid'] as String;
      }

      expect(uid(first), uid(second));
    });

    test('rejects a non-positive pending-event limit', () {
      expect(
        () => AnalyticsService(
          sessionManager: session,
          publicKey: 'APP_USR-test',
          siteId: 'MCO',
          maxPendingEvents: 0,
        ),
        throwsAssertionError,
      );
    });

    test('does not enqueue or send events when disabled', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('', 200);
      });
      final service = AnalyticsService(
        sessionManager: session,
        publicKey: 'APP_USR-test',
        siteId: 'MCO',
        httpClient: client,
        enabled: false,
      );
      final event = AnalyticsEvent.tokenizeSuccess(isSavedCard: false);

      service
        ..track(event)
        ..track(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(calls, 0);
      service.close();
    });

    test(
      'serializes delivery and drops events beyond the pending limit',
      () async {
        final releaseFirst = Completer<void>();
        final secondSent = Completer<void>();
        var calls = 0;
        var active = 0;
        var maxActive = 0;
        final client = MockClient((request) async {
          calls++;
          active++;
          if (active > maxActive) maxActive = active;
          if (calls == 1) await releaseFirst.future;
          active--;
          if (calls == 2 && !secondSent.isCompleted) secondSent.complete();
          return http.Response('', 200);
        });
        final service = AnalyticsService(
          sessionManager: session,
          publicKey: 'APP_USR-test',
          siteId: 'MCO',
          httpClient: client,
          maxPendingEvents: 2,
        );
        final event = AnalyticsEvent.tokenizeSuccess(isSavedCard: false);

        service
          ..track(event)
          ..track(event)
          ..track(event);
        await Future<void>.delayed(Duration.zero);
        expect(calls, 1);

        releaseFirst.complete();
        await secondSent.future.timeout(const Duration(seconds: 2));

        expect(calls, 2);
        expect(maxActive, 1);
        service.close();
      },
    );
  });
}
