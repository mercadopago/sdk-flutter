# MercadoPago Flutter SDK — Claude Code Context

This file is auto-loaded by Claude Code. It gives you full context to work
in this repository without additional prompting.

---

## What this project is

`mercadopago_flutter_sdk` is the official Flutter plugin for MercadoPago card
tokenization. Integrators use it to accept card payments across 7 Latin
American markets without handling raw card data on their servers.

**Business goal**: Let any Flutter developer accept MercadoPago payments in
their app in < 30 minutes, with full PCI compliance, without needing to
understand the MercadoPago API directly.

**Technical goal**: A Flutter plugin that wraps the card tokenization API,
provides PCI-compliant input widgets, and exposes a typed, idiomatic Dart
result type — while keeping raw card data exclusively inside the SDK.

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
├── components/     PCI-compliant Flutter widgets: CardNumberField, etc.
├── checkout/       Hosted checkout UI: 3 screens + controller + builder
├── fingerprint/    Platform Channel → native device SDK (iOS/Android)
└── analytics/      Fire-and-forget event tracking
```

### Public surface (lib/mercadopago_flutter_sdk.dart)

Only what is exported from the barrel is the public API. Everything under
`lib/src/` is implementation detail. The key exports are:

- `MercadoPagoSDK` — singleton entry point
- `CoreMethods` — low-level API (tokenization, payment methods, etc.)
- `MercadoPagoCheckout` — hosted checkout builder
- `PciFieldState`, `CardNumberField`, `SecurityCodeField`, `ExpirationDateField`
- `MercadoPagoResult<T>` sealed + `Success`, `Failure`, `Cancelled`
- Domain models: `CardToken`, `PaymentMethod`, `Installment`, `Issuer`, etc.

### Dependency injection

Manual, no frameworks. `MercadoPagoSDK._bootstrap()` constructs the entire
graph. This is intentional — the SDK must not force state management
libraries on integrators.

---

## The PCI secure fields rule — most important design decision

**Problem**: If integrators can access raw card numbers, they might log them,
store them, or send them to their own servers — a PCI DSS violation.

**Solution**: `createTokenForNewCard` takes `PciFieldState` controllers.
The raw values are read exclusively inside `CoreMethods` and sent directly
to the MercadoPago API. The integrator only ever receives the opaque token.

```dart
// ✅ Correct — the only acceptable pattern
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,     // PciFieldState
  securityCode: cvvController,          // PciFieldState
  expirationDate: expirationController, // PciFieldState (MMYY)
  cardholderName: 'JOHN DOE',
);

// ❌ Wrong — removed from public API intentionally
createTokenForNewCard(NewCardData(cardNumber: rawString, ...))

// ❌ Wrong — never read rawValue for tokenization
final raw = controller.rawValue; // bypasses PCI secure fields
```

`PciFieldState.rawValue` still exists (Dart has no package-private) but is
not needed in any public-API usage. If you find yourself suggesting
`rawValue`, you are bypassing the security model.

---

## Result type — always handle all three cases

`MercadoPagoResult<T>` is a sealed class. All three cases must be handled.
CoreMethods never emits `Cancelled` — that's only for checkout flows.

```dart
switch (result) {
  case Success(:final data): // use data
  case Failure(:final error): // show error to user
  case Cancelled(:final context): // user closed checkout UI
}
```

Common `MercadoPagoError` variants:
- `InvalidCardNumberError` — Luhn check failed
- `InvalidCvvError` — length not 3–4 digits
- `CardExpiredError` / `InvalidExpirationDateError`
- `NetworkError(statusCode, isRetriable, message, location)`
- `BinIsEmptyError` — call `getPaymentMethods` without a BIN
- `ValidationError(field, message)`

---

## Three integration paths

### 1. Hosted checkout — recommended for most use cases
```dart
// SDK owns the full UI; integrator only handles the result.
MercadoPagoCheckout.forCardSave(onResult: (r) { ... }).build()
MercadoPagoCheckout.forCardTransaction(
  amount: 1500.0, payerEmail: 'user@example.com',
  onResult: (r) { ... },
).build()
```

### 2. CoreMethods with custom UI — when app design requires it
```dart
// App builds its own form using PCI widgets.
// Raw card data stays inside the SDK throughout.
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: _cardNumberCtrl,   // PciFieldState from CardNumberField
  securityCode: _cvvCtrl,        // PciFieldState from SecurityCodeField
  expirationDate: _expCtrl,      // PciFieldState from ExpirationDateField (MMYY)
  cardholderName: _nameCtrl.text.trim(),
);
```

### 3. Other CoreMethods (BIN lookup, installments, etc.)
```dart
// BINs must be 8 digits (not 6 — the API indexes by BIN-8)
await sdk.getPaymentMethods(bin: '45099535');
await sdk.getInstallments(bin: '45099535', amount: 1500.0);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes();
```

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

---

## Native platform channels

The fingerprint Platform Channel runs on Android/iOS only.
`FingerprintService` handles `MissingPluginException` gracefully — tokenization
still works but without enriched fraud signals. Never add fingerprint logic
to the Dart layer.

---

## Supported countries

ARG, BRA, CHL, COL, MEX, PER, URY

Only these 7. `Country.fromCode()` throws `SDKInvalidCountryError` for anything else.

---

## Testing

```bash
flutter analyze   # must be 0 issues before any commit
flutter test      # 63 tests — all must pass
```

Test files live in `test/` mirroring `lib/src/`. Fakes are in `test/_fakes/`.
When adding a new public behavior, add tests in the matching `test/` path.

Tests use `mocktail` (no code generation). Fakes implement repository
interfaces directly.

---

## Commit rules

- No AI co-author lines (`Co-Authored-By: Claude...`)
- No AI mentions in commit messages
- Feature branch: `feature/001-mercadopago-flutter-sdk` → merges to `main`

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
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | 50317557 |

Cardholder name: `APRO` (triggers approved response)

---

## Common mistakes to avoid

| Mistake | Correct approach |
|---------|-----------------|
| `NewCardData(cardNumber: string)` | Pass `PciFieldState` to `createTokenForNewCard` |
| `field.rawValue` in app code | No — pass the controller directly |
| 6-digit BIN to `getPaymentMethods` | Use 8-digit BIN |
| Missing Artifactory in Android build | Add `maven { url 'artifacts.mercadolibre.com/...' }` |
| `pluginClass: none` in pubspec.yaml | Invalid Flutter syntax — omit unsupported platforms |
| Storing the token on device | Token expires in 15 min — send to backend immediately |

---

## What is NOT done yet (v0.1.0 known gaps)

- Widget tests for `CardFormScreen`, `InstallmentScreen`, `ReviewScreen`
- Integration tests against real MercadoPago API
- Federated plugin architecture (deferred to post v1.0)
- `X-Product-id` is shared with the iOS SDK — a Flutter-specific ID is pending
