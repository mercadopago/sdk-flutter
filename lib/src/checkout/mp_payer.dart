/// Typed payer model, mirroring the native Android/iOS `MPPayer`.
///
/// Reserved for parity with the native SDKs: like them, it is a public model
/// that is **not** wired into the checkout builder (for card transactions the
/// payer is resolved server-side from the order). It exists so integrator code
/// and future payer-related APIs can use a typed model instead of a bare
/// `String` email.
class MPPayer {
  const MPPayer({required this.email});

  /// The payer's email address.
  final String email;
}
