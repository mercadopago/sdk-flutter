/// Errors that can be raised during SDK lifecycle operations (init/teardown).
///
/// These are distinct from [MercadoPagoError] (which represents runtime
/// failures while interacting with the API). [SDKError] is thrown — never
/// wrapped in [MercadoPagoResult] — because misuse of the SDK lifecycle is a
/// programmer error, not a recoverable runtime condition.
sealed class SDKError implements Exception {
  const SDKError(this.message);

  final String message;

  @override
  String toString() => 'SDKError: $message';
}

/// Thrown when an SDK operation is called before [MercadoPagoSDK.initialize].
final class SDKNotInitializedError extends SDKError {
  const SDKNotInitializedError()
      : super(
          'MercadoPagoSDK.initialize() must be called before any other '
          'SDK operation.',
        );
}

/// Thrown when [MercadoPagoSDK.initialize] is called more than once without
/// calling [MercadoPagoSDK.setNewConfiguration] in between.
final class SDKAlreadyInitializedError extends SDKError {
  const SDKAlreadyInitializedError()
      : super(
          'MercadoPagoSDK is already initialized. Call setNewConfiguration() '
          'to change credentials.',
        );
}

/// Thrown when the public key does not match the expected `APP_USR-*` format.
final class SDKInvalidPublicKeyError extends SDKError {
  const SDKInvalidPublicKeyError()
      : super(
          'Invalid public key. Expected format: APP_USR-{uuid}.',
        );
}

/// Thrown when the supplied country code is not one of the supported countries.
final class SDKInvalidCountryError extends SDKError {
  const SDKInvalidCountryError(String code)
      : super('Unsupported country code: $code.');
}
