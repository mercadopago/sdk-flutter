# MercadoPago Flutter SDK — AI Agents Context

Full reference: `ai/sdk-context.md`

## What this is

`mercadopago` — Flutter plugin for MercadoPago card tokenization.
Architecture: Clean Architecture, Dart layer (pure) + native Android device
fingerprinting and an empty iOS compatibility channel. No third-party state
management or DI frameworks.
Installation: `flutter pub add mercadopago` (hosted on pub.dev), as shown in
`README.md`.

## Before making changes

```bash
./tool/verify.sh
```
Do not commit if any check fails. GitHub Actions are unavailable under the
organization's security policy, so this local gate is mandatory: it analyzes
the package and example, runs the full test suite, enforces 80% coverage
independently for `domain`, `core_methods`, and `pci`, validates the pub.dev
archive, and builds native targets supported by the host. Android and iOS build
evidence from correctly provisioned hosts is required before merge;
`--without-native` is for iteration only.

## Core Methods processing mode

`getPaymentMethods` and `getInstallments` both default to
`ProcessingMode.aggregator`. Gateway integrations must pass the same explicit
`ProcessingMode.gateway` value to both calls. Public models preserve native
response metadata and agreements; do not project gateway responses back into a
reduced aggregator-only model.

## Security rule: PCI secure fields (most important)

Tokenization takes PciFieldState controllers — never raw strings.

No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.

Widgets clear retained values on removal and app pause/detach. Successful new-
and saved-card tokenization clears supplied controllers. `dispose()` remains
required. Describe this as logical clearing, never byte-level memory
zeroization.

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

## Integration path

```dart
// Custom UI — app builds the form with PCI widgets
final cardNumber = PciFieldState(); // dispose in dispose()
// render CardNumberField(controller: cardNumber), ...
await sdk.coreMethods.createTokenForNewCard(cardNumber: cardNumber, ...);
```

## Result handling

```dart
switch (result) {
  case Success(:final data):   // send data.token to backend
  case Failure(:final error):  // show error to user
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

Android DeviceSDK provides native fraud signals and can fall back gracefully.
The iOS compatibility channel deliberately returns an empty device payload and
does not bundle a fingerprint framework. A missing Platform Channel also
produces an empty device payload. Keep iOS empty until the native owner
publishes an approved, versioned artifact with licensing, privacy-manifest,
signing, and provenance evidence. Never invent fallback identifiers or copy an
unreviewed binary. Describe Android's native signal set as dependency-dependent;
do not enumerate supposedly excluded data categories.

Native privacy release review is mandatory:

- iOS: verify the final application archive and privacy report. This plugin
  does not collect native fingerprint signals on iOS.
- Android: DeviceSDK contributes `com.google.android.gms.permission.AD_ID` to
  the merged manifest. The plugin requests no optional runtime permission, but
  the host owns Play Data Safety, advertising-ID, consent, and privacy
  disclosures.

## HTTP product ID contract

`CVQP49FTT60D1548Q56G` is the assigned product ID. Card-token POSTs send it in
`X-Product-id`; applicable CoreMethods GETs use the `product_id` query
parameter; identification-type GETs omit it.

## Test cards (Argentina)

Visa: `4509 9535 6623 3704` · CVV `123` · exp `11/30` · BIN-8 `45099535`

## Never generate

- `NewCardData(cardNumber: rawString)` — removed from public API
- imports of `lib/src/` helpers to read PCI values in integrator code
- `pluginClass: none` in pubspec.yaml — invalid Flutter syntax
- Riverpod/Bloc imports in SDK code

## Commit rules

No AI co-author lines. No AI mentions in commit messages. Do not assume a
feature branch name; use the branch already selected for the task.
