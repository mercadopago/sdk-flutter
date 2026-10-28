<div align="center">

<img src="https://raw.githubusercontent.com/mercadopago/n8n-nodes-mercadopago/master/nodes/MercadoPago/icon-mercadopago.svg" width="80" alt="Mercado Pago" />

# Mercado Pago SDK for Flutter

**Official Flutter SDK for Mercado Pago card payments across Latin America.**

Tokenize cards and collect card input through PCI-oriented widgets without
requiring application code to copy sensitive values into raw strings.

[![pub package](https://img.shields.io/pub/v/mercadopago_sdk_flutter.svg)](https://pub.dev/packages/mercadopago_sdk_flutter)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.2%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2023%2B-green?logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-black?logo=apple)](https://developer.apple.com)

</div>

> **Status:** pre-release `v0.1.0` — public API may change before `v1.0`.

---

## Why this SDK?

Accepting card payments with MercadoPago requires careful card capture, secure
tokenization, and installment handling. This plugin provides an idiomatic
Flutter API where applications pass SDK-owned field controllers directly to
tokenization instead of copying card values into ordinary strings.

| Goal | What to use |
|------|------------|
| Build a fully custom card form | [`CoreMethods`](#core-methods) + [PCI widgets](#pci-widgets) |
| Look up payment methods or installments | [`CoreMethods`](#core-methods) |

---

## Features

- **PCI-oriented input widgets** — `CardNumberField`, `SecurityCodeField`, and `ExpirationDateField` keep sensitive values in `PciFieldState`; integrator code passes the controllers directly instead of extracting strings
- **Secure tokenization** — `createTokenForNewCard` and `createTokenForSavedCard` accept widget controllers, not raw strings
- **Typed result handling** — sealed `MercadoPagoResult<T>` with `Success` and `Failure` variants
- **Native Core Methods contract** — payment methods, installments, and issuers preserve gateway metadata, agreements, payer costs, labels, and card/BIN details returned by the native SDK contracts
- **Device fingerprinting** — native Android fraud signals with a safe, empty iOS fallback
- **Session management** — automatic `Meli-Session-id` UUID rotation on each initialization
- **7 Latin American markets** — ARG, BRA, CHL, COL, MEX, PER, URY

---

## Platform support

| Platform | Tokenization | PCI widgets | Device fingerprint |
|----------|:---:|:---:|:---:|
| Android (API 23+) | ✅ | ✅ | ✅ |
| iOS (13.0+) | ✅ | ✅ | ➖ Empty fallback |

This is a mobile-first SDK. MercadoPago card payments are designed for
Android and iOS applications.

---

## Requirements

- Flutter `3.44.2+` / Dart `3.12+`
- iOS `13.0+`
- Android API `23+` (Android 6.0)
- A MercadoPago public key: `TEST-*` for testing or `APP_USR-*` for
  production — [get credentials here](https://www.mercadopago.com/developers/panel/app)

---

## Installation

### 1. Add the dependency

```bash
flutter pub add mercadopago_sdk_flutter
```

Or add it to `pubspec.yaml` manually and run `flutter pub get`:

```yaml
dependencies:
  mercadopago_sdk_flutter: ^0.1.0
```

While the SDK is in `0.x`, a caret constraint only accepts patch releases
(`^0.1.0` resolves `>=0.1.0 <0.2.0`), so minor releases that may change the
public API are always an explicit upgrade.

### 2. Android setup (required)

The device-fingerprint library is distributed from MercadoLibre's
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

> **Android privacy review:** DeviceSDK contributes
> `com.google.android.gms.permission.AD_ID` to the merged manifest. The plugin
> itself does not request optional runtime permissions, but the host app must
> inspect its final manifest and accurately complete Google Play Data Safety,
> advertising-ID policy, consent, and privacy disclosures before release.

### 3. iOS setup

No extra code setup is required. The iOS plugin intentionally returns an empty
device payload: it does not bundle or call a device-fingerprint framework.
Tokenization therefore works on iOS without enriched fingerprint signals.
That behavior remains in place until the native owner publishes an approved,
versioned artifact with licensing, privacy-manifest, signing, and provenance
evidence. Do not add a local identifier fallback or copy an unreviewed binary
into the plugin.

---

## Quick start

Initialize once at app startup, then build your card form with the SDK widgets
and tokenize through `CoreMethods`:

```dart
import 'package:flutter/material.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  MercadoPagoSDK.shared.initialize(
    publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    countryCode: 'ARG', // ARG | BRA | CHL | COL | MEX | PER | URY
  );
  runApp(const MyApp());
}

final cardNumber = PciFieldState();
final expirationDate = PciFieldState();
final securityCode = PciFieldState();

final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumber,
  expirationDate: expirationDate,
  securityCode: securityCode,
  identification: const BuyerIdentification(name: 'JOHN DOE'),
);
```

### Analytics and opt-out

Analytics are enabled by default to preserve parity with the native SDKs. A
host application can disable them when initializing the SDK:

```dart
MercadoPagoSDK.shared.initialize(
  publicKey: 'APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  countryCode: 'ARG',
  analyticsEnabled: false,
);
```

`setNewConfiguration` accepts the same `analyticsEnabled` option. Pass
`false` there as well when replacing a configuration that must remain opted
out. When disabled, the SDK does not enqueue or send analytics events.

When enabled, the SDK sends fire-and-forget HTTPS `POST` requests to Mercado
Libre/Mercado Pago's `https://api.mercadolibre.com/tracks` endpoint for
operational and product measurement of SDK initialization, tokenization, and
Core Methods usage. The current payload can include:

- event path, event UUID and client timestamp;
- public key, locale, debug mode, SDK version, site, platform and OS version;
- a random process-lifetime UID and a session UUID generated in memory;
- non-PCI operation metadata such as saved-card status, document **type**,
  payment method/issuer identifiers, card brand, security-code length, error
  category and installment `transaction_amount`.

The SDK analytics schema does not include PAN, CVV, expiration date,
cardholder name, or identification number. Identifiers and the bounded event
queue (up to 20 pending events) are memory-only and are not persisted by this
SDK. Delivery is serialized, has a five-second HTTP timeout, and failures or
capacity drops never fail the payment operation.

Before release, the Mercado Pago privacy owner must confirm the permitted use
and retention of analytics data, particularly `transaction_amount`. This SDK
does not define or claim a server-side retention period.

---

## Core Methods

For full control over the UI, use `CoreMethods` together with the PCI input
widgets. Pass each `PciFieldState` directly to tokenization; application code
should not copy, log, or persist its sensitive value.

### Custom card form

```dart
// 1. Declare PCI controllers
final cardNumber     = PciFieldState();
final securityCode   = PciFieldState();
final expirationDate = PciFieldState();
final nameCtrl       = TextEditingController();
int? securityCodeLength; // unknown until the BIN metadata lookup finishes
String? activeBin;
bool tokenizing = false;

@override
void dispose() {
  cardNumber.dispose();     // clears the retained value
  securityCode.dispose();
  expirationDate.dispose();
  nameCtrl.dispose();
  super.dispose();
}

// 2. Render PCI widgets — values stay inside controllers
CardNumberField(
  controller: cardNumber,
  enabled: !tokenizing,
  onBinChanged: (bin) async {
    // Clear card-specific CVV state whenever the BIN changes.
    activeBin = bin;
    securityCode.clear();
    setState(() => securityCodeLength = null);
    if (bin == null) return;

    final result = await MercadoPagoSDK.shared.coreMethods
        .getPaymentMethods(bin: bin);
    // Ignore a late response for a BIN the user already replaced.
    if (!mounted || activeBin != bin) return;
    if (result case Success(:final data) when data.isNotEmpty) {
      final length = data.first.securityCodeLength;
      setState(() {
        securityCodeLength = length == 3 || length == 4 ? length : null;
      });
    }
  },
),
ExpirationDateField(
  controller: expirationDate,
  enabled: !tokenizing,
),
SecurityCodeField(
  controller: securityCode,
  expectedLength: securityCodeLength,
  enabled: !tokenizing,
),
TextField(controller: nameCtrl, enabled: !tokenizing),

// Disable all PCI fields while tokenization is in flight. CoreMethods uses a
// consistent snapshot and will not clear edits made after that snapshot, but
// freezing the form prevents the UI from appearing to represent another card
// while an earlier card's token is returned.

// 3. Tokenize — pass controllers, not raw strings. The cardholder name and
//    optional document go inside BuyerIdentification (matching the native SDKs).
setState(() => tokenizing = true);
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForNewCard(
  cardNumber: cardNumber,
  expirationDate: expirationDate,
  securityCode: securityCode,
  identification: BuyerIdentification(
    name: nameCtrl.text.trim(),
    number: '012345678', // optional
    type: 'CPF',         // optional
  ),
);
if (mounted) setState(() => tokenizing = false);
```

### Saved cards

```dart
final result = await MercadoPagoSDK.shared.coreMethods.createTokenForSavedCard(
  cardId: 'CARD-ID-FROM-BACKEND',
  securityCode: cvvController,   // PciFieldState
  expirationDate: expController, // optional PciFieldState (MMYY)
);
```

### BIN lookup, installments, issuers

```dart
final sdk = MercadoPagoSDK.shared.coreMethods;

// All BIN lookups require 8 digits
const mode = ProcessingMode.gateway;
await sdk.getPaymentMethods(bin: '45099535', mode: mode);
await sdk.getInstallments(
  bin: '45099535',
  amount: 1500.0,
  mode: mode,
);
await sdk.getIssuers(paymentMethodId: 'visa', bin: '45099535');
await sdk.getIdentificationTypes();
```

Use the same `ProcessingMode` for payment-method discovery and installments so
gateway data is not resolved through an aggregator lookup. Omitting `mode` from
both calls keeps `ProcessingMode.aggregator` as the default.

The public response models preserve the native data needed by gateway flows,
including processing mode, merchant account, agreements, payer costs, labels,
issuer/card/BIN metadata, thumbnails, installment-rate collectors, and
reimbursement rates. Empty optional strings accepted by the native contracts
are normalized to `null` where the public field is nullable.

---

## PCI widgets

`CardNumberField`, `SecurityCodeField`, and `ExpirationDateField` store card
values in memory through `PciFieldState`. The supported integration path passes
those controllers directly to `CoreMethods`.

**No symbol in this package returns the raw value** — exported or not.
Everything that can observe a card number or CVV lives in the single
`lib/src/pci/` library and the value is private to it, so the boundary is
enforced by the Dart compiler rather than by convention: importing `lib/src/`
yields no accessor to bypass. This reduces exposure; it is not an isolated
native secure element and does not certify your app as PCI DSS compliant. The
value still lives in the Dart heap, so a fork, a debug build, an attached
debugger, or card data you collect in your own `TextField` fall outside it.

```dart
CardNumberField(
  controller: cardNumber,
  // An eight-digit BIN becomes available after the 8th digit. If the user edits
  // it back to fewer than eight digits, the callback receives null.
  onBinChanged: (bin) => _detectBrand(bin),
),
```

**Dispose is required.** Calling `dispose()` on a `PciFieldState` clears its
stored value and unregisters listeners:

```dart
@override
void dispose() {
  cardNumber.dispose();
  super.dispose();
}
```

The widgets also clear their visible and retained values when they are removed
from the tree or the app enters `inactive`, `paused`, or `detached`. After successful new- or
saved-card tokenization, `CoreMethods` clears every supplied PCI controller.
Validation and network failures keep values available for correction or retry.
These are logical value-clearing guarantees, not claims of low-level memory
zeroization.

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
}
```

---

## Security

- **Controller-based capture** — sensitive values remain in `PciFieldState`
  until the SDK reads them for direct transmission to MercadoPago's
  tokenization API. The public API exposes only non-sensitive length metadata,
  and no symbol in the package returns the value — the `lib/src/pci/` library
  keeps it private at the compiler level, so there is no helper to import.
- **Lifecycle clearing** — widget removal, app pause/detach, controller
  disposal, and successful tokenization clear retained field values. This does
  not claim byte-level zeroization of Dart runtime memory.
- **Screen capture is a host responsibility** — PCI widgets cannot impose a
  whole-application screenshot policy. Protect card-entry routes and
  recent-app previews. On Android, apply `FLAG_SECURE` to the containing
  activity (the example does this). On iOS, obscure card UI before the scene
  becomes inactive and define how your app responds to active screen capture;
  iOS does not provide a general API that prevents screenshots.
- **No persistent storage** — the SDK never writes card data to disk,
  `SharedPreferences`, Keychain, or any storage layer.
- **Single-use tokens** — tokens expire after first use or within the lifetime
  reported by Mercado Pago (currently up to 7 days); do not persist them.
- **Session UUIDs** — a fresh `Meli-Session-id` is generated on initialization
  and whenever `setNewConfiguration()` replaces the active configuration.
- **Encrypted transport** — MercadoPago API endpoints use HTTPS and the host
  platform applies its TLS policy.
- **Device fingerprinting** — Android's native DeviceSDK provides fraud
  signals. If collection fails, or when running on iOS, tokenization continues
  without a device payload. Review the merged Android permissions and privacy
  disclosures before release; DeviceSDK contributes `AD_ID`. iOS remains an
  explicit empty fallback until an approved, versioned native artifact carries
  the required privacy-manifest, signing, and provenance evidence.

Using this package does not by itself certify an application as PCI DSS
compliant. Integrators remain responsible for their complete data flow,
logging, analytics, backend, and compliance assessment.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

---

## Example app

A runnable example demonstrating `CoreMethods` with PCI widgets lives in
[`example/`](example/).

```bash
cd example
flutter run \
  --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-your-public-key \
  --dart-define=MERCADOPAGO_COUNTRY_CODE=ARG
```

---

## AI-friendly development

This SDK is designed to work well with AI coding assistants (Claude Code,
GitHub Copilot, Cursor, OpenAI Codex). The repository includes structured
context files that give AI tools everything they need to help you integrate
the SDK correctly — without you having to explain the architecture every time.

### The `ai/` directory

```
ai/
├── sdk-context.md   ← Complete reference: setup, API, examples, common errors
├── claude.md        ← Instructions for Claude Code
├── copilot.md       ← Instructions for GitHub Copilot
└── codex.md         ← Instructions for OpenAI Codex / ChatGPT agents
```

### Auto-loaded context files

These files at the repo root are picked up automatically by their respective
tools when you open the project:

| File | Tool |
|------|------|
| [`CLAUDE.md`](https://github.com/mercadopago/sdk-flutter/blob/main/CLAUDE.md) | Claude Code |
| [`.github/copilot-instructions.md`](https://github.com/mercadopago/sdk-flutter/blob/main/.github/copilot-instructions.md) | GitHub Copilot |
| [`AGENTS.md`](https://github.com/mercadopago/sdk-flutter/blob/main/AGENTS.md) | OpenAI Codex / ChatGPT Agents |

### What AI tools learn from this context

- The PCI secure fields pattern — why tokenization takes `PciFieldState`
  controllers, not raw strings, and why the `lib/src/pci/` library exposes no
  way to read a card value
- The public `CoreMethods` API and PCI widget integration pattern
- Required Android setup (the Artifactory step that most integrations miss)
- Supported countries, test card numbers, and common error resolutions
- Architecture decisions and what NOT to generate

This means an AI assistant that opens this repo can immediately suggest
correct, secure integration code without needing extra prompting.

---

## Roadmap

| Version | Focus |
|---------|-------|
| **v0.1.0** | Core tokenization, PCI widgets, Android device fingerprinting, pub.dev release |
| **v0.2** | Integration tests, retry logic |
| **v0.3** | ESC (Encrypted Security Code), Apple Pay |
| **v1.0** | Stable public API, federated plugin architecture |

---

## Release verification

GitHub Actions are unavailable for this repository under the organization's
security policy. Every pull request must therefore run the reproducible local
gate and attach its successful output as review evidence:

```bash
./tool/verify.sh
```

The gate resolves package and example dependencies, checks formatting, analyzes
the package and example, runs the full test suite, enforces at least 80% line
coverage independently for `lib/src/domain/`, `lib/src/core_methods/`, and
`lib/src/pci/`, validates the pub.dev archive, and builds the native targets
supported by the host. Before merge, Android and iOS release builds must both
be evidenced from correctly provisioned hosts. `--without-native` is available
for iteration, but it is not sufficient as final merge evidence.

Native builds verify compilation only. They do not clear the Android
store-disclosure review documented above or replace an iOS privacy-report
review of the final application archive.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request.

```bash
./tool/verify.sh
```

All PRs must include successful local-gate evidence, including the native
example builds required above.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Copyright 2026 MercadoPago.
