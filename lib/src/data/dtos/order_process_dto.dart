import '../../domain/models/order_process_result.dart';
import '../../domain/repositories.dart';

/// Serializes an [OrderProcessParams] to the `/orders/{id}/process` request body
/// and parses the response into an [OrderProcessResult].
///
/// The wire contract matches the native SDKs: `amount` as a 2-decimal string and
/// `payment_method_type` carrying the `paymentTypeId` value.
abstract final class OrderProcessDto {
  static Map<String, dynamic> toRequestBody(OrderProcessParams params) => {
        'payment_method_id': params.paymentMethodId,
        'payment_method_type': params.paymentTypeId,
        'token': params.token,
        'installments': params.installments,
        'amount': params.amount.toStringAsFixed(2),
      };

  static OrderProcessResult parse(Map<String, dynamic> json) =>
      OrderProcessResult(
        id: (json['id'] ?? '').toString(),
        status: (json['status'] as String?) ?? '',
      );
}
