# MercadoPago Flutter SDK — Complete AI Reference

## Purpose

`mercadopago` is the official Flutter plugin for MercadoPago card
tokenization. It lets Flutter developers accept card payments in Latin America
through controller-based card capture. Application code passes controllers
directly to tokenization and receives an opaque, short-lived token for its
backend.

**Why this exists**: This SDK brings the MercadoPago tokenization flow
available in the iOS and Android SDKs to Flutter.

---

## Architecture overview

### Package type: Flutter Plugin

- **Dart layer** (pure): CoreMethods, PCI widgets, domain models
- **Native Android** (Kotlin): Platform Channel for device fingerprinting
- **Native iOS** (Swift): Platform Channel with a deterministic empty fallback

### Layer structure

```
lib/src/
├── core/           SDK singleton, HTTP client (package:http), session UUID,
│                   configuration, error types, Luhn algorithm
├── domain/         Sealed Result<T>, domain models, repository interfaces,
│                   error hierarchy
├── data/           JSON DTOs with defensive parsing, repository implementations
├── core_methods/   Public low-level API class
├── pci/            Single library: field state, PCI input widgets,
│                   ExpirationDateField, PciFieldState)
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

If integrator code reads raw card numbers, it can accidentally log, persist, or
re-transmit them and expand the application's PCI DSS scope.

### The solution

`createTokenForNewCard` and `createTokenForSavedCard` take `PciFieldState`
**controllers**, not strings. The supported integration passes those
controllers directly to `CoreMethods`, which sends the required values to the
MercadoPago tokenization endpoint.

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

// ❌ Antipattern — importing lib/src helpers to extract a raw string
```

No symbol in the package — exported or not — returns a raw card value:
everything that can observe one lives in the single `lib/src/pci/` library and
the value is private to it, enforced by the Dart compiler. Importing `lib/src/`
yields no accessor to bypass. Treat this as exposure reduction, not an isolated
secure element or PCI DSS certification.

---

## Installation

### pubspec.yaml

```yaml
dependencies:
  mercadopago:
    git:
      url: https://github.com/mercadopago/sdk-flutter.git
      ref: main # Pin an audited commit SHA in production.
```

After the first pub.dev release, use the hosted version shown on the package's
official pub.dev page.

### Android setup (required)

The device-fingerprint library is resolved from MercadoLibre's Artifactory.
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

DeviceSDK contributes `com.google.android.gms.permission.AD_ID` to the merged
manifest. The plugin does not request optional runtime permissions, but the
host owns Play Data Safety, advertising-ID, consent, and privacy disclosures.

### iOS setup

No extra setup is needed. The iOS plugin does not bundle a fingerprint
framework. For compatibility, `getDeviceData` returns an empty map and Dart
continues tokenization without a `device` payload. Do not generate iOS code
that invents fallback identifiers or reintroduces a fingerprint binary. Keep
this fallback until the native owner publishes an approved, versioned artifact
with licensing, privacy-manifest, signing, and provenance evidence.

---

## Initialization

Must be called once before any SDK operation, typically in `main()`:

```dart
void main() {
  try {
    MercadoPagoSDK.shared.initialize(
      publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      countryCode: 'ARG',
      analyticsEnabled: false, // Optional; defaults to true
    );
  } on SDKInvalidPublicKeyError catch (e) {
    // Key format wrong — use TEST-* for testing or APP_USR-* in production
  } on SDKInvalidCountryError catch (e) {
    // Country not supported
  }
  runApp(const MyApp());
}
```

**Key format**: `TEST-*` for testing credentials or `APP_USR-*` for production.
Get it at https://www.mercadopago.com/developers/panel/app

**Supported countries**: ARG, BRA, CHL, COL, MEX, PER, URY

**Re-initialize** (to switch credentials):
```dart
MercadoPagoSDK.shared.setNewConfiguration(
  publicKey: '...',
  countryCode: 'BRA',
  analyticsEnabled: false,
);
// Rotates session UUID, clears GET cache
```

