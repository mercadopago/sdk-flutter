/// A MercadoPago order that a card transaction is bound to.
///
/// Both fields are required and travel together: [orderId] identifies the
/// server-side order and [clientToken] authorizes the SDK's calls against it
/// (sent as an `Authorization: Bearer` token). The transaction **amount is not
/// passed by the integrator** — it is resolved server-side from the order, so
/// there is a single source of truth. This mirrors the native Android
/// (`MPOrder`) and iOS (`MPOrder`) SDKs.
///
/// Create the order from your backend via the MercadoPago Orders API, then hand
/// its `id` and client token to [MercadoPagoCheckout.forCardTransaction].
class MPOrder {
  const MPOrder({required this.orderId, required this.clientToken});

  /// The id returned by the Orders API when the order was created.
  final String orderId;

  /// The short-lived client token returned by the Orders API, used to
  /// authorize the checkout's calls against the order.
  final String clientToken;
}
