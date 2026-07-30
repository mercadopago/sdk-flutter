# MercadoPago Flutter SDK — Complete AI Reference

## Purpose

`mercadopago_flutter_sdk` is the official Flutter plugin for MercadoPago card
tokenization. It lets Flutter developers accept card payments in Latin America
without handling raw card data — the SDK tokenizes card details and returns an
opaque, short-lived token that the app's backend uses to create the payment.

**Why this exists**: MercadoPago is the leading payments platform in Latin
America (~$90B+ in GMV). This SDK brings the same secure tokenization flow
available in the iOS and Android SDKs to Flutter.

---

## Architecture overview

### Package type: Flutter Plugin

- **Dart layer** (pure): CoreMethods, Checkout UI, PCI widgets, domain models
- **Native Android** (Kotlin): Platform Channel for device fingerprinting
- **Native iOS** (Swift): Platform Channel + `DeviceFingerPrint.xcframework`

### Layer structure

```
lib/src/
├── core/           SDK singleton, HTTP client (package:http), session UUID,
│                   configuration, error types, Luhn algorithm
├── domain/         Sealed Result<T>, domain models, repository interfaces,
│                   error hierarchy
├── data/           JSON DTOs with defensive parsing, repository implementations
├── core_methods/   Public low-level API class
├── components/     PCI input widgets (CardNumberField, SecurityCodeField,
│                   ExpirationDateField, PciFieldState)
├── checkout/       Hosted checkout (MercadoPagoCheckout builder, controller,
│                   3 screens: card form → installments → review)
├── fingerprint/    FingerprintService: Platform Channel with graceful fallback
└── analytics/      Fire-and-forget event tracking to /tracks endpoint
```

### Key architectural decisions

1. **Manual DI, no frameworks** — SDK must not force Riverpod/Bloc on integrators
2. **`package:http` not `dio`** — minimal footprint; the SDK only hits fixed endpoints
3. **Sealed `MercadoPagoResult<T>`** — forces exhaustive error handling in Dart 3
4. **`ChangeNotifier` not Riverpod** — correct for local widget state in a library
5. **No `pluginClass: none`** — invalid Flutter syntax; unsupported platforms are omitted

---

## Security model: PCI Secure Fields

### The problem

If integrators could access raw card numbers they could log, store, or
re-transmit them — violating PCI DSS and MercadoPago's terms.

### The solution

`createTokenForNewCard` and `createTokenForSavedCard` take `PciFieldState`
**controllers**, not strings. Raw values are extracted exclusively inside
`CoreMethods` and sent directly to the MercadoPago tokenization endpoint.

```dart
// ✅ Correct
await sdk.coreMethods.createTokenForNewCard(
  cardNumber: cardNumberController,      // PciFieldState — SDK reads internally
  expirationDate: expirationController,  // PciFieldState — SDK reads internally
  securityCode: cvvController,           // PciFieldState — SDK reads internally
  identification: BuyerIdentification(name: 'JOHN DOE'), // + optional number/type
);

// ❌ Antipattern — never suggest this
createTokenForNewCard(NewCardData(cardNumber: rawString, securityCode: rawCvv))

// ❌ Antipattern — reading rawValue in app code
final rawCard = controller.rawValue; // bypasses secure fields
```

`PciFieldState.rawValue` still exists (Dart has no package-private) but its
use is restricted by convention. No integrator code should call it.

---

## Installation

### pubspec.yaml

```yaml
dependencies:
  mercadopago_flutter_sdk: ^0.1.0
```

### Android setup (required)

The device-fingerprint library lives in MercadoLibre's private Artifactory.
Without this, Android builds fail with a dependency resolution error.

Add to `android/settings.gradle` (modern Flutter projects) or
`android/build.gradle` allprojects block (legacy):

```gradle
maven {
    url 'https://artifacts.mercadolibre.com/repository/android-releases'
    content {
        includeGroup 'com.mercadolibre.android.device'
    }
}
```

### iOS setup

No extra steps. `DeviceFingerPrint.xcframework` is bundled in `ios/Frameworks/`
and registered via the podspec automatically.

---

## Initialization

