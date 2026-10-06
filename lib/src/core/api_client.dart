import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'api_error.dart';
import 'constants.dart';
import 'session_manager.dart';

/// Internal HTTP client used by all repository implementations.
///
/// Responsibilities:
/// * Attach the always-on headers (`Meli-Session-id`, `SDK-version`,
///   `User-Agent`) to every request.
/// * Authenticate with the `public_key` query parameter expected by
///   CoreMethods endpoints.
/// * Attach `product_id` where the endpoint requires it (query on most GETs,
///   `X-Product-id` header on `POST /v1/card_tokens`, nowhere on
///   `identification_types`), matching the native SDK contract.
/// * Enforce a 30s default timeout.
/// * Cache idempotent GET responses for 5 minutes (in-memory only).
/// * Translate transport-level failures into [ApiException].
class ApiClient {
  ApiClient({
    required SessionManager sessionManager,
    required String publicKey,
    http.Client? httpClient,
    Duration timeout = kHttpTimeout,
    Duration cacheTtl = kCacheTtl,
    int maxCacheEntries = defaultMaxCacheEntries,
    DateTime Function()? clock,
  }) : _sessions = sessionManager,
       _key = publicKey,
       _client = _resolveClient(httpClient),
       _requestTimeout = timeout,
       _responseCacheTtl = cacheTtl,
       _maxCacheEntries = maxCacheEntries,
       _clock = clock ?? DateTime.now {
    if (maxCacheEntries <= 0) {
      throw ArgumentError.value(
        maxCacheEntries,
        'maxCacheEntries',
        'must be greater than zero',
      );
    }
  }

  static const int defaultMaxCacheEntries = 100;

  /// Honours an injected client in **debug builds only**.
  ///
  /// `http.Client` is a third-party interface the SDK cannot seal, so an
  /// injected client would otherwise be a way for application code to observe
  /// a tokenization request body — including the card number. Resolving it
  /// inside an `assert` means the parameter is inert in profile and release
  /// builds (asserts are stripped) while tests, which run in debug, keep
  /// injecting `MockClient` unchanged.
  ///
  /// This mirrors Flutter's own debug-override idiom (see
  /// `painting/_network_image_io.dart`).
  static http.Client _resolveClient(http.Client? injected) {
    http.Client? client;
    assert(() {
      client = injected;
      return true;
    }());
    return client ?? http.Client();
  }

  final SessionManager _sessions;
  final String _key;
  final http.Client _client;
  final Duration _requestTimeout;
  final Duration _responseCacheTtl;
  final int _maxCacheEntries;
  final DateTime Function() _clock;
  final Map<String, _CacheEntry> _cache = {};

  @visibleForTesting
  int get cacheEntryCount => _cache.length;

  /// Performs a GET request. Responses are cached for [_responseCacheTtl] unless
  /// [cache] is `false`.
  ///
  /// [sendProductId] controls the `product_id` query param — set `false` for
  /// endpoints that do
  /// not take it (e.g. `identification_types`).
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool cache = true,
    bool sendProductId = true,
  }) async {
    final uri = _buildUri(path, queryParameters, productIdQuery: sendProductId);
    final cacheKey = uri.toString();

    if (cache) {
      final entry = _readCache(cacheKey);
      if (entry != null) return entry.body;
    }

    final body = await _send(
      () => _client
          .get(uri, headers: _headers())
          .timeout(_requestTimeout, onTimeout: _onTimeout),
    );

    if (cache) {
      _storeCache(cacheKey, body);
    }
    return body;
  }

  /// Returns a GET response decoded as a JSON list. See [get] for parameters.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParameters,
    bool cache = true,
    bool sendProductId = true,
  }) async {
    final uri = _buildUri(path, queryParameters, productIdQuery: sendProductId);
    final cacheKey = '$uri::list';

    if (cache) {
      final entry = _readCache(cacheKey);
      if (entry != null) return entry.body['__list__'] as List<dynamic>;
    }

    final decoded = await _sendRaw(
      () => _client
          .get(uri, headers: _headers())
          .timeout(_requestTimeout, onTimeout: _onTimeout),
    );

    if (decoded is! List) {
      throw const ApiException(message: 'Expected JSON array response.');
    }

    if (cache) {
      _storeCache(cacheKey, {'__list__': decoded});
    }
    return decoded;
  }

  /// Performs a POST request with a JSON body. Responses are never cached.
  ///
  /// [sendProductIdHeader] attaches `X-Product-id` — required by
  /// `POST /v1/card_tokens`, matching the native SDK.
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? queryParameters,
    bool sendProductIdHeader = false,
  }) async {
    final uri = _buildUri(path, queryParameters, productIdQuery: false);
    final headers = {
      ..._headers(productIdHeader: sendProductIdHeader),
      kHeaderContentType: kContentTypeJson,
    };
    return _send(
      () => _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout, onTimeout: _onTimeout),
    );
  }

  /// Clears the in-memory GET cache. Called when configuration changes.
  void clearCache() {
    _cache.clear();
  }

  /// Disposes the underlying HTTP client.
  void close() {
    _client.close();
    _cache.clear();
  }

  _CacheEntry? _readCache(String key) {
    final now = _clock();
    _purgeExpired(now);
    return _cache[key];
  }

  void _storeCache(String key, Map<String, dynamic> body) {
    final now = _clock();
    _purgeExpired(now);

    if (!_cache.containsKey(key) && _cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CacheEntry(body, now);
  }

  void _purgeExpired(DateTime now) {
    _cache.removeWhere((_, entry) => entry.isExpired(now, _responseCacheTtl));
  }

  /// Builds a request URI, attaching `public_key` and/or `product_id` query
  /// params as dictated by the endpoint contract (see [get]/[post]).
  Uri _buildUri(
    String path,
    Map<String, String>? extraQuery, {
    required bool productIdQuery,
  }) {
    final base = Uri.parse('$kApiBaseUrl$path');
    final query = <String, String>{
      'public_key': _key,
      if (productIdQuery) 'product_id': kProductId,
      ...?extraQuery,
    };
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Map<String, String> _headers({bool productIdHeader = false}) => {
    kHeaderSessionId: _sessions.sessionId,
    kHeaderSdkVersion: kSdkVersion,
    kHeaderUserAgent: 'MercadoPagoFlutterSDK/$kSdkVersion',
    if (productIdHeader) kHeaderProductId: kProductId,
  };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final decoded = await _sendRaw(request);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(message: 'Expected JSON object response.');
    }
    return decoded;
  }

  Future<dynamic> _sendRaw(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on SocketException catch (e) {
      throw ApiException(message: e.message, isNetwork: true);
    } on http.ClientException catch (e) {
      throw ApiException(message: e.message, isNetwork: true);
    } on TimeoutException {
      throw const ApiException(message: 'Request timed out.', isTimeout: true);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        // Never reflect remote error bodies. Tokenization responses can echo
        // card, document, CVV, or token values in free-form messages.
        message: 'HTTP request failed with status ${response.statusCode}.',
      );
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(message: 'Invalid JSON in response body.');
    }
  }

  http.Response _onTimeout() {
    throw TimeoutException(
      'Request exceeded ${_requestTimeout.inSeconds}s timeout.',
    );
  }
}

class _CacheEntry {
  _CacheEntry(this.body, this.storedAt);

  final Map<String, dynamic> body;
  final DateTime storedAt;

  bool isExpired(DateTime now, Duration ttl) => now.difference(storedAt) >= ttl;
}
