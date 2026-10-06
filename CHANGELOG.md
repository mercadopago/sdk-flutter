# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A reproducible local verification gate (`./tool/verify.sh`) for formatting,
  package/example analysis, tests, focused coverage thresholds, Android/iOS
  release builds, and pub.dev dry-run validation. Pull requests attach this
  evidence because GitHub Actions are unavailable under the organization's
  security policy.
- Canonical iOS response fixtures for payment methods, installments, and
  issuers, plus Android native fingerprint fallback tests.

### Changed

- **PCI values are now enclosed in a single Dart library.** `lib/src/pci/`
  holds the field state, the three input widgets, validation and the
  tokenization request assembly, with the value private to that library.
  No symbol in the package — exported or not — returns a raw card value, so
  the boundary is enforced by the compiler instead of by an `@internal`
  annotation, which a consuming app could ignore. Removed the
  `readPciValue` / `snapshotPciValue` / `writePciValue` / `clearPciValue`
  helpers, the `PciValueSnapshot` typedef, and the PAN-bearing `NewCardInput` /
  `SavedCardInput` / `TokenRepository` types. Full capture in native secure
  fields (Platform Views) is tracked as post-v0.1.0 work.
- BIN lookups use 8 digits across CoreMethods, matching the native contract
  (Android `CARD_BIN_LENGTH = 8`, iOS `CardNumber.binLength = 8`).
- CoreMethods response parsing follows the native contract instead of being
  stricter: `payment_methods` no longer requires `name`, `secure_thumbnail` or
  root-level `min/max_allowed_amount` (which live in `payer_costs[]`), and the
  issuer and installment DTOs no longer require fields the native responses do
  not carry. The optional `card` block and partial PAN/CVV metadata are
  preserved during discovery; available constraints are applied only in the
  tokenization-validation path.
- Optional empty strings accepted by the iOS native contract are accepted by
  the Flutter DTOs and normalized to `null` for nullable public fields,
  including aggregator `merchant_account_id` and issuer thumbnails.
- `getPaymentMethods` now accepts `ProcessingMode`, propagates it to the HTTP
  request, and defaults to `aggregator`, matching `getInstallments`. Gateway
  integrations must use the same mode for both lookups.
- Public payment-method, installment, and issuer models now preserve native
  gateway metadata, including processing mode, merchant account, agreements,
  payer costs, labels, issuer/card/BIN data, thumbnails, installment-rate
  collectors, and reimbursement rates.
- Android fingerprinting now forwards `DeviceSDK.info` when available and
  returns an empty payload when native collection fails instead of fabricating
  a second Flutter-specific schema.
- Tokenization captures non-sensitive PCI revision counters before asynchronous
  BIN/fingerprint work and aborts if any field changes before request assembly,
  preventing even a second valid card or security code from being sent through
  a stale validation result.
- Removed raw-value access from the public package surface; integrators pass
  `PciFieldState` controllers directly and must not import internal helpers.
- Added automatic sensitive-field clearing on widget removal, app
  pause/detach, and successful tokenization, without claiming runtime-memory
  zeroization.
- Aligned release metadata with the assigned product ID and Android native
  fingerprint implementation.
- Removed the unlicensed iOS `DeviceFingerPrint.xcframework`, its DiskSpace API
  use, and identifier-based fallback. The iOS channel now returns an empty map
  so tokenization continues without enriched device signals.
- Hardened the publish archive exclusions while retaining documentation linked
  from the published README.
- Added `TEST-*` credential support, strict identifier/document validation,
  bounded caches and analytics queues, and sanitized public error messages.
- Added the public `analyticsEnabled` configuration option. Analytics remain
  enabled by default for native-SDK parity, while opted-out configurations
  neither enqueue nor send events.
- Added card-brand-aware 3/4-digit CVV handling. Unknown brands accept either
  length, BIN metadata narrows the field when available, and a brand change
  clears previously entered CVV data.
- Made API response parsing fail closed instead of fabricating valid-looking
  defaults for malformed payloads.

### Release disclosures

- The Mercado Pago privacy owner must confirm the permitted use and retention
  of analytics data, especially `transaction_amount`, before release.
- Android DeviceSDK contributes
  `com.google.android.gms.permission.AD_ID` to the merged manifest. Host apps
  must complete the applicable Play Data Safety, advertising-ID, consent, and
  privacy disclosures.
- iOS fingerprinting remains an explicit empty fallback until the native owner
  provides an approved, versioned artifact with licensing, privacy-manifest,
  signing, and provenance evidence.

## [0.1.0] - 2026-08-19

### Added

- Initial SDK foundation for MercadoPago integration on Flutter.
- `MercadoPagoSDK` singleton entry point with `initialize()` and `setNewConfiguration()`.
- `CoreMethods` low-level API:
  - `createTokenForNewCard()` with PCI field controllers.
  - `createTokenForSavedCard()` by card id + PCI security-code controller.
  - `getPaymentMethods(bin)`.
  - `getInstallments(bin, amount)`.
  - `getIssuers(paymentMethodId, bin)`.
  - `getIdentificationTypes()`.
- PCI-oriented input widgets:
  - `CardNumberField` with BIN detection and Luhn validation.
  - `SecurityCodeField` with configurable length.
  - `ExpirationDateField` with MM/YY auto-formatting.
- Device fingerprinting via Platform Channel (`mercadopago/fingerprint`), with
  Android DeviceSDK `4.0.1` and an empty compatibility fallback on iOS.
- Automatic analytics event tracking (fire-and-forget) to `/tracks`.
- Sealed `MercadoPagoResult<T>` type with `Success` and `Failure` variants.
- Support for the 7 Latin American countries where MercadoPago operates
  (ARG, BRA, CHL, COL, MEX, PER, URY).
- Example app demonstrating `CoreMethods` with PCI widgets.

### Changed (public API parity with native Android/iOS SDKs)

- `CoreMethods.createTokenForNewCard` now takes a typed `BuyerIdentification`
  (name + optional document) instead of loose `cardholderName`/`documentType`/
  `documentNumber` params.
- `CoreMethods.createTokenForSavedCard` now takes an optional
  `expirationDate` `PciFieldState` instead of raw month/year integers.
- Added the typed `BuyerIdentification` model.
- **CVV length** is validated against the card's `securityCodeLength` from a BIN
  lookup (exact match), not a fixed 3–4 range.
- `getPaymentMethods` now sends `processing_mode`; the CoreMethods getters emit
  their analytics tracks; `identity_document_type`
  is always present in tokenization tracks.

### Not applied

- Review point 11 (`product_id` as a header on the GET endpoints) was **not**
  applied: it contradicts the verified native contract, where `product_id` is a
  query param on GETs and absent on `identification_types`.

### Known limitations

- Integration tests against the real MercadoPago API are not part of the
  mandatory suite yet.
- Automatic network retry is not implemented.
- Native privacy release gates in the Unreleased section must be resolved or
  explicitly handled by the host application before store submission.
- The product ID is fixed to `CVQP49FTT60D1548Q56G`; it is sent as
  `X-Product-id` on card-token POSTs and as `product_id` on GET endpoints that
  require it.