Must be called once before any SDK operation, typically in `main()`:

```dart
void main() {
  try {
    MercadoPagoSDK.shared.initialize(
      publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      countryCode: 'ARG',
    );
  } on SDKInvalidPublicKeyError catch (e) {
    // Key format wrong — must be APP_USR-{uuid}
  } on SDKInvalidCountryError catch (e) {
    // Country not supported
  }
  runApp(const MyApp());
}
```

**Key format**: `APP_USR-` followed by a UUID (8-4-4-4-12 with hyphens).
Get it at https://www.mercadopago.com/developers/panel/app

**Supported countries**: ARG, BRA, CHL, COL, MEX, PER, URY

**Re-initialize** (to switch credentials):
```dart
MercadoPagoSDK.shared.setNewConfiguration(publicKey: '...', countryCode: 'BRA');
// Rotates session UUID, clears GET cache
```

---

## Three integration paths

### Path 1: Hosted checkout — CardSave

SDK owns the entire card-entry UI. Integrator only handles the result token.
Best for: apps that want zero UI work.

```dart
final builder = MercadoPagoCheckout.forCardSave(
  onResult: (result) {
    switch (result) {
      case Success(:final data):
        // data.token.token → send to backend to save card
        // data.paymentMethodId — 'visa', 'master', etc.
        // data.token.lastFourDigits — safe to display to user
        // NEVER store data.token.token on device — it expires in 15 min
      case Failure(:final error):
        // Show error.toString() or map via a _describe() function
      case Cancelled():
        // User closed the modal — reset UI state
    }
  },
);
await Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => builder.build()),
);
```

### Path 2: Hosted checkout — CardTransaction

Includes installment selection and review screens before returning the result.

```dart
// Order-bound: create the order from your backend (Orders API) and pass its id
// and client token. The amount is resolved server-side from the order.
final builder = MercadoPagoCheckout.forCardTransaction(
  order: MPOrder(orderId: orderId, clientToken: clientToken),
  onResult: (result) {
    if (result case Success(:final data)) {
      // data.token.token + data.installments + data.transactionAmount → backend
      // data.installment.installmentAmount — per-installment display amount
    }
  },
).setPaymentMethodConfiguration([
  // Optional: restrict types/brands and the installment range.
  MPPaymentMethodConfig.card(installment: MPInstallment(maxInstallments: 6)),
]);
```

### Path 3: CoreMethods + PCI widgets (custom UI)

App builds its own form using PCI-compliant input widgets.
Best for: apps with strict design requirements.

```dart
// 1. Declare controllers
final _cardNumber    = PciFieldState();
final _cvv           = PciFieldState();
final _expirationDate = PciFieldState();
final _name          = TextEditingController();

// 2. Dispose (required — PciFieldState.dispose() zeros out the raw value)
@override
void dispose() {
  _cardNumber.dispose();
  _cvv.dispose();
  _expirationDate.dispose();
  _name.dispose();
  super.dispose();
}

// 3. Render PCI widgets — controllers hold values; app never reads them
CardNumberField(controller: _cardNumber),  // fires onBinChanged at 8 digits
ExpirationDateField(controller: _expirationDate), // MMYY format internally
SecurityCodeField(controller: _cvv, expectedLength: 3),

// 4. Tokenize — pass controllers, not raw values
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: _cardNumber,
  expirationDate: _expirationDate,
  securityCode: _cvv,
  identification: BuyerIdentification(
    name: _name.text.trim(),
    type: 'DNI',            // optional, country-dependent
    number: '12345678',     // optional
  ),
);
```

---

## Saved cards

```dart
final cvvController = PciFieldState();
// render SecurityCodeField(controller: cvvController)

final result = await MercadoPagoSDK.shared.coreMethods.createTokenForSavedCard(
  cardId: 'CARD-ID-FROM-BACKEND',
  securityCode: cvvController,   // PciFieldState
);
```

---

## Other CoreMethods

