# MercadoPago Flutter SDK — Claude Code Context

This file is auto-loaded by Claude Code. It gives you full context to work
in this repository without additional prompting.

---

## What this project is

`mercadopago` is the official Flutter plugin for MercadoPago card
tokenization. Integrators use it to accept card payments across 7 Latin
American markets without requiring raw card data on their application
servers.

**Business goal**: Let Flutter developers accept MercadoPago payments with a
PCI-oriented capture flow and without needing to understand the tokenization
API directly. Integrators remain responsible for their complete PCI DSS scope
and assessment.

**Technical goal**: A Flutter plugin that wraps the card tokenization API,
provides PCI-oriented input widgets, and exposes a typed, idiomatic Dart result
type while letting applications pass field controllers instead of copying
sensitive values into strings.

---

## Architecture

### Layers (Clean Architecture)

```
lib/src/
├── core/           Infrastructure: HTTP client, session UUID, SDK singleton,
│                   configuration, errors, Luhn validation
├── domain/         Business contracts: sealed Result type, domain models,
│                   repository interfaces, error hierarchy
├── data/           API integration: DTOs (JSON↔domain), repository impls
├── core_methods/   Public low-level API: CoreMethods class, tokenization
├── pci/            Single library holding ALL card-value code: field
│                   state, the 3 input widgets, validation, tokenization
├── fingerprint/    Platform Channel → Android DeviceSDK / empty iOS fallback
└── analytics/      Fire-and-forget event tracking
```

### Public surface (lib/mercadopago.dart)

Only what is exported from the barrel is the public API. Everything under
`lib/src/` is implementation detail. The key exports are:

- `MercadoPagoSDK` — singleton entry point
- `CoreMethods` — low-level API (tokenization, payment methods, etc.)
- `PciFieldState`, `CardNumberField`, `SecurityCodeField`, `ExpirationDateField`
- `MercadoPagoResult<T>` sealed + `Success`, `Failure`
- Domain models: `CardToken`, `PaymentMethod`, `Installment`, `Issuer`, etc.

### Dependency injection

Manual, no frameworks. `MercadoPagoSDK._bootstrap()` constructs the entire
graph. This is intentional — the SDK must not force state management
libraries on integrators.

---

## The PCI secure fields rule — most important design decision

**Problem**: If integrator code reads raw card numbers, it might log, persist,
or send them to an application server and expand its PCI DSS scope.

**Solution**: `createTokenForNewCard` takes `PciFieldState` controllers. The
supported integration passes controllers directly to `CoreMethods`, which
reads their values and sends them to the MercadoPago API. The application uses
the opaque token returned by the SDK.

```dart
// ✅ Correct — the only acceptable pattern
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,     // PciFieldState
  expirationDate: expirationController, // PciFieldState (MMYY)
  securityCode: cvvController,          // PciFieldState
  identification: BuyerIdentification(name: 'JOHN DOE'), // + optional number/type
);

// ❌ Wrong — removed from public API intentionally
createTokenForNewCard(NewCardData(cardNumber: rawString, ...))

// ❌ Wrong — never import lib/src helpers to extract a raw string
```

No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.

Widgets clear their values on removal and app pause/detach. Successful new- or
saved-card tokenization clears supplied controllers; validation/network
failures retain values for correction or retry. `dispose()` remains required.
Never describe logical clearing as byte-level memory zeroization.

---

## Result type — always handle both cases

`MercadoPagoResult<T>` is a sealed class. Both cases must be handled.

```dart
switch (result) {
  case Success(:final data): // use data
  case Failure(:final error): // show error to user
}
```

Common `MercadoPagoError` variants:
- `InvalidCardNumberError` — Luhn check failed
- `InvalidCvvError` — length differs from the payment method requirement
- `CardExpiredError` / `InvalidExpirationDateError`
- `NetworkError(statusCode, isRetriable, message, location)`
- `BinIsEmptyError` — call `getPaymentMethods` without a BIN
- `ValidationError(field, message)`

---

## Integration with CoreMethods and PCI widgets

### Card tokenization
```dart
// App builds its own form and passes PCI controllers without reading them.
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: _cardNumberCtrl,   // PciFieldState from CardNumberField
  expirationDate: _expCtrl,      // PciFieldState from ExpirationDateField (MMYY)
  securityCode: _cvvCtrl,        // PciFieldState from SecurityCodeField
  identification: BuyerIdentification(name: _nameCtrl.text.trim()),
);
```

### Other CoreMethods (BIN lookup, installments, etc.)
```dart
// BINs must be 8 digits, matching the native SDK contract.
await sdk.getPaymentMethods(bin: '45099535');
await sdk.getInstallments(bin: '45099535', amount: 1500.0);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes();
```

