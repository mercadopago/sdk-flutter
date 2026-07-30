# Claude Code — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## Working in this repo

- Package name: `mercadopago_flutter_sdk`
- The SDK is a Flutter plugin (native Android + iOS for fingerprinting,
  pure Dart for everything else)
- Feature branch: `feature/001-mercadopago-flutter-sdk` → merges to `main`
- No co-authors, no AI mentions in commit messages

## Key architecture rule: secure fields

The tokenization API takes `PciFieldState` controllers, **never raw strings**.

```dart
// ✅ Correct
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,   // PciFieldState
  expirationDate: expController,      // PciFieldState (MMYY)
  securityCode: cvvController,        // PciFieldState
  identification: BuyerIdentification(name: 'JOHN DOE'), // + optional number/type
);

// ❌ Wrong — never suggest this pattern
await sdk.coreMethods.createTokenForNewCard(
  NewCardData(cardNumber: rawString, ...)
);
```

## Running tests

```bash
flutter analyze    # must be 0 issues
flutter test       # 105 tests
```

## Running the example

```bash
cd example
flutter run -d <device>
# Replace APP_USR-REPLACE-WITH-YOUR-KEY in lib/main.dart first
```
