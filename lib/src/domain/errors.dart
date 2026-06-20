/// Where in the SDK flow an error originated. Useful for analytics and for
/// driving recovery UI.
enum ErrorLocation {
  initialization,
  tokenization,
  paymentMethods,
  installments,
  issuer,
  identification,
  binChange,
  unknown,
}

/// Runtime errors surfaced to SDK consumers. Always wrapped in
/// [MercadoPagoResult.failure], never thrown.
sealed class MercadoPagoError {
  const MercadoPagoError({this.location = ErrorLocation.unknown});

  final ErrorLocation location;
}

/// Failure communicating with the MercadoPago API.
class NetworkError extends MercadoPagoError {
  const NetworkError({
    required this.message,
    required this.isRetriable,
    this.statusCode,
    super.location,
  });

  final String message;
  final int? statusCode;
  final bool isRetriable;

  @override
  String toString() =>
      'NetworkError(status: $statusCode, retriable: $isRetriable, '
      'location: $location, message: $message)';
}

/// Local validation failed (e.g. empty BIN, malformed input).
class ValidationError extends MercadoPagoError {
  const ValidationError({
    required this.field,
    required this.message,
    super.location,
  });

  final String field;
  final String message;

  @override
  String toString() =>
      'ValidationError(field: $field, message: $message, location: $location)';
}

class InvalidCardNumberError extends MercadoPagoError {
  const InvalidCardNumberError({super.location = ErrorLocation.tokenization});

  @override
  String toString() => 'InvalidCardNumberError(location: $location)';
}

class InvalidCvvError extends MercadoPagoError {
  const InvalidCvvError({super.location = ErrorLocation.tokenization});

  @override
  String toString() => 'InvalidCvvError(location: $location)';
}

class InvalidExpirationDateError extends MercadoPagoError {
  const InvalidExpirationDateError({
    super.location = ErrorLocation.tokenization,
  });

  @override
  String toString() => 'InvalidExpirationDateError(location: $location)';
}

class CardExpiredError extends MercadoPagoError {
  const CardExpiredError({super.location = ErrorLocation.tokenization});

  @override
  String toString() => 'CardExpiredError(location: $location)';
}

class BinIsEmptyError extends MercadoPagoError {
  const BinIsEmptyError({super.location = ErrorLocation.binChange});

  @override
  String toString() => 'BinIsEmptyError(location: $location)';
}

class InitializationFailedError extends MercadoPagoError {
  const InitializationFailedError({
    required this.reason,
    super.location = ErrorLocation.initialization,
  });

  final String reason;

  @override
  String toString() =>
      'InitializationFailedError(reason: $reason, location: $location)';
}

class UnknownError extends MercadoPagoError {
  const UnknownError({required this.message, super.location});

  final String message;

  @override
  String toString() =>
      'UnknownError(message: $message, location: $location)';
}

/// Errors specific to PCI text fields. These are surfaced to the field's
/// `onError` callback rather than wrapped in [MercadoPagoResult].
sealed class CardFieldError {
  const CardFieldError();
}

enum CardNumberFieldError implements CardFieldError {
  empty,
  invalidCharacters,
  invalidLength,
  invalidLuhn;

  @override
  String toString() => 'CardNumberFieldError.$name';
}

enum SecurityCodeFieldError implements CardFieldError {
  empty,
  invalidCharacters,
  invalidLength;

  @override
  String toString() => 'SecurityCodeFieldError.$name';
}

enum ExpirationDateFieldError implements CardFieldError {
  empty,
  invalidFormat,
  invalidMonth,
  expired;

  @override
  String toString() => 'ExpirationDateFieldError.$name';
}
