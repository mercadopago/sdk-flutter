# OpenAI Codex / ChatGPT Agents — MercadoPago Flutter SDK

Full reference: `ai/sdk-context.md`

## Project overview

Flutter plugin for MercadoPago card tokenization. Raw card data stays inside
the SDK — integrators receive only an opaque token. Package:
`mercadopago_flutter_sdk: ^0.1.0`.

Architecture:
- `lib/src/core/` — HTTP, session, config, errors
- `lib/src/domain/` — sealed Result<T>, models, repository interfaces
- `lib/src/data/` — DTOs, repository implementations
- `lib/src/core_methods/` — public low-level tokenization API
- `lib/src/components/` — PCI input widgets
- `lib/src/checkout/` — hosted checkout flow
- `lib/mercadopago_flutter_sdk.dart` — public barrel (only export from here)

## Critical rule: PCI secure fields

The tokenization API takes `PciFieldState` controllers, never raw strings.
`NewCardData` was intentionally removed from the public API.

```dart
// Always generate this pattern
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,      // PciFieldState
  securityCode: cvvController,           // PciFieldState
  expirationDate: expirationController,  // PciFieldState (MMYY from ExpirationDateField)
  cardholderName: 'JOHN DOE',
  documentType: 'DNI',    // optional
  documentNumber: '12345678', // optional
);
```

## Integration patterns

### Hosted checkout
```dart
MercadoPagoCheckout.forCardSave(onResult: (r) { ... }).build()
MercadoPagoCheckout.forCardTransaction(amount: 1500.0, payerEmail: '...', onResult: (r) { ... }).build()
```

### Custom UI (PCI widgets)
```dart
// Setup
final cardNumber = PciFieldState();
// dispose() in StatefulWidget.dispose()

// Render
CardNumberField(controller: cardNumber),  // onBinChanged fires at 8 digits
SecurityCodeField(controller: securityCode),
ExpirationDateField(controller: expirationDate),

// Submit
final result = await sdk.coreMethods.createTokenForNewCard(cardNumber: cardNumber, ...);
```

### Result handling
```dart
switch (result) {
  case Success(:final data):   // data.token.token → backend
  case Failure(:final error):  // show error
  case Cancelled():             // reset state
}
```

## Setup

### Initialization
```dart
MercadoPagoSDK.shared.initialize(
  publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  countryCode: 'ARG', // ARG BRA CHL COL MEX PER URY
);
```

### Android (required by integrators)
```gradle
maven {
    url 'https://artifacts.mercadolibre.com/repository/android-releases'
    content { includeGroup 'com.mercadolibre.android.device' }
}
```

## Error types
- `InvalidCardNumberError` — Luhn failed
- `InvalidCvvError` — length not 3–4
- `CardExpiredError` — past expiry
- `NetworkError(isRetriable: bool, message: String)`
- `BinIsEmptyError` — empty BIN in getPaymentMethods

## Test cards
Visa: `4509 9535 6623 3704` / CVV `123` / exp `11/30` / BIN-8 `45099535`

## Do NOT generate
- `NewCardData(cardNumber: rawString)` — removed from API
- `field.rawValue` in any user-facing code
- `pluginClass: none` in pubspec.yaml
- Riverpod/Bloc dependencies in SDK layer
- 6-digit BINs (use 8 digits for all API calls)