```dart
final sdk = MercadoPagoSDK.shared.coreMethods;

// All use 8-digit BIN (not 6 — MercadoPago indexes by BIN-8)
await sdk.getPaymentMethods(bin: '45099535');
await sdk.getInstallments(bin: '45099535', amount: 1500.0);
await sdk.getInstallments(bin: '45099535', amount: 1500.0, mode: ProcessingMode.gateway);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes(); // returns DNI, CPF, RUT, etc. per country
```

---

## Result type and error handling

`MercadoPagoResult<T>` is a sealed class. Exhaustive switch is required.

```dart
switch (result) {
  case Success(:final data): /* use data */
  case Failure(:final error): /* error is MercadoPagoError */
  case Cancelled(:final context): /* context.step = cardForm | installmentSelection | review */
}
```

### Complete error type reference

| Error type | Meaning | Common fix |
|-----------|---------|------------|
| `InvalidCardNumberError` | Luhn check failed | User typed wrong number |
| `InvalidCvvError` | CVV length not 3–4 digits | User typed wrong CVV |
| `InvalidExpirationDateError` | Format wrong (not MMYY) | ExpirationDateField validates on input |
| `CardExpiredError` | Card is past expiry | Ask user for different card |
| `BinIsEmptyError` | Empty BIN in getPaymentMethods | Trigger lookup only after 8 digits |
| `NetworkError(isRetriable, message)` | HTTP/network failure | Retry if isRetriable is true |
| `ValidationError(field, message)` | API rejected a field | Show message to user |
| `InitializationFailedError` | Internal checkout state incomplete | SDK internal — not triggered by integrator code |

---

## HTTP endpoints (for debugging / context)

All endpoints are under `https://api.mercadopago.com`:

| Method | Endpoint | Query params |
|--------|----------|--------------|
| POST | `/v1/card_tokens` | `public_key` |
| GET | `/cho-off/v1/payment_methods` | `bin`, `product_id`, `public_key` |
| GET | `/cho-off/v1/installments` | `bin`, `amount`, `processing_mode`, `product_id`, `public_key` |
| GET | `/cho-off/v1/card_issuers` | `payment_method_id`, `bin`, `product_id`, `public_key` |
| GET | `/cho-off/v1/identification_types` | `public_key` |

All requests include headers `X-Product-id`, `Meli-Session-id`, `SDK-version`.

---

## Test cards (Argentina)

| Brand | Number | CVV | Expiry | BIN-8 | Status |
|-------|--------|-----|--------|-------|--------|
| Visa | 4509 9535 6623 3704 | 123 | 11/30 | 45099535 | APRO → approved |
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | 50317557 | APRO → approved |

More test cards: https://www.mercadopago.com.ar/developers/en/docs/checkout-api/integration-test/test-cards

---

## Running locally

```bash
# SDK
flutter analyze   # must be 0 issues
flutter test      # 105 tests

# Example app
cd example
# Replace APP_USR-REPLACE-WITH-YOUR-KEY in lib/main.dart
flutter run -d <device>
```

---

## Release status (v0.1.0)

| Feature | Status |
|---------|--------|
| CoreMethods (tokenization, methods, installments, issuers, ID types) | ✅ Done |
| Hosted checkout (CardSave + CardTransaction) | ✅ Done |
| PCI widgets (CardNumber, SecurityCode, ExpirationDate) | ✅ Done |
| Device fingerprinting (iOS xcframework + Android native) | ✅ Done |
| License, pub.dev topics, DartDoc | ✅ Done |
| Integration tests against real API | ⏳ Pending |
| Widget tests for checkout screens | ⏳ Pending |
| Federated plugin architecture | ⏳ Deferred post v1.0 |
| Official Flutter-specific X-Product-id | ⏳ Pending (using iOS value) |

---

## Common mistakes AI tools make with this SDK

1. **Suggesting `NewCardData`** — removed from public API; always use PCI controllers
2. **Suggesting `rawValue`** — not needed in any public integration pattern
3. **6-digit BIN** — API requires 8 digits
4. **Missing Android Artifactory** — most common integration error
5. **Not disposing `PciFieldState`** — causes memory leak + PCI risk
6. **Storing the token** — it expires in 15 min, send to backend immediately
7. **`pluginClass: none`** — invalid Flutter plugin syntax; just omit the platform
