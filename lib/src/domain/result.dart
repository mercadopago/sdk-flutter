import 'errors.dart';
import 'models/mp_cancel_context.dart';

/// Discriminated union returned by every public SDK operation that can
/// succeed, fail, or be cancelled by the user.
///
/// Pattern matching with Dart 3's exhaustive `switch` is the idiomatic way to
/// consume a [MercadoPagoResult]:
///
/// ```dart
/// final result = await coreMethods.getPaymentMethods(bin: '423456');
/// switch (result) {
///   case Success(:final data):
///     print('Got ${data.length} methods');
///   case Failure(:final error):
///     print('Failed: $error');
///   case Cancelled():
///     // not produced by core methods, only by checkout flows
/// }
/// ```
sealed class MercadoPagoResult<T> {
  const MercadoPagoResult();
}

class Success<T> extends MercadoPagoResult<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends MercadoPagoResult<T> {
  const Failure(this.error);
  final MercadoPagoError error;
}

class Cancelled<T> extends MercadoPagoResult<T> {
  const Cancelled(this.context);
  final MPCancelContext context;
}
