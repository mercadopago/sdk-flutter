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

    test('GET sends public_key + product_id query, no X-Product-id header',
        () async {
      final client = buildClient(
        (_) async => http.Response('{"ok":true}', 200),
      );
      await client.get('/cho-off/v1/payment_methods');

      final req = sentRequests.single;
      // Always-on headers.
      expect(req.headers[kHeaderSessionId], session.sessionId);
      expect(req.headers[kHeaderSdkVersion], kSdkVersion);
      // CoreMethods GETs authenticate with public_key + product_id as query
      // params — never the X-Product-id header (that is POST card_tokens only).
      expect(req.url.queryParameters['public_key'], 'APP_USR-test');
      expect(req.url.queryParameters['product_id'], kProductId);
      expect(req.headers[kHeaderProductId], isNull);
      expect(req.headers[kHeaderPublicKey], isNull);
    });

    test('GET with sendProductId:false omits the product_id query', () async {
      final client = buildClient(
        (_) async => http.Response('[]', 200),
      );
      await client.getList(
        '/cho-off/v1/identification_types',
        sendProductId: false,
      );

      final req = sentRequests.single;
      // identification_types takes neither product_id query nor header.
      expect(req.url.queryParameters['product_id'], isNull);
      expect(req.headers[kHeaderProductId], isNull);
      // public_key still travels as a query param.
      expect(req.url.queryParameters['public_key'], 'APP_USR-test');
    });

    test('GET with publicKeyHeader auth uses X-Public-Key header', () async {
      final client = buildClient(
        (_) async => http.Response('{"ok":true}', 200),
      );
      await client.get(
        '/cho-off/v1/card_payment_brick/initialization',
        authMode: AuthMode.publicKeyHeader,
        queryParameters: {'checkout_type': 'card_save'},
      );

      final req = sentRequests.single;
      // BFF: public_key travels in the X-Public-Key header, NOT the query.
      expect(req.headers[kHeaderPublicKey], 'APP_USR-test');
      expect(req.url.queryParameters['public_key'], isNull);
      // product_id remains a query param on the BFF.
      expect(req.url.queryParameters['product_id'], kProductId);
    });

    test('GET forwards extra headers (e.g. Authorization Bearer)', () async {
      final client = buildClient(
        (_) async => http.Response('{"ok":true}', 200),
      );
      await client.get(
        '/cho-off/v1/card_payment_brick/initialization',
        authMode: AuthMode.publicKeyHeader,
        extraHeaders: const {kHeaderAuthorization: 'Bearer tok_123'},
      );

      expect(sentRequests.single.headers[kHeaderAuthorization], 'Bearer tok_123');
    });

    test('POST card_tokens sends X-Product-id header, no product_id query',
        () async {
      final client = buildClient(
        (_) async => http.Response('{"id":"abc"}', 200),
      );
      await client.post(
        '/v1/card_tokens',
        body: {'card_number': '4111'},
        sendProductIdHeader: true,
      );

      final req = sentRequests.single;
      expect(req.method, 'POST');
      expect(req.headers[kHeaderContentType], kContentTypeJson);
      expect(req.headers[kHeaderProductId], kProductId);
      expect(req.headers[kHeaderSessionId], session.sessionId);
      // public_key travels as a query param; product_id must NOT (header only).
      expect(req.url.queryParameters['public_key'], 'APP_USR-test');
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
