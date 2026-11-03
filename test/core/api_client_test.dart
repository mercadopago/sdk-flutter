import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_client.dart';
import 'package:mercadopago_sdk_flutter/src/core/api_error.dart';
import 'package:mercadopago_sdk_flutter/src/core/constants.dart';
import 'package:mercadopago_sdk_flutter/src/core/session_manager.dart';

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
      int maxCacheEntries = ApiClient.defaultMaxCacheEntries,
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
        maxCacheEntries: maxCacheEntries,
        clock: clock,
      );
    }

    test(
      'GET sends public_key + product_id query, no X-Product-id header',
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
      },
    );

    test('GET with sendProductId:false omits the product_id query', () async {
      final client = buildClient((_) async => http.Response('[]', 200));
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

    test(
      'POST card_tokens sends X-Product-id header, no product_id query',
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
      },
    );

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

    test('bounds the GET cache and evicts the oldest entry', () async {
      final calls = <String, int>{};
      final client = buildClient((request) async {
        final path = request.url.path;
        calls[path] = (calls[path] ?? 0) + 1;
        return http.Response('{"path":"$path"}', 200);
      }, maxCacheEntries: 2);

      await client.get('/a');
      await client.get('/b');
      await client.get('/c');
      await client.get('/a');

      expect(client.cacheEntryCount, 2);
      expect(calls['/a'], 2);
      expect(calls['/b'], 1);
      expect(calls['/c'], 1);
    });

    test('purges expired entries before caching a fresh response', () async {
      var now = DateTime.utc(2026, 1, 1);
      final client = buildClient(
        (_) async => http.Response('{}', 200),
        cacheTtl: const Duration(minutes: 1),
        maxCacheEntries: 3,
        clock: () => now,
      );

      await client.get('/a');
      await client.get('/b');
      expect(client.cacheEntryCount, 2);

      now = now.add(const Duration(minutes: 2));
      await client.get('/c');

      expect(client.cacheEntryCount, 1);
    });

    test('rejects a non-positive cache bound', () {
      expect(
        () => buildClient(
          (_) async => http.Response('{}', 200),
          maxCacheEntries: 0,
        ),
        throwsArgumentError,
      );
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
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('never reflects a non-JSON error body containing a PAN', () async {
      const pan = '4111111111111111';
      final client = buildClient(
        (_) async => http.Response('Rejected card $pan', 422),
      );

      await expectLater(
        () => client.get('/payment_methods'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.message, 'message', isNot(contains(pan)))
              .having(
                (error) => error.message,
                'message',
                'HTTP request failed with status 422.',
              ),
        ),
      );
    });

    test('never reflects structured remote messages', () async {
      final client = buildClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Card 4111 1111 1111 1111, CVV 123, token tok_secret',
          }),
          400,
        ),
      );

      await expectLater(
        () => client.get('/payment_methods'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'HTTP request failed with status 400.',
          ),
        ),
      );
    });
  });
}
