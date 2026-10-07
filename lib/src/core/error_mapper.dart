import '../domain/errors.dart';
import 'api_error.dart';

/// Translates internal [ApiException]s into public [MercadoPagoError]s tagged
/// with the originating SDK location.
MercadoPagoError mapApiError(Object error, ErrorLocation location) {
  if (error is ApiException) {
    return NetworkError(
      message: error.message,
      isRetriable: error.isRetriable,
      statusCode: error.statusCode,
      location: location,
    );
  }
  // Unknown exception text is not part of a trusted contract and can include
  // request or response data. Expose only its type to avoid reflecting
  // sensitive values through the public error surface.
  return UnknownError(
    message: 'Unexpected SDK error (${error.runtimeType}).',
    location: location,
  );
}