---

## Typed public models

The public API mirrors the native Android/iOS SDKs using typed models instead
of loose primitives:

- `BuyerIdentification(name, number?, type?)` — cardholder identity for
  `createTokenForNewCard` (name lives inside it, matching Android).

**Monetary type (`double`, deliberate):** amounts use `double`, not a decimal
type. After the order-driven change, integrator-facing money only appears in
`getInstallments(amount:)`, where it is a pass-through (serialized to a string
for the query, no arithmetic) — so `double` is safe for LATAM amounts and stays
idiomatic. The native SDKs use `BigDecimal`/`Decimal`; we intentionally do not
add a decimal dependency.

---

## Android integration requirement

Every app using this SDK must add the MercadoLibre Artifactory to
`android/settings.gradle` (or `build.gradle` legacy):

```gradle
maven {
    url 'https://artifacts.mercadolibre.com/repository/android-releases'
    content { includeGroup 'com.mercadolibre.android.device' }
}
```

Without this, the device-fingerprint dependency (`com.mercadolibre.android.device:sdk:4.0.1`)
won't resolve and the Android build fails.

DeviceSDK contributes `com.google.android.gms.permission.AD_ID` to the merged
manifest. The plugin does not request optional runtime permissions; the host
still owns Play Data Safety, advertising-ID, consent, and privacy disclosures.

---

## Native platform channels

The fingerprint Platform Channel runs on Android/iOS only.
`FingerprintService` handles `MissingPluginException` gracefully — tokenization
still works but without enriched fraud signals. Android collection failures
may return a minimal fallback. The iOS channel always returns an empty map and
does not collect fallback identifiers. Android's native signal set can evolve,
so do not claim it excludes particular data categories. Never add fingerprint
logic to the Dart layer.

The assigned product ID is `CVQP49FTT60D1548Q56G`. Card-token POSTs send it as
`X-Product-id`; applicable CoreMethods GETs send it as the `product_id` query
parameter; identification-type GETs omit it.

### iOS fingerprint state

The iOS plugin intentionally has no fingerprint framework. Its compatibility
channel returns an empty map so tokenization continues without enriched device
signals. Do not reintroduce a binary or identifier fallback without licensing,
privacy, and App Store required-reason review.

---

## Supported countries

ARG, BRA, CHL, COL, MEX, PER, URY

Only these 7. `Country.fromCode()` throws `SDKInvalidCountryError` for anything else.

---

## Testing

```bash
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test --coverage
dart pub publish --dry-run
```

Test files live in `test/` mirroring `lib/src/`. Fakes are in `test/_fakes/`.
When adding a new public behavior, add tests in the matching `test/` path.

CI runs the declared minimum Flutter `3.44.2`, requires 80% line coverage separately
for `domain` and `core_methods`, and builds the example for Android and iOS.

Fakes implement repository interfaces directly.

---

## Commit rules

- No AI co-author lines (`Co-Authored-By: Claude...`)
- No AI mentions in commit messages
- Do not assume a feature branch name; work on the branch selected for the task

---

## Running the example

```bash
cd example
# Set your key in lib/main.dart: APP_USR-{uuid}
flutter run -d <device>
```

The example needs the MercadoLibre Artifactory in `example/android/build.gradle.kts`
(already configured in this repo).

---

## Test cards (Argentina / ARG)

| Brand | Number | CVV | Expiry | BIN-8 |
|-------|--------|-----|--------|-------|
| Visa | 4509 9535 6623 3704 | 123 | 11/30 | 45099535 |
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | 503175 |

Cardholder name: `APRO` (triggers approved response)

---

## Common mistakes to avoid

| Mistake | Correct approach |
|---------|-----------------|
| `NewCardData(cardNumber: string)` | Pass `PciFieldState` to `createTokenForNewCard` |
| Importing `lib/src/` helpers in app code | No — pass the controller directly |
| Passing a BIN that is not 8 digits | Use the first 8 digits |
| Missing Artifactory in Android build | Add `maven { url 'artifacts.mercadolibre.com/...' }` |
| `pluginClass: none` in pubspec.yaml | Invalid Flutter syntax — omit unsupported platforms |
| Storing the token on device | Treat the token as single-use and short-lived; send it to the backend immediately and do not persist it |

---

## What is NOT done yet (v0.1.0 known gaps)

- Integration tests against real MercadoPago API
- Federated plugin architecture (deferred to post v1.0)
- Automatic network retry
- Publication to pub.dev (the archive is validated with `--dry-run` in CI)
- Enriched iOS device fingerprinting (deliberately disabled for this release)
