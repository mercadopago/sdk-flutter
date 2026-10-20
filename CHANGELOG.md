# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-20

First public release on pub.dev.

### Added

- `MercadoPagoSDK` singleton entry point with `initialize()` and `setNewConfiguration()`.
- `CoreMethods` low-level API, with public models that mirror the native
  Android/iOS SDKs:
  - `createTokenForNewCard()` with PCI field controllers and a typed
    `BuyerIdentification` (name + optional document).
  - `createTokenForSavedCard()` by card id + PCI security-code controller and
    an optional `expirationDate` controller.
  - `getPaymentMethods(bin)`, accepting `ProcessingMode` (default
    `aggregator`, matching `getInstallments`). Gateway integrations must use
    the same mode for both lookups.
  - `getInstallments(bin, amount)`.
  - `getIssuers(paymentMethodId, bin)`.
  - `getIdentificationTypes()`.
- PCI-oriented input widgets:
  - `CardNumberField` with BIN detection and Luhn validation.
  - `SecurityCodeField` with card-brand-aware 3/4-digit handling. Unknown
    brands accept either length, BIN metadata narrows the field when
    available, and a brand change clears previously entered CVV data.
  - `ExpirationDateField` with MM/YY auto-formatting.
- Device fingerprinting via Platform Channel (`mercadopago/fingerprint`), with
  Android DeviceSDK `4.0.1` and an empty compatibility fallback on iOS.
- Automatic analytics event tracking (fire-and-forget) to `/tracks`, with a
  public `analyticsEnabled` configuration option. Analytics are enabled by
  default for native-SDK parity; opted-out configurations neither enqueue nor
  send events.
- Sealed `MercadoPagoResult<T>` type with `Success` and `Failure` variants.
- `TEST-*` credential support for sandbox integrations.
- Support for the 7 Latin American countries where MercadoPago operates
  (ARG, BRA, CHL, COL, MEX, PER, URY).
- Example app demonstrating `CoreMethods` with PCI widgets.
- A reproducible local verification gate (`./tool/verify.sh`) for formatting,
  analysis, tests, coverage thresholds, Android/iOS release builds, and pub.dev
  dry-run validation.

### Security

- PCI values are enclosed in a single Dart library (`lib/src/pci/`). No symbol
  in the package — exported or not — returns a raw card value; the boundary is
  enforced by the Dart compiler. Integrators pass `PciFieldState` controllers
  directly to `CoreMethods`.
- Sensitive fields are cleared on widget removal, app pause/detach, and
  successful tokenization. Validation and network failures retain values for
  correction or retry. This is logical clearing, not runtime-memory
  zeroization.
- Tokenization captures non-sensitive field revision counters before
  asynchronous BIN/fingerprint work and aborts if any field changes before the
  request is assembled.
- CVV length (and PAN length, when supplied) is validated against BIN-8 lookup
  metadata when it is available. A lookup outage never fabricates defaults that
  would reject a valid card.
- API response parsing follows the native contract and fails closed on
  malformed payloads instead of fabricating valid-looking defaults.
- Strict identifier/document validation, bounded caches and analytics queues,
  and sanitized public error messages.

### Privacy notes for host applications

- Android DeviceSDK contributes
  `com.google.android.gms.permission.AD_ID` to the merged manifest. Host apps
  must complete the applicable Play Data Safety, advertising-ID, consent, and
  privacy disclosures.
- Android fingerprinting forwards `DeviceSDK.info` when available and returns
  an empty payload when native collection fails.
- iOS bundles no fingerprint framework: the channel returns an empty map, so
  tokenization continues without enriched device signals.

### Known limitations

- Integration tests against the real MercadoPago API are not part of the
  mandatory suite yet.
- Automatic network retry is not implemented.
- Card capture uses Flutter widgets; full capture in native secure fields
  (Platform Views) is planned for a later release.
- The product ID is fixed to `CVQP49FTT60D1548Q56G`; it is sent as
  `X-Product-id` on card-token POSTs and as `product_id` on GET endpoints that
  require it.

[0.1.0]: https://github.com/mercadopago/sdk-flutter/releases/tag/v0.1.0
