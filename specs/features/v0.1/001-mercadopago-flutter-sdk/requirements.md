# Feature Requirements: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1
> Status: implemented; release validation and native privacy blockers remain

## Functional requirements

- [ ] Accessing SDK services before `MercadoPagoSDK.initialize()` throws
  `SDKNotInitializedError`.
- [ ] Calling `initialize()` twice throws `SDKAlreadyInitializedError`; changing
  credentials uses `setNewConfiguration()`.
- [ ] Valid `TEST-*` and `APP_USR-*` public keys are accepted; malformed keys
  throw `SDKInvalidPublicKeyError`, and
  unsupported country codes throw `SDKInvalidCountryError`.
- [ ] `initialize()` and `setNewConfiguration()` each create a new
  `Meli-Session-id` UUID and configuration changes clear the in-memory GET
  cache.
- [ ] Every CoreMethods API request sends `Meli-Session-id`, `SDK-version`, and
  `User-Agent`, and authenticates with `public_key` in the query string.
- [ ] Card-token POSTs send the assigned product ID in `X-Product-id`.
  Applicable CoreMethods GETs send it as `product_id`; identification-type GETs
  omit it.
- [ ] `getPaymentMethods`, `getInstallments`, and `getIssuers` accept exactly
  eight numeric BIN digits and reject invalid input before network access.
- [ ] `getPaymentMethods` accepts `ProcessingMode`, defaults to `aggregator`,
  and propagates `gateway` to the HTTP request. An integration must use the
  same mode when it subsequently calls `getInstallments`.
- [ ] Public payment-method, installment, and issuer models preserve the native
  fields required by aggregator and gateway flows, including merchant account,
  agreements, payer costs, issuer, thumbnails, labels, and card/BIN metadata.
- [ ] New-card tokenization validates Luhn, expiration, and the security-code
  length required by the detected payment method before POSTing.
- [ ] Saved-card tokenization accepts a required security-code controller and
  an optional expiration controller.
- [ ] Tokenization captures non-sensitive PCI revision counters before
  asynchronous BIN/fingerprint work and aborts before the HTTP request when
  any supplied field changes, even when the replacement data is also valid.
- [ ] Native fingerprint data is sent under `device` only when collection
  returns a non-empty payload. A missing or failing Platform Channel must not
  prevent tokenization.
- [ ] Android forwards `DeviceSDK.info` when collection succeeds and returns an
  empty map on null/failure; it must not fabricate a Flutter-specific fallback
  schema. iOS remains an explicit empty fallback until an approved native
  artifact is available.
- [ ] Sensitive card values stay in memory and are never persisted or logged by
  the SDK. Widgets clear values on removal and app pause/detach; successful
  tokenization clears supplied controllers. The application still owns each
  `PciFieldState` and must call `dispose()`. These are logical clearing
  guarantees, not byte-level memory zeroization.
- [ ] CoreMethods HTTP calls time out after 30 seconds and eligible GET results
  use an in-memory five-minute cache.
- [ ] CoreMethods operations return `Future<MercadoPagoResult<T>>`; SDK lifecycle
  misuse remains an explicit `SDKError` exception.
- [ ] `flutter analyze` completes without warnings or errors.
- [ ] Line coverage is at least 80% independently for `lib/src/domain/`,
  `lib/src/core_methods/`, and `lib/src/pci/`.

## Constraints

- No third-party dependency-injection or state-management framework in the SDK.
- No persistent card-data storage (`SharedPreferences`, Keychain,
  `flutter_secure_storage`, Hive, files, or databases).
- No `dart:mirrors` and no logging of card number, security code, or expiration.
- Device fingerprinting delegates to Android DeviceSDK through the
  `mercadopago/fingerprint` Platform Channel. The iOS implementation returns
  an empty map; Dart must not recreate native signal collection.
- The public API is exported only through `lib/mercadopago.dart`; `lib/src/`
  remains implementation detail.
- The public package barrel exposes no raw-value getter. Integrator code must
  not import `lib/src/` helpers to bypass it. This design reduces accidental
  exposure but is not an isolated secure element and does not certify the host
  application as PCI DSS compliant.

## Key decisions

| Decision | Selected approach | Rationale |
|----------|-------------------|-----------|
| HTTP client | `package:http` | Small dependency footprint for fixed endpoints. |
| Sensitive field state | `PciFieldState` + Flutter widgets | Lets the supported flow pass controllers directly instead of copying strings. |
| Result type | Sealed `MercadoPagoResult<T>` | Exhaustive success/failure handling in Dart 3. |
| Dependency injection | Manual bootstrap in `MercadoPagoSDK` | Avoids imposing an application framework. |
| Fingerprinting | Platform Channel to Android DeviceSDK; empty iOS fallback | Preserves Android fraud signals without bundling an unreviewed iOS binary. |

## Constants and transport contract

| Constant | Value | Use |
|----------|-------|-----|
| Product ID | `CVQP49FTT60D1548Q56G` | POST header or applicable GET query parameter. |
| SDK version | `0.1.0` | Must stay synchronized with `pubspec.yaml`. |
| API base URL | `https://api.mercadopago.com` | CoreMethods API. |
| Tracks URL | `https://api.mercadolibre.com/tracks` | Best-effort analytics. |

The iOS channel returns an empty map and the podspec bundles no fingerprint
framework. Android resolves `com.mercadolibre.android.device:sdk:4.0.1` from
the MercadoLibre Artifactory.
The plugin manifest declares `INTERNET` and `ACCESS_NETWORK_STATE`; it does not
request optional runtime permissions. Android DeviceSDK contributes
`com.google.android.gms.permission.AD_ID` through the merged manifest, so the
host owns Play Data Safety, advertising-ID, consent, and privacy disclosures.
Integrators must inspect final merged manifests because native signal sets and
transitive manifests can evolve.

## Release requirements

- The reproducible local gate `./tool/verify.sh` uses Flutter `3.44.2` or a
  compatible newer version. GitHub Actions are unavailable under the
  organization's security policy, so successful output is attached to the PR.
- The example must build as an Android release APK and an unsigned iOS release.
- `dart pub publish --dry-run` must pass from a clean checkout.
- The final iOS application archive and privacy report must be reviewed. This
  SDK release performs no iOS fingerprint collection and must not add a binary
  or identifier fallback without licensing and privacy review.
- Android release review must verify the merged `AD_ID` permission and complete
  the applicable Play Data Safety and advertising-ID disclosures.
- The publish archive must exclude caches, build output, internal AI context,
  and feature specs while retaining README-linked release/security documents.
- Real-API or device integration tests require isolated test credentials and
  remain opt-in until a secure CI environment is defined.
- Host applications must protect card-entry routes from screenshots and
  recent-app previews (`FLAG_SECURE` on Android; an inactive-scene privacy
  overlay and an explicit active-capture policy on iOS).