### Analytics contract

Analytics default to enabled for native-SDK parity. Pass
`analyticsEnabled: false` to both `initialize` and any later
`setNewConfiguration` call to opt out; disabled analytics do not enqueue or
send events.

Enabled analytics send fire-and-forget HTTPS `POST` requests to Mercado
Libre/Mercado Pago's `https://api.mercadolibre.com/tracks` endpoint for
operational and product measurement. The payload contains event identifiers,
path/time, public key, SDK/app/site/platform/OS context, an in-memory random
process UID, a session UUID, and non-PCI operation metadata. Operation fields
can include document type, payment-method/issuer data, error category, and
installment `transaction_amount`; they do not include PAN, CVV, expiration
date, cardholder name, or identification number.

The event queue is memory-only, serialized, bounded to 20 pending events, and
uses a five-second HTTP timeout. Failures and overflow are dropped without
affecting SDK operations. The privacy owner must confirm the permitted use and
retention of `transaction_amount`; this project does not claim a server-side
retention period.

---

## Integration path: CoreMethods + PCI widgets

App builds its own form using PCI-oriented input widgets.
Best for: apps with strict design requirements.

```dart
// 1. Declare controllers
final _cardNumber    = PciFieldState();
final _cvv           = PciFieldState();
final _expirationDate = PciFieldState();
final _name          = TextEditingController();
String? _activeBin;
int? _securityCodeLength;

Future<void> _loadPaymentMetadata(String? bin) async {
  _activeBin = bin;
  _cvv.clear();
  if (mounted) setState(() => _securityCodeLength = null);
  if (bin == null) return;

  final result = await MercadoPagoSDK.shared.coreMethods.getPaymentMethods(
    bin: bin,
  );
  if (!mounted || _activeBin != bin) return;

  final methods = switch (result) {
    Success(:final data) => data,
    Failure() => const <PaymentMethod>[],
  };
  final length = methods.isEmpty ? null : methods.first.securityCodeLength;
  setState(() {
    _securityCodeLength = length == 3 || length == 4 ? length : null;
  });
}

// 2. Dispose (required — PciFieldState.dispose() clears the retained value)
@override
void dispose() {
  _cardNumber.dispose();
  _cvv.dispose();
  _expirationDate.dispose();
  _name.dispose();
  super.dispose();
}

// 3. Render PCI widgets — pass controllers without importing internal helpers
CardNumberField(
  controller: _cardNumber,
  onBinChanged: _loadPaymentMetadata, // receives 8 digits, or null if cleared
),
ExpirationDateField(controller: _expirationDate), // MMYY format internally
SecurityCodeField(
  controller: _cvv,
  expectedLength: _securityCodeLength, // resolve 3/4 from BIN metadata
),

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

The widgets clear visible/retained values when removed or when the app enters
`inactive`/`paused`/`detached`. Successful tokenization clears every supplied PCI
controller. Validation/network failures retain values for correction or retry.
These are logical clearing guarantees, not byte-level memory zeroization.

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

// All lookups use the 8-digit BIN expected by the native SDK contract.
const mode = ProcessingMode.gateway;
await sdk.getPaymentMethods(bin: '45099535', mode: mode);
await sdk.getInstallments(
  bin: '45099535',
  amount: 1500.0,
  mode: mode,
);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes(); // returns DNI, CPF, RUT, etc. per country
```

Both discovery methods default to `ProcessingMode.aggregator`. A gateway flow
must pass the same explicit mode to payment-method and installment lookups.
Their public models preserve the native contract's merchant account,
agreements, payer costs, labels, issuer/card/BIN metadata, thumbnails,
installment-rate collectors, and reimbursement rates.

---

## Result type and error handling

`MercadoPagoResult<T>` is a sealed class. Exhaustive switch is required.

