import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago_flutter_sdk/src/core/api_client.dart';
import 'package:mercadopago_flutter_sdk/src/core/api_error.dart';
import 'package:mercadopago_flutter_sdk/src/core/constants.dart';
import 'package:mercadopago_flutter_sdk/src/core/session_manager.dart';

void main() {
  group('ApiClient', () {
    late SessionManager session;
    late List<http.Request> sentRequests;

    setUp(() {
      session = SessionManager();
      sentRequests = [];
    });

    ApiClient buildClient(
      Future<http.Response> Function(http.Request request) handler, {
      Duration cacheTtl = kCacheTtl,
      DateTime Function()? clock,
    }) {
      final mock = MockClient((request) async {
        sentRequests.add(request);
        return handler(request);
      });
      return ApiClient(
        sessionManager: session,
        publicKey: 'APP_USR-test',
        httpClient: mock,
        cacheTtl: cacheTtl,
        clock: clock,
      );
    }

    test('sends mandatory headers on GET requests', () async {
      final client = buildClient(
        (_) async => http.Response('{"ok":true}', 200),
      );
      await client.get('/v1/identification_types');

      final req = sentRequests.single;
      expect(req.headers[kHeaderProductId], kProductId);
      expect(req.headers[kHeaderSessionId], session.sessionId);
      expect(req.headers[kHeaderSdkVersion], kSdkVersion);
      expect(req.url.queryParameters['public_key'], 'APP_USR-test');
      // GETs MUST include product_id as a query parameter — the API
      // returns 400 'missing product_id' otherwise.
      expect(req.url.queryParameters['product_id'], kProductId);
    });

    test('sends mandatory headers on POST requests', () async {
      final client = buildClient(
        (_) async => http.Response('{"id":"abc"}', 200),
      );
      await client.post('/v1/card_tokens', body: {'card_number': '4111'});

      final req = sentRequests.single;
      expect(req.method, 'POST');
      expect(req.headers[kHeaderContentType], kContentTypeJson);
      expect(req.headers[kHeaderProductId], kProductId);
      expect(req.headers[kHeaderSessionId], session.sessionId);
      // POST card_tokens MUST NOT carry product_id as a query parameter;
      // it travels only in the X-Product-id header (matches iOS/Android).
      expect(req.url.queryParameters['product_id'], isNull);
    });

    test('caches GET responses for the configured TTL', () async {
      var calls = 0;
      final client = buildClient((_) async {
        calls++;
        return http.Response(jsonEncode({'n': calls}), 200);
      });

      final first = await client.get('/payment_methods');
      final second = await client.get('/payment_methods');
      expect(first['n'], 1);
      expect(second['n'], 1);
      expect(calls, 1);
    });

    test('does not cache POST responses', () async {
      var calls = 0;
      final client = buildClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      await client.post('/v1/card_tokens', body: {});
      await client.post('/v1/card_tokens', body: {});
      expect(calls, 2);
    });

    test('throws ApiException on non-2xx status', () async {
      final client = buildClient(
        (_) async => http.Response('{"message":"nope"}', 400),
      );
      expect(
        () => client.get('/payment_methods'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });
}
