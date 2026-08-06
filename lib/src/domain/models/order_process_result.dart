/// Outcome of processing an order (`POST /orders/{id}/process`).
///
/// The SDK reduces the large process response to the two fields the integrator
/// needs, matching the native SDKs (`OrderProcessOutput` / order status).
class OrderProcessResult {
  const OrderProcessResult({required this.id, required this.status});

  /// Processed order id.
  final String id;

  /// Order status (e.g. `"processed"`, `"pending"`).
  final String status;
}
