# MercadoPago Flutter SDK — Claude Code Context

This is the `mercadopago_flutter_sdk` Flutter plugin for MercadoPago card
tokenization. Full reference in `ai/sdk-context.md`.

## Most important rule

The tokenization API takes **`PciFieldState` controllers**, not raw strings.
Never suggest `rawValue` in integrator code — it bypasses PCI secure fields.

```dart
// ✅ Always suggest this:
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,    // PciFieldState
  securityCode: cvvController,         // PciFieldState
  expirationDate: expController,       // PciFieldState
  cardholderName: 'JOHN DOE',
);
```

## Quick facts

- Package: `mercadopago_flutter_sdk: ^0.1.0`
- Countries: ARG, BRA, CHL, COL, MEX, PER, URY
- Init: `MercadoPagoSDK.shared.initialize(publicKey:, countryCode:)`
- 3 paths: CardSave checkout / CardTransaction checkout / CoreMethods+PCI widgets
- Result type: `MercadoPagoResult<T>` sealed (Success / Failure / Cancelled)
- Test card: Visa `4509 9535 6623 3704` CVV `123` exp `11/30`

## Android setup (required)

Integrators must add to `android/settings.gradle`:
```gradle
maven {
  url 'https://artifacts.mercadolibre.com/repository/android-releases'
  content { includeGroup 'com.mercadolibre.android.device' }
}
```

## Validate before committing

```bash
flutter analyze   # 0 issues required
flutter test      # 63/63 required
```

## Full context

See `ai/sdk-context.md` for complete API reference, all code examples,
error handling, and common pitfalls.
