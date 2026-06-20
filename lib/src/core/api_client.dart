import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_error.dart';
import 'constants.dart';
import 'session_manager.dart';

/// Internal HTTP client used by all repository implementations.
///
/// Responsibilities:
/// * Attach the mandatory headers (`X-Product-id`, `Meli-Session-id`,
///   `SDK-version`) to every request.
/// * Append `public_key` as a query parameter on every GET.
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
    DateTime Function()? clock,
  })  : _sessionManager = sessionManager,
        _publicKey = publicKey,
        _client = httpClient ?? http.Client(),
        _timeout = timeout,
        _cacheTtl = cacheTtl,
        _clock = clock ?? DateTime.now;

  final SessionManager _sessionManager;
  final String _publicKey;
  final http.Client _client;
  final Duration _timeout;
  final Duration _cacheTtl;
  final DateTime Function() _clock;
  final Map<String, _CacheEntry> _cache = {};

  /// Performs a GET request. Responses are cached for [_cacheTtl] unless
  /// [cache] is `false`.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool cache = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final cacheKey = uri.toString();

    if (cache) {
      final entry = _cache[cacheKey];
      if (entry != null && !entry.isExpired(_clock(), _cacheTtl)) {
        return entry.body;
      }
    }

    final body = await _send(
      () => _client
          .get(uri, headers: _headers())
          .timeout(_timeout, onTimeout: _onTimeout),
    );

    if (cache) {
      _cache[cacheKey] = _CacheEntry(body, _clock());
    }
    return body;
  }

  /// Returns a GET response decoded as a JSON list.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParameters,
    bool cache = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final cacheKey = '$uri::list';

    if (cache) {
      final entry = _cache[cacheKey];
      if (entry != null && !entry.isExpired(_clock(), _cacheTtl)) {
        return entry.body['__list__'] as List<dynamic>;
      }
    }

    final decoded = await _sendRaw(
      () => _client
          .get(uri, headers: _headers())
          .timeout(_timeout, onTimeout: _onTimeout),
    );

    if (decoded is! List) {
      throw const ApiException(message: 'Expected JSON array response.');
    }

    if (cache) {
      _cache[cacheKey] = _CacheEntry({'__list__': decoded}, _clock());
    }
    return decoded;
  }

  /// Performs a POST request with a JSON body. Responses are never cached.
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = {
      ..._headers(),
      kHeaderContentType: kContentTypeJson,
    };
    return _send(
      () => _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout, onTimeout: _onTimeout),
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

  Uri _buildUri(String path, Map<String, String>? extraQuery) {
    final base = Uri.parse('$kApiBaseUrl$path');
    final query = <String, String>{
      'public_key': _publicKey,
      ...?extraQuery,
    };
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Map<String, String> _headers() => {
        kHeaderProductId: kProductId,
        kHeaderSessionId: _sessionManager.sessionId,
        kHeaderSdkVersion: kSdkVersion,
        kHeaderUserAgent: 'MercadoPagoFlutterSDK/$kSdkVersion',
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
        message: _safeMessage(response.body),
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

  String _safeMessage(String body) {
    if (body.isEmpty) return 'HTTP error with no body.';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // fall through
    }
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }

  http.Response _onTimeout() {
    throw TimeoutException('Request exceeded ${_timeout.inSeconds}s timeout.');
  }
}

class _CacheEntry {
  _CacheEntry(this.body, this.storedAt);

  final Map<String, dynamic> body;
  final DateTime storedAt;

  bool isExpired(DateTime now, Duration ttl) =>
      now.difference(storedAt) >= ttl;
}
