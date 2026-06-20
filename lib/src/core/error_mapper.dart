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
  return UnknownError(message: error.toString(), location: location);
}
