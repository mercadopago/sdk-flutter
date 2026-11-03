# OpenAI Codex / ChatGPT Agents — MercadoPago Flutter SDK

Full reference: `ai/sdk-context.md`

## Project overview

Flutter plugin for MercadoPago card tokenization. Integrators pass
`PciFieldState` controllers directly instead of copying sensitive values into
strings, then receive an opaque token. Install from pub.dev with
`flutter pub add mercadopago_sdk_flutter`.

Architecture:
- `lib/src/core/` — HTTP, session, config, errors
- `lib/src/domain/` — sealed Result<T>, models, repository interfaces
- `lib/src/data/` — DTOs, repository implementations
- `lib/src/core_methods/` — public low-level tokenization API
- `lib/src/pci/` — single library: field state, PCI widgets, tokenization
- `lib/mercadopago_sdk_flutter.dart` — public barrel (only export from here)

## Critical rule: PCI secure fields

The tokenization API takes `PciFieldState` controllers, never raw strings.
`NewCardData` was intentionally removed from the public API.
No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.
accidental access but is not absolute technical isolation or PCI DSS
certification.

```dart
// Always generate this pattern
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,      // PciFieldState
  expirationDate: expirationController,  // PciFieldState (MMYY from ExpirationDateField)
  securityCode: cvvController,           // PciFieldState
  identification: BuyerIdentification(
    name: 'JOHN DOE',
    type: 'DNI',        // optional
    number: '12345678', // optional
  ),
);
```

## Integration patterns

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
  case Success(:final data):   // data.token → backend
  case Failure(:final error):  // show error
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
- `InvalidCvvError` — length differs from the payment-method requirement
- `CardExpiredError` — past expiry
- `NetworkError(isRetriable: bool, message: String)`
- `BinIsEmptyError` — empty BIN in getPaymentMethods

## Test cards
Visa: `4509 9535 6623 3704` / CVV `123` / exp `11/30` / BIN-8 `45099535`

## Native and HTTP contract

- Android resolves DeviceSDK `4.0.1` from the MercadoLibre Artifactory. The iOS
  channel returns an empty map and bundles no fingerprint framework.
- Android fingerprint fields are native-dependency dependent. Missing channels
  and the iOS fallback degrade to an empty payload; do not invent iOS fallback
  identifiers.
- Android DeviceSDK contributes `com.google.android.gms.permission.AD_ID`;
  host apps own Play Data Safety, advertising-ID, consent, and privacy
  disclosures. The plugin itself requests no optional runtime permissions.
- The assigned product ID is `CVQP49FTT60D1548Q56G`: POST tokenization uses
  `X-Product-id`, applicable GETs use `product_id`, and identification types
  omit it.

## Do NOT generate
- `NewCardData(cardNumber: rawString)` — removed from API
- imports of `lib/src/` helpers to read PCI values in user-facing code
- `pluginClass: none` in pubspec.yaml
- Riverpod/Bloc dependencies in SDK layer
- BIN values that are not exactly 8 digits in CoreMethods calls
