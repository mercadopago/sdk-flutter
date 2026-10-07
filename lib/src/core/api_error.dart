/// Low-level error raised by [ApiClient] when an HTTP request fails.
///
/// This is an internal type — public consumers of the SDK see
/// `MercadoPagoError` instead (mapped by repository implementations).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.isTimeout = false,
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetwork;

  bool get isRetriable =>
      isTimeout ||
      isNetwork ||
      (statusCode != null && statusCode! >= 500 && statusCode! < 600);

  @override
  String toString() =>
      'ApiException(status: $statusCode, message: $message, '
      'timeout: $isTimeout, network: $isNetwork)';
}
