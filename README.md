# MercadoPago SDK for Flutter

Official Flutter SDK for integrating MercadoPago payments into mobile
applications across Latin America.

> **Status:** pre-release (`v0.1.0`). Public API may change before `v1.0`.

## Why this SDK?

| You want to… | Use… |
|--------------|------|
| Drop in a complete, themable checkout flow | [`MercadoPagoCheckout`](#hosted-checkout) |
| Build a fully custom UI on top of MercadoPago | [`CoreMethods`](#core-methods) + PCI widgets |
| Tokenize card data on a screen you fully own | [`CardNumberField`](#pci-widgets), [`SecurityCodeField`](#pci-widgets), [`ExpirationDateField`](#pci-widgets) |

All three paths share the same underlying engine: a single result type
(`MercadoPagoResult<T>`), one session UUID per app run, and PCI data that
never touches disk or logs.

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  mercadopago_flutter_sdk: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Requirements

- Flutter `3.10+` / Dart `3.x`
- iOS `13.0+`
- Android API `23+` (Android 6.0)

### Android setup

The SDK depends on MercadoLibre's device-fingerprinting library, which is
distributed from MercadoLibre's public Artifactory (the same one
`sdk-android` uses). Add this repository to your host app's
`android/settings.gradle`:

```gradle
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://artifacts.mercadolibre.com/repository/android-releases'
            content {
                includeGroup 'com.mercadolibre.android.device'
            }
        }
    }
}
```

> If your project still uses the legacy layout that declares repositories
> in `android/build.gradle`'s `allprojects` block, add the same `maven {}`
> entry there. Without this declaration, `flutter run` and
> `flutter build apk` fail to resolve
> `com.mercadolibre.android.device:sdk`.

The `includeGroup` clause restricts Gradle so it only ever asks the
MercadoLibre Artifactory for that exact group — every other dependency in
your app keeps resolving from your usual repos.

### iOS setup

No extra configuration needed. The `DeviceFingerPrint.xcframework` ships
embedded in the plugin (under `ios/Frameworks/`) and is wired
automatically through the podspec.

---

## Initialization

Call `initialize` once, typically in `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  MercadoPagoSDK.shared.initialize(
    publicKey: 'APP_USR-xxxxxxxxxxxxxxxxxxxxxxxx',
    countryCode: 'ARG', // any of the 19 ISO codes (ARG, BRA, CHL, COL, MEX, …)
  );
  runApp(const MyApp());
}
```

Use `setNewConfiguration` to change credentials at runtime (this rotates the
session UUID and clears caches):

```dart
MercadoPagoSDK.shared.setNewConfiguration(
  publicKey: 'APP_USR-different-key',
  countryCode: 'BRA',
);
```

---

## Hosted checkout

The hosted checkout handles the entire UI for you. It supports two flows:

### Card Save

Tokenize a card without charging it. Use this when you need to save a card
for later payments.

```dart
final builder = MercadoPagoCheckout.forCardSave(
  onResult: (result) {
    switch (result) {
      case Success(:final data):
        sendTokenToBackend(data.token.token);
      case Failure(:final error):
        showSnack('Error: $error');
      case Cancelled():
        // user closed the flow
    }
  },
);

Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => builder.build()),
);
```

### Card Transaction

Tokenize a card and let the user pick installments for an immediate payment.

```dart
final builder = MercadoPagoCheckout.forCardTransaction(
  amount: 25_000.00,
  payerEmail: 'buyer@example.com',
  onResult: (result) {
    if (result case Success(:final data)) {
      createPaymentOnBackend(
        token: data.token.token,
        installments: data.installments,
        amount: data.transactionAmount,
      );
    }
  },
);

Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => builder.build()),
);
```

### Theming

```dart
MercadoPagoCheckout.forCardSave(
  appearance: const MPCheckoutAppearance(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF6200EE),
  ),
);
```

---

## Core Methods

For full control over the UI, talk to the API directly through
`MercadoPagoSDK.shared.coreMethods`:

```dart
final core = MercadoPagoSDK.shared.coreMethods;

// Detect card brand
final methods = await core.getPaymentMethods(bin: '423456');

// Get installment options
final installments = await core.getInstallments(
  bin: '423456',
  amount: 1000.00,
);

// Tokenize a new card
final token = await core.createTokenForNewCard(
  const NewCardData(
    cardNumber: '4111 1111 1111 1111',
    cardholderName: 'JOHN DOE',
    expirationMonth: 12,
    expirationYear: 2030,
    securityCode: '123',
  ),
);

// Tokenize a previously saved card
final saved = await core.createTokenForSavedCard(
  const SavedCardData(cardId: 'card_id_123', securityCode: '123'),
);
```

Every call returns a `MercadoPagoResult<T>`. Use Dart 3's exhaustive pattern
matching to handle each branch.

---

## PCI widgets

Build a custom card form without touching raw card data:

```dart
final number = PciFieldState();
final cvv = PciFieldState();
final exp = PciFieldState();

@override
void dispose() {
  number.dispose();
  cvv.dispose();
  exp.dispose();
  super.dispose();
}

Column(
  children: [
    CardNumberField(
      controller: number,
      onBinChanged: (bin) => _loadPaymentMethods(bin),
    ),
    Row(children: [
      Expanded(child: ExpirationDateField(controller: exp)),
      SizedBox(width: 110, child: SecurityCodeField(controller: cvv)),
    ]),
  ],
);
```

Card values stay inside `PciFieldState` (in-memory only) until you pass them
to `coreMethods.createTokenForNewCard`. They are never logged, serialized,
or written to disk.

---

## Error handling

`MercadoPagoError` is a sealed class — pattern-match exhaustively:

```dart
String describe(MercadoPagoError e) => switch (e) {
  NetworkError(:final message, :final isRetriable) =>
    'Network: $message (retriable=$isRetriable)',
  ValidationError(:final field, :final message) => '$field: $message',
  InvalidCardNumberError() => 'Invalid card number',
  InvalidCvvError()       => 'Invalid security code',
  InvalidExpirationDateError() => 'Invalid expiration date',
  CardExpiredError()      => 'Card expired',
  BinIsEmptyError()       => 'BIN cannot be empty',
  InitializationFailedError(:final reason) => 'Init failed: $reason',
  UnknownError(:final message) => 'Unknown: $message',
};
```

---

## Security model

- **Card data never leaves the device**: `PciFieldState` holds raw values
  in memory only. `toString()` does not leak them.
- **No persistent storage**: the SDK never writes card data to
  `SharedPreferences`, `flutter_secure_storage`, files, or
  `UserDefaults`/`Keychain`.
- **Session correlation**: each `initialize()` mints a fresh UUID sent as
  `Meli-Session-id` on every request.
- **HTTPS only**: all communication is TLS 1.2+, using the system
  certificate store.
- **Device fingerprinting**: opt-in, delegated to the native
  fingerprinting SDK via a Platform Channel. If unavailable (e.g.
  simulator), tokenization continues without it.
- **Token TTL**: tokens expire in ~15 minutes. The SDK never persists nor
  reuses them.

### Optional Android permissions

The plugin only declares `INTERNET`. The host app may add
`ACCESS_COARSE_LOCATION` and `READ_PHONE_STATE` if it wants the
fingerprinting SDK to collect richer signals.

---

## Supported countries

MercadoPago operates — and the SDK is supported — in:
`ARG` (Argentina), `BRA` (Brazil), `CHL` (Chile), `COL` (Colombia),
`MEX` (Mexico), `PER` (Peru), `URY` (Uruguay).

---

## Roadmap

See [`specs/constitution/roadmap.md`](specs/constitution/roadmap.md) for the
full Spec-Driven Development backlog. Highlights:

- `v0.2` — retries, integration tests, pub.dev publishing
- `v0.3` — ESC (Encrypted Security Code), checkout theming, Apple Pay

---

## Example

A runnable example app lives under `example/`. Replace the placeholder
public key in `example/lib/main.dart` with a real one:

```bash
cd example
flutter pub get
flutter run
```

---

## License

See [LICENSE](LICENSE).
