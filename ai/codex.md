# OpenAI Codex / ChatGPT Agents — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## What this repo is

Flutter plugin for MercadoPago card tokenization. Package:
`mercadopago_flutter_sdk`. The SDK tokenizes cards via MercadoPago's API
and returns an opaque token — raw card data is never exposed to integrators.

## Critical rule when generating code

The tokenization API takes `PciFieldState` controllers, NOT Dart strings.
Never generate `NewCardData(cardNumber: someString)` — that class is
intentionally removed from the public API.

## Correct patterns to generate

### Initialize SDK
```dart
MercadoPagoSDK.shared.initialize(publicKey: 'APP_USR-...', countryCode: 'ARG');
```

### Tokenize with custom form
```dart
final cardNumber = PciFieldState();
// ... (attach to CardNumberField, SecurityCodeField, ExpirationDateField)
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumber,
  securityCode: cvvController,
  expirationDate: expController,
  cardholderName: 'JOHN DOE',
);
```

### Hosted checkout
```dart
MercadoPagoCheckout.forCardSave(onResult: (r) { ... }).build()
```

### Handle results
```dart
switch (result) {
  case Success(:final data): /* data.token.token → backend */
  case Failure(:final error): /* show error */
  case Cancelled(): /* dismissed */
}
```

## Do not suggest
- `NewCardData` with raw string fields
- `PciFieldState.rawValue` in integrator code
- State management libraries (Riverpod, Bloc) — the SDK has no external deps
- `pluginClass: none` in pubspec.yaml — it's invalid Flutter syntax
