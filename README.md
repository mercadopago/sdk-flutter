# mercadopago_flutter_sdk

**Official Flutter plugin for MercadoPago card payments across Latin America.**

Tokenize cards, present a hosted checkout, and collect card input through
PCI-compliant widgets — without your app ever touching raw card data.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2023%2B-green?logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-black?logo=apple)](https://developer.apple.com)

> **Status:** pre-release `v0.1.0` — public API may change before `v1.0`.

---

## Why this SDK?

Accepting card payments with MercadoPago requires PCI-compliant card capture,
secure tokenization, and handling of installments — all while keeping raw card
data away from your application code. This plugin wraps all of that into an
idiomatic Flutter API.

| Goal | What to use |
|------|------------|
| Drop in a complete checkout UI (card form + installments) | [`MercadoPagoCheckout`](#hosted-checkout) |
| Build a fully custom card form | [`CoreMethods`](#core-methods) + [PCI widgets](#pci-widgets) |
| Look up payment methods or installments | [`CoreMethods`](#core-methods) |

---

## Features

- **Hosted checkout** — SDK-owned card-entry UI with installment selection and review screen
- **PCI-compliant input widgets** — `CardNumberField`, `SecurityCodeField`, `ExpirationDateField` keep raw card values inside the SDK; your code never reads them
- **Secure tokenization** — `createTokenForNewCard` and `createTokenForSavedCard` accept widget controllers, not raw strings
- **Typed result handling** — sealed `MercadoPagoResult<T>` with `Success`, `Failure`, and `Cancelled` variants
- **Device fingerprinting** — native Android + iOS integration for fraud signals, with graceful fallback
- **Session management** — automatic `Meli-Session-id` UUID rotation on each initialization
- **7 Latin American markets** — ARG, BRA, CHL, COL, MEX, PER, URY

---

## Platform support

| Platform | Tokenization | Checkout UI | Device fingerprint |
|----------|:---:|:---:|:---:|
| Android (API 23+) | ✅ | ✅ | ✅ |
| iOS (13.0+) | ✅ | ✅ | ✅ |

This is a mobile-first SDK. MercadoPago card payments are designed for
Android and iOS applications.

---

## Requirements

- Flutter `3.10+` / Dart `3.0+`
- iOS `13.0+`
- Android API `23+` (Android 6.0)
- A MercadoPago account with a public key — [get one here](https://www.mercadopago.com/developers/panel/app)

---

## Installation

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:
  mercadopago_flutter_sdk: ^0.1.0
```

```bash
flutter pub get
```

### 2. Android setup (required)

The device-fingerprint library is distributed from MercadoLibre's public
Artifactory. Add it to `android/settings.gradle`:

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

> **Legacy layout?** Add the same `maven {}` block inside `allprojects > repositories`
> in `android/build.gradle`. Without this, `flutter run` fails to resolve
> `com.mercadolibre.android.device:sdk`.

### 3. iOS setup

No extra steps. `DeviceFingerPrint.xcframework` ships embedded in the plugin
and is linked automatically via the podspec.

---

## Quick start

Initialize once at app startup, then open a hosted checkout:

```dart
import 'package:flutter/material.dart';
import 'package:mercadopago_flutter_sdk/mercadopago_flutter_sdk.dart';

void main() {
  MercadoPagoSDK.shared.initialize(
    publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    countryCode: 'ARG', // ARG | BRA | CHL | COL | MEX | PER | URY
  );
  runApp(const MyApp());
}

// In any widget:
MercadoPagoCheckout.forCardSave(
  onResult: (result) {
    switch (result) {
      case Success(:final data):
        sendToBackend(data.token.token); // opaque token → your server
      case Failure(:final error):
        showError(error.toString());
      case Cancelled():
        break;
    }
  },
).build(); // returns a Widget; push it with Navigator
```

---

## Hosted checkout

### Card Save

Tokenize a card for future payments. The SDK owns the entire card-entry UI;
your app only receives the token.

```dart
final builder = MercadoPagoCheckout.forCardSave(
  onResult: (result) {
    if (result case Success(:final data)) {
      // Send data.token.token to your backend — never store on device.
      // Token expires in ~15 minutes.
    }
  },
);

Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => builder.build()),
);
```

### Card Transaction

Tokenize a card and let the user choose installments before confirming.

```dart
MercadoPagoCheckout.forCardTransaction(
  amount: 1500.00,
  payerEmail: 'buyer@example.com',
  onResult: (result) {
    if (result case Success(:final data)) {
      // data.token.token + data.installments + data.transactionAmount → backend
    }
  },
).build();
```

### Appearance

```dart
MercadoPagoCheckout.forCardSave(
  appearance: const MPCheckoutAppearance(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF6200EE),
  ),
  onResult: (r) { ... },
);
```

---

## Core Methods

For full control over the UI, use `CoreMethods` together with the PCI input
widgets. The SDK reads raw card values internally — your code never accesses
them.

### Custom card form

```dart
// 1. Declare PCI controllers
final cardNumber     = PciFieldState();
final securityCode   = PciFieldState();
final expirationDate = PciFieldState();
final nameCtrl       = TextEditingController();

@override
void dispose() {
  cardNumber.dispose();     // zeroes out raw value
  securityCode.dispose();
  expirationDate.dispose();
  nameCtrl.dispose();
  super.dispose();
}

// 2. Render PCI widgets — values stay inside controllers
CardNumberField(controller: cardNumber),
ExpirationDateField(controller: expirationDate),
SecurityCodeField(controller: securityCode),
TextField(controller: nameCtrl),

// 3. Tokenize — pass controllers, not raw strings
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumber,
  securityCode: securityCode,
  expirationDate: expirationDate,
  cardholderName: nameCtrl.text.trim(),
);
```

### Saved cards

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForSavedCard(
  cardId: 'CARD-ID-FROM-BACKEND',
  securityCode: cvvController, // PciFieldState
);
```

### BIN lookup, installments, issuers

```dart
final sdk = MercadoPagoSDK.shared.coreMethods;

// All BIN lookups require 8 digits
await sdk.getPaymentMethods(bin: '45099535');
await sdk.getInstallments(bin: '45099535', amount: 1500.0);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes();
```

---

## PCI widgets

`CardNumberField`, `SecurityCodeField`, and `ExpirationDateField` store
card values in memory through `PciFieldState`. The raw data is read only
inside the SDK during tokenization.

```dart
CardNumberField(
  controller: cardNumber,
  onBinChanged: (bin) => _detectBrand(bin), // fires after 8th digit
),
```

**Dispose is required.** Calling `dispose()` on a `PciFieldState` zeroes out
the stored value and unregisters listeners:

```dart
@override
void dispose() {
  cardNumber.dispose();
  super.dispose();
}
```

---

## Error handling

`MercadoPagoResult<T>` is a sealed class. Pattern-match exhaustively:

```dart
switch (result) {
  case Success(:final data):
    // use data
  case Failure(:final error):
    final message = switch (error) {
      InvalidCardNumberError()     => 'Invalid card number.',
      InvalidCvvError()            => 'Invalid security code.',
      CardExpiredError()           => 'Card has expired.',
      NetworkError(:final message, :final isRetriable) =>
        '${isRetriable ? 'Retryable error' : 'Error'}: $message',
      ValidationError(:final message) => message,
      _                            => error.toString(),
    };
  case Cancelled():
    // user dismissed the checkout
}
```

---

## Security

- **Raw card data never leaves the SDK** — `PciFieldState` holds values in
  memory only; `toString()` returns a masked representation.
- **No persistent storage** — the SDK never writes card data to disk,
  `SharedPreferences`, Keychain, or any storage layer.
- **Short-lived tokens** — tokens expire in ~15 minutes and are never reused.
- **Session UUIDs** — a fresh `Meli-Session-id` is generated on every
  `initialize()` call for fraud correlation.
- **TLS 1.2+** — all network communication uses HTTPS; no exceptions.
- **Device fingerprinting** — native-only, via Platform Channel. The SDK
  collects no personal data, location, or contacts.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

---

## Example app

A runnable example demonstrating all three integration paths lives in
[`example/`](example/).

```bash
cd example
# Set your key in lib/main.dart
flutter run
```

---

## Roadmap

| Version | Focus |
|---------|-------|
| **v0.1.0** | Core tokenization, hosted checkout, PCI widgets, device fingerprinting |
| **v0.2** | Integration tests, retry logic, pub.dev publishing |
| **v0.3** | ESC (Encrypted Security Code), Apple Pay |
| **v1.0** | Stable public API, federated plugin architecture |

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request.

```bash
# Run tests
flutter test

# Lint
flutter analyze
```

All PRs must pass `flutter analyze` (0 issues) and `flutter test` (all tests).

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Copyright 2024 MercadoPago.
