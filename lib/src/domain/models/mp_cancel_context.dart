/// Identifies the screen the user was on when they cancelled a checkout flow.
enum CheckoutStep {
  cardForm,
  installmentSelection,
  review,
  initialization,
}

/// Context attached to a [Cancelled] result, useful for analytics and for
/// resuming the user from where they left off.
class MPCancelContext {
  const MPCancelContext({required this.step, this.reason});

  final CheckoutStep step;
  final String? reason;
}
