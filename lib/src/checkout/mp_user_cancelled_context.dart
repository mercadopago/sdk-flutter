/// Context delivered when the user cancels a hosted-checkout flow.
///
/// Mirrors the native `MPUserCancelledContext`: it reports the per-field state
/// of the card form and, for card transactions, the ordered list of screens the
/// user visited — so integrators know exactly where the user dropped off.
sealed class MPUserCancelledContext {
  const MPUserCancelledContext();
}

/// Cancellation of a Card Save flow: only the card-form field states.
final class MPCardSaveCancelled extends MPUserCancelledContext {
  const MPCardSaveCancelled({required this.fields});

  final List<MPCancelledFieldState> fields;
}

/// Cancellation of a Card Transaction flow: field states + visited screens.
final class MPCardTransactionCancelled extends MPUserCancelledContext {
  const MPCardTransactionCancelled({
    required this.fields,
    required this.screens,
  });

  final List<MPCancelledFieldState> fields;
  final List<CheckoutScreen> screens;
}

/// Snapshot of a single card-form field at cancel time.
class MPCancelledFieldState {
  const MPCancelledFieldState({required this.field, required this.state});

  final CheckoutField field;
  final CancelFieldState state;
}

/// The card-form fields (mirrors the native `Field` enum).
enum CheckoutField { cardNumber, cardHolder, expirationDate, securityCode, document }

/// Validation state of a field at cancel time (mirrors the native `State`).
///
/// The native SDKs attach the offending brand/type to
/// `cardBrandNotAccepted`/`cardTypeNotAccepted`; this port keeps the state as a
/// flat enum (the payload is omitted).
enum CancelFieldState {
  valid,
  empty,
  incomplete,
  invalid,
  cardBrandNotAccepted,
  cardTypeNotAccepted,
}

/// Checkout screens the user can navigate (mirrors the native `Screen` enum).
enum CheckoutScreen { cardForm, installments, review }
