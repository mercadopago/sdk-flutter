# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added

- Initial SDK foundation for MercadoPago integration on Flutter.
- `MercadoPagoSDK` singleton entry point with `initialize()` and `setNewConfiguration()`.
- `CoreMethods` low-level API:
  - `createToken()` for new cards (with full card data).
  - `createToken()` for saved cards (by card id + security code).
  - `getPaymentMethods(bin)`.
  - `getInstallments(bin, amount)`.
  - `getIssuers(paymentMethodId, bin)`.
  - `getIdentificationTypes()`.
- PCI-compliant input widgets:
  - `CardNumberField` with BIN detection and Luhn validation.
  - `SecurityCodeField` with configurable length.
  - `ExpirationDateField` with MM/YY auto-formatting.
- Hosted checkout UI:
  - `MercadoPagoCheckout.forCardSave()` flow.
  - `MercadoPagoCheckout.forCardTransaction()` flow with installment selection and review.
  - `MPCheckoutAppearance` for light/dark theming.
- Device fingerprinting via Platform Channel (`mercadopago/fingerprint`).
- Automatic analytics event tracking (fire-and-forget) to `/tracks`.
- Sealed `MercadoPagoResult<T>` type with `Success`, `Failure`, and `Cancelled` variants.
- Support for the 7 Latin American countries where MercadoPago operates
  (ARG, BRA, CHL, COL, MEX, PER, URY).
- Example app demonstrating all three integration paths.

### Changed (public API parity with native Android/iOS SDKs)

- `MercadoPagoCheckout.forCardTransaction` now requires an `MPOrder(orderId,
  clientToken)`; `amount` and `payerEmail` were removed — the amount is resolved
  server-side from the order (matching the native SDKs).
- Payment-method configuration moved to a sealed `MPPaymentMethodConfig.card(...)`
  supplied via `setPaymentMethodConfiguration([...])`, carrying `excludedTypes`,
  `excludedBrands` and an `MPInstallment(minInstallments, maxInstallments)` range.
- `CoreMethods.createTokenForNewCard` now takes a typed `BuyerIdentification`
  (name + optional document) instead of loose `cardholderName`/`documentType`/
  `documentNumber` params.
- `CoreMethods.createTokenForSavedCard` now takes an optional
  `expirationDate` `PciFieldState` instead of raw month/year integers.
- `MPCheckoutAppearance` now uses `themeMode` (Flutter's `ThemeMode`
  system/light/dark, default `system` — adaptive) instead of a fixed `brightness`.
- Added typed models `MPOrder`, `MPInstallment`, `MPPayer` and
  `BuyerIdentification`.

### Known limitations

- `X-Product-id` header uses a placeholder (`MP_FLUTTER_SDK_001`) pending official assignment.
- iOS `DeviceFingerPrint.xcframework` integration deferred until binary is provided; channel returns empty data without errors.