```dart
switch (result) {
  case Success(:final data): /* use data */
  case Failure(:final error): /* error is MercadoPagoError */
}
```

### Complete error type reference

| Error type | Meaning | Common fix |
|-----------|---------|------------|
| `InvalidCardNumberError` | Luhn check failed | User typed wrong number |
| `InvalidCvvError` | CVV length differs from payment-method config | User typed wrong CVV |
| `InvalidExpirationDateError` | Format wrong (not MMYY) | ExpirationDateField validates on input |
| `CardExpiredError` | Card is past expiry | Ask user for different card |
| `BinIsEmptyError` | Empty BIN in a lookup | Trigger lookup only after 8 digits |
| `NetworkError(isRetriable, message)` | HTTP/network failure | Retry if isRetriable is true |
| `ValidationError(field, message)` | Local/API field validation, including malformed BIN | Show message to user |

---

## HTTP endpoints (for debugging / context)

All endpoints are under `https://api.mercadopago.com`:

| Method | Endpoint | Query params |
|--------|----------|--------------|
| POST | `/v1/card_tokens` | `public_key` |
| GET | `/cho-off/v1/payment_methods` | `bin`, `processing_mode`, `product_id`, `public_key` |
| GET | `/cho-off/v1/installments` | `bin`, `amount`, `processing_mode`, `product_id`, `public_key` |
| GET | `/cho-off/v1/card_issuers` | `payment_method_id`, `bin`, `product_id`, `public_key` |
| GET | `/cho-off/v1/identification_types` | `public_key` |

All requests include `Meli-Session-id` and `SDK-version`. Card-token POSTs also
include `X-Product-id`; CoreMethods GETs send `product_id` as a query parameter
when the endpoint requires it.

The assigned product ID is `CVQP49FTT60D1548Q56G`; it is not a placeholder.

---

## Test cards (Argentina)

| Brand | Number | CVV | Expiry | BIN-8 | Status |
|-------|--------|-----|--------|-------|--------|
| Visa | 4509 9535 6623 3704 | 123 | 11/30 | 45099535 | APRO → approved |
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | 503175 | APRO → approved |

More test cards: https://www.mercadopago.com.ar/developers/en/docs/checkout-api/integration-test/test-cards

---

## Running locally

```bash
# Complete pull-request gate (native targets supported by this host included)
./tool/verify.sh

# Example app
cd example
flutter run -d <device> \
  --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-...
```

---

## Release status (v0.1.0)

| Feature | Status |
|---------|--------|
| CoreMethods (tokenization, methods, installments, issuers, ID types) | ✅ Done |
| PCI widgets (CardNumber, SecurityCode, ExpirationDate) | ✅ Done |
| Android device fingerprinting implementation | ✅ Implemented |
| iOS fingerprint compatibility fallback | ✅ Empty, no native collection |
| Android AD_ID/Data Safety review | ⚠️ Host release action |
| Local quality, coverage, native-build and package dry-run gate | ✅ `./tool/verify.sh` |
| License, pub.dev metadata, public API documentation comments | ✅ Implemented |
| Integration tests against real API | ⏳ Pending |
| Publication to pub.dev | ⏳ Pending |
| Federated plugin architecture | ⏳ Deferred post v1.0 |
| Assigned product ID `CVQP49FTT60D1548Q56G` | ✅ Configured |

---

## Common mistakes AI tools make with this SDK

1. **Suggesting `NewCardData`** — removed from public API; always use PCI controllers
2. **Importing `lib/src/` PCI helpers** — outside the supported public API
3. **Long BIN prefixes** — CoreMethods lookups require exactly the first 8 digits
4. **Missing Android Artifactory** — most common integration error
5. **Not disposing `PciFieldState`** — causes memory leak + PCI risk
6. **Storing the token** — it expires after first use or within the documented
   maximum lifetime (currently 7 days); send it to the backend immediately
7. **`pluginClass: none`** — invalid Flutter plugin syntax; just omit the platform
