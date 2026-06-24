# MercadoPago Flutter SDK — AI Context

## What it is

Official Flutter plugin for MercadoPago card tokenization. Integrators pass
card data through PCI-compliant input widgets; the SDK tokenizes and returns
an opaque token for the backend — raw card values are never accessible to
integrator code.

Package: `mercadopago_flutter_sdk`
Repo: https://github.com/mercadopago/sdk-flutter
License: Apache 2.0

---

## Installation

### pubspec.yaml

```yaml
dependencies:
  mercadopago_flutter_sdk: ^0.1.0
```

### Android — required step

Add the MercadoLibre Artifactory to `android/settings.gradle` (or
`android/build.gradle` if using the legacy layout):

```gradle
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://artifacts.mercadolibre.com/repository/android-releases'
            content { includeGroup 'com.mercadolibre.android.device' }
        }
    }
}
```

Without this, `flutter run` fails on Android with a missing dependency error.

### iOS

No extra steps. The `DeviceFingerPrint.xcframework` ships bundled inside the
plugin (`ios/Frameworks/`).

---

## Initialization

Call once, before any other SDK method — typically in `main()`:

```dart
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  MercadoPagoSDK.shared.initialize(
    publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    countryCode: 'ARG', // ARG | BRA | CHL | COL | MEX | URY | PER
  );
  runApp(const MyApp());
}
```

Throws `SDKInvalidPublicKeyError` if key format is wrong, or
`SDKInvalidCountryError` if the country is not supported.

---

## Three integration paths

### Path 1 — Hosted checkout: Card Save

SDK owns the entire card-entry UI. Integrator only receives the token.

```dart
final builder = MercadoPagoCheckout.forCardSave(
  onResult: (result) {
    switch (result) {
      case Success(:final data):
        // Send data.token.token to your backend — never store on device.
        print('Payment method: ${data.paymentMethodId}');
      case Failure(:final error):
        print('Error: $error');
      case Cancelled():
        print('User cancelled.');
    }
  },
);

Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => builder.build()),
);
```

### Path 2 — Hosted checkout: Card Transaction

Same as Card Save, but includes installment selection and review screens.

```dart
final builder = MercadoPagoCheckout.forCardTransaction(
  amount: 1500.0,
  payerEmail: 'buyer@example.com',
  onResult: (result) {
    if (result case Success(:final data)) {
      // data.token.token + data.installments + data.transactionAmount → backend
    }
  },
);
```

### Path 3 — CoreMethods with PCI widgets (custom UI)

Integrator builds the form UI using PCI-compliant input widgets.
**Raw card values are never accessible to integrator code** — pass
the `PciFieldState` controllers directly to `createTokenForNewCard`.

```dart
final cardNumber    = PciFieldState();
final securityCode  = PciFieldState();
final expirationDate = PciFieldState();
final nameCtrl      = TextEditingController();

@override
void dispose() {
  cardNumber.dispose();
  securityCode.dispose();
  expirationDate.dispose();
  nameCtrl.dispose();
  super.dispose();
}

// In the build method:
CardNumberField(controller: cardNumber),
ExpirationDateField(controller: expirationDate),
SecurityCodeField(controller: securityCode),
TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Cardholder name')),

// On submit:
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumber,           // ← PciFieldState, NOT a String
  securityCode: securityCode,       // ← PciFieldState, NOT a String
  expirationDate: expirationDate,   // ← PciFieldState (MMYY format)
  cardholderName: nameCtrl.text.trim(),
);

switch (result) {
  case Success(:final data):
    // Send data.token to your backend
  case Failure(:final error):
    // Show error to user
  case Cancelled():
    break;
}
```

#### ⚠️ Common mistake

```dart
// ❌ WRONG — never do this:
final raw = cardNumber.rawValue; // exposes raw card number

// ✅ CORRECT — pass the controller:
createTokenForNewCard(cardNumber: cardNumber, ...)
```

---

## Saved cards

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForSavedCard(
  cardId: 'CARD-ID-FROM-BACKEND',
  securityCode: cvvController, // PciFieldState
);
```

---

## Error handling

`MercadoPagoResult<T>` is a sealed class. Always handle all three cases:

```dart
switch (result) {
  case Success(:final data):   // happy path
  case Failure(:final error):  // SDK or network error
  case Cancelled():             // user closed the checkout UI
}
```

Common `MercadoPagoError` variants:
- `InvalidCardNumberError` — Luhn check failed
- `InvalidCvvError` — CVV length wrong (must be 3–4 digits)
- `InvalidExpirationDateError` / `CardExpiredError`
- `NetworkError(isRetriable: bool, message: String)`
- `BinIsEmptyError` — bin was empty when calling `getPaymentMethods`

---

## Other CoreMethods

```dart
final sdk = MercadoPagoSDK.shared.coreMethods;

// Detect card brand by BIN (first 8 digits of card number)
final methods = await sdk.getPaymentMethods(bin: '45099535');

// Get installment options
final installments = await sdk.getInstallments(bin: '45099535', amount: 1500.0);

// Get issuing banks
final issuers = await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');

// Document types for current country
final idTypes = await sdk.getIdentificationTypes();
```

---

## Supported countries

`ARG` (Argentina), `BRA` (Brazil), `CHL` (Chile), `COL` (Colombia),
`MEX` (Mexico), `PER` (Peru), `URY` (Uruguay).

---

## Test cards (Argentina)

| Brand | Number | CVV | Expiry | Cardholder |
|-------|--------|-----|--------|------------|
| Visa  | 4509 9535 6623 3704 | 123 | 11/30 | APRO |
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | APRO |

BIN for API calls (8 digits): `45099535` (Visa), `50317557` (Mastercard).

---

## Running the example app

```bash
cd example
# Replace APP_USR-REPLACE-WITH-YOUR-KEY in lib/main.dart with your key
flutter run
```

---

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `SDKInvalidPublicKeyError` | Key doesn't match `APP_USR-{uuid}` format | Get key from developers.mercadopago.com |
| `Could not find com.mercadolibre.android.device:sdk` | Missing Artifactory in Android | Add maven block to settings.gradle (see Installation) |
| HTTP 400 `missing product_id` | Sending BIN to wrong endpoint | Use the SDK methods — don't call the API directly |
| HTTP 404 on payment methods | BIN too short | Use 8-digit BIN, not 6 |
| `type int is not a subtype of Map` | Old API usage | Pass `PciFieldState` controllers, not `NewCardData` |
