import '../domain/errors.dart';
import 'mp_payment_data.dart';
import 'mp_user_cancelled_context.dart';

/// Result delivered to the hosted-checkout `onResult` callback.
///
/// Sealed hierarchy mirroring the native `MercadoPagoCheckoutResult`
/// (`Success` / `Error` / `UserCancelled`). `CheckoutError` is named with a
/// `Checkout` prefix to avoid clashing with `dart:core`'s `Error`.
///
/// ```dart
/// switch (result) {
///   case CheckoutSuccess(:final data):        // use data
///   case CheckoutError(:final error):         // show error
///   case CheckoutUserCancelled(:final context): // user dropped off
/// }
/// ```
sealed class MercadoPagoCheckoutResult<T extends MPPaymentData> {
  const MercadoPagoCheckoutResult();
}

final class CheckoutSuccess<T extends MPPaymentData>
    extends MercadoPagoCheckoutResult<T> {
  const CheckoutSuccess(this.data);
  final T data;
}

final class CheckoutError<T extends MPPaymentData>
    extends MercadoPagoCheckoutResult<T> {
  const CheckoutError(this.error);
  final MercadoPagoError error;
}

final class CheckoutUserCancelled<T extends MPPaymentData>
    extends MercadoPagoCheckoutResult<T> {
  const CheckoutUserCancelled(this.context);
  final MPUserCancelledContext context;
}
