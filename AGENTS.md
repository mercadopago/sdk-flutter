# MercadoPago Flutter SDK — AI Agents Context

Full reference: `ai/sdk-context.md`

## What this is

`mercadopago_flutter_sdk` — Flutter plugin for MercadoPago card tokenization.
Architecture: Clean Architecture, Dart layer (pure) + native Android/iOS for
device fingerprinting. No third-party state management or DI frameworks.
Package: `mercadopago_flutter_sdk: ^0.1.0`

## Before making changes

```bash
flutter analyze   # must be 0 issues
flutter test      # 112 tests, all must pass
```
Do not commit if either fails.

## Security rule: PCI secure fields (most important)

Tokenization takes PciFieldState controllers — never raw strings.

```dart
// Correct
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,     // PciFieldState
  expirationDate: expirationController, // PciFieldState
  securityCode: cvvController,          // PciFieldState
  identification: BuyerIdentification(name: 'JOHN DOE'),
);
// Wrong — NewCardData removed from public API
// createTokenForNewCard(NewCardData(cardNumber: rawString, ...))
```

## Integration paths

```dart
// Hosted checkout — SDK owns the UI. One builder + MPCheckoutType + .show(context).
MercadoPagoCheckout(MPCheckoutType.cardSave()).show(context, onResult: (r) { ... });
// Card transaction: order-bound; SDK processes the payment, returns orderStatus.
MercadoPagoCheckout(MPCheckoutType.cardTransaction(MPOrder(orderId: '...', clientToken: '...')))
    .show(context, onResult: (r) { ... });
// result: CheckoutSuccess / CheckoutError / CheckoutUserCancelled

// Custom UI — app builds the form with PCI widgets
final cardNumber = PciFieldState(); // dispose in dispose()
// render CardNumberField(controller: cardNumber), ...
await sdk.coreMethods.createTokenForNewCard(cardNumber: cardNumber, ...);
```

## Result handling

```dart
switch (result) {
  case Success(:final data):   // send data.token.token to backend
  case Failure(:final error):  // show error to user
  case Cancelled():             // user dismissed — reset state
}
```

## Initialization

```dart
MercadoPagoSDK.shared.initialize(
  publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  countryCode: 'ARG', // ARG | BRA | CHL | COL | MEX | PER | URY
);
```

## Android: required for integrators

```gradle
maven {
    url 'https://artifacts.mercadolibre.com/repository/android-releases'
    content { includeGroup 'com.mercadolibre.android.device' }
}
```

## Test cards (Argentina)

Visa: `4509 9535 6623 3704` · CVV `123` · exp `11/30` · BIN-8 `45099535`

## Never generate

- `NewCardData(cardNumber: rawString)` — removed from public API
- `field.rawValue` in integrator code
- `pluginClass: none` in pubspec.yaml — invalid Flutter syntax
- Riverpod/Bloc imports in SDK code

## Commit rules

No AI co-author lines. No AI mentions. Branch: `feature/001-mercadopago-flutter-sdk`
