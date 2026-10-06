# Claude Code — MercadoPago Flutter SDK

> Full SDK reference: see `ai/sdk-context.md`

## Working in this repo

- Package name: `mercadopago`
- The SDK is a Flutter plugin (native Android fingerprinting, an empty iOS
  compatibility channel, and pure Dart for everything else)
- Work on the branch selected for the task; do not assume a branch name
- No co-authors, no AI mentions in commit messages

## Key architecture rule: secure fields

The tokenization API takes `PciFieldState` controllers, **never raw strings**.
No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.

The iOS channel deliberately returns an empty device payload and bundles no
fingerprint framework. Android DeviceSDK contributes `AD_ID`, so hosts own Play
Data Safety and advertising-ID disclosures.

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
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test --coverage
dart pub publish --dry-run
```

## Running the example

```bash
cd example
flutter run -d <device> \
  --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-...
```
