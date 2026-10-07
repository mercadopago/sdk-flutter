# Feature Validation: MercadoPago Flutter SDK

> Feature ID: 001
> Phase: v0.1
> A checkbox is completed only after the corresponding CI or manual evidence is
> recorded; documentation alone is not evidence of a passing check.

## Automated release gates

The canonical gate is `./tool/verify.sh`. GitHub Actions are unavailable under
the organization's security policy, so successful local output and native
build evidence are attached to the pull request.

- [ ] Dart sources in `lib/`, `test/`, and `example/lib/` pass
  `dart format --output=none --set-exit-if-changed`.
- [ ] Package and example pass `flutter analyze` on the declared and
  native-build-verified minimum, Flutter `3.44.2`.
- [ ] Unit/widget tests pass on the pinned Flutter `3.44.2` toolchain.
- [ ] `flutter test --coverage` reports at least 80% line coverage separately
  for `lib/src/domain/`, `lib/src/core_methods/`, and `lib/src/pci/`.
- [ ] `flutter build apk --release` succeeds in `example/` on Linux with JDK 17.
- [ ] `flutter build ios --release --no-codesign` succeeds in `example/` on
  macOS.
- [ ] `dart pub publish --dry-run` succeeds from a clean checkout.

## SDK lifecycle

- [ ] Access before initialization throws `SDKNotInitializedError`.
- [ ] An invalid public key throws `SDKInvalidPublicKeyError`.
- [ ] An unsupported country throws `SDKInvalidCountryError`.
- [ ] A second `initialize()` throws `SDKAlreadyInitializedError`.
- [ ] `setNewConfiguration()` rotates the session UUID, replaces clients, and
  invalidates the previous GET cache.
- [ ] `dispose()` returns the singleton to an uninitialized state.

## CoreMethods: tokenization

- [ ] A valid new card returns `Success<CardToken>` with a non-empty token.
- [ ] Luhn failure, malformed expiration, expired card, and incorrect
  payment-method security-code length return `Failure` before the token POST.
- [ ] `BuyerIdentification.name` is required; document type/number are included
  only when supplied.
- [ ] Saved-card tokenization accepts a required security-code controller and
  optional MMYY expiration controller.
- [ ] Repository serialization contains only the endpoint's expected keys and
  never emits card values to logs or analytics.
- [ ] Editing any card, expiration, or security-code field while BIN metadata
  or fingerprint collection is pending aborts before tokenization, including a
  change from one otherwise-valid card to another.

## CoreMethods: lookups

- [ ] Payment-method, installment, and issuer lookup accept exactly eight
  numeric BIN digits.
- [ ] Empty, shorter-than-eight, longer-than-eight, and non-numeric BIN values
  return `Failure` without a network request.
- [ ] `getPaymentMethods` defaults to `aggregator` and sends an explicitly
  selected `gateway` mode; the same mode can be used for installments.
- [ ] Canonical iOS fixtures with empty `merchant_account_id` or `thumbnail`
  parse successfully, normalizing nullable blank fields without turning a
  valid native response into `UnknownError`.
- [ ] Public models retain native gateway data, including agreements,
  installment-rate collector, reimbursement rate, merchant account, issuer,
  payer costs, labels, thumbnails, and card/BIN metadata.
- [ ] Installment amounts must be greater than zero.
- [ ] Identification-type lookup returns the country-specific typed list.
- [ ] Repository/network failures are mapped to the correct
  `MercadoPagoError.location`.

## Sensitive input widgets

- [ ] `CardNumberField` formats digits and emits BIN at digit eight without
  inferring completion from an ambiguous PAN prefix; `CoreMethods` performs
  final length and Luhn validation on submit.
- [ ] `SecurityCodeField` obscures input, accepts 3 or 4 digits while the brand
  is unknown, honors a configured exact length, and clears the CVV when that
  card-specific length changes.
- [ ] `ExpirationDateField` formats MM/YY and rejects invalid or expired dates,
  including current-month/year boundaries.
- [ ] Fields filter non-digits, respect disabled state, and expose appropriate
  semantics without revealing sensitive values.
- [ ] Widget removal, app pause/detach, explicit controller disposal, and
  successful tokenization clear retained values; validation/network failures
  retain them for correction or retry. Tests assert logical clearing without
  claiming byte-level memory zeroization.
- [ ] Public examples do not import `lib/src/` helpers; the package API boundary
  is documented as exposure reduction, not absolute technical isolation.
- [ ] The example and host integration guide document screen-capture
  protection for Android and iOS card-entry routes.

## Device fingerprinting

- [ ] Android returns a map on successful native collection; iOS returns an
  empty map deterministically.
- [ ] Android forwards `DeviceSDK.info` on success and returns an empty map on
  null/failure; it never fabricates a second platform/app schema.
- [ ] Missing channel, `PlatformException`, null, or malformed Dart response
  degrades to an empty device payload without failing tokenization.
- [ ] A non-empty device payload is included under `device`; an empty payload
  is omitted.
- [ ] Final Android/iOS manifests and privacy disclosures are reviewed for the
  actual native dependency versions and collected data before release.
- [ ] The iOS release archive contains no fingerprint XCFramework and the
  compatibility channel returns no device identifiers.
- [ ] Android release review records the merged
  `com.google.android.gms.permission.AD_ID` permission and completes Play Data
  Safety, advertising-ID, consent, and privacy disclosures. The plugin itself
  requests no optional runtime permissions.

## Analytics

- [ ] Initialization and CoreMethods events are best effort and never change
  the primary operation result.
- [ ] Tracking failures and timeouts are swallowed without sensitive values in
  event data.

## HTTP contract

- [ ] Every CoreMethods API request includes a valid `Meli-Session-id`,
  `SDK-version`, `User-Agent`, and `public_key` query parameter.
- [ ] `POST /v1/card_tokens` includes the assigned product ID in the
  `X-Product-id` header and does not add the `product_id` query parameter.
- [ ] Payment-method, installment, and issuer GETs use the assigned product ID
  in the `product_id` query parameter and do not send `X-Product-id`.
- [ ] Identification-type GETs omit both `product_id` and `X-Product-id`.
- [ ] GET cache hit, TTL expiration, explicit cache clearing, timeout,
  transport failure, malformed JSON, and non-2xx responses are tested.

## Coverage inventory

- [ ] `MercadoPagoSDK` lifecycle and configuration replacement.
- [ ] `CoreMethods` happy paths, local validation, and repository failures.
- [ ] Repository request serialization and defensive DTO parsing.
- [ ] `ApiClient` headers, query contract, cache, timeout, and error mapping.
- [ ] `FingerprintService` success and graceful-fallback branches.
- [ ] PCI widget callbacks, validation boundaries, semantics, and disposal.
- [ ] Android host and iOS XCTest coverage for the Platform Channel contract.
- [ ] Opt-in `integration_test` flow with isolated MercadoPago test credentials.

## Packaging and documentation

- [ ] The pub archive includes `README.md`, `CHANGELOG.md`, `LICENSE`,
  `CONTRIBUTING.md`, and `SECURITY.md`.
- [ ] The archive excludes caches, local configuration, internal AI context,
  and feature specs.
- [ ] Public SDD files contain no secrets, restricted links, customer data, or
  unpublished internal discussion, and remain aligned with the implementation.
- [ ] README, changelog, podspec, package metadata, and AI context describe only
  CoreMethods, PCI-oriented widgets, tokenization, and fingerprinting.
- [ ] No documentation claims that card values are technically inaccessible or
  that using the SDK alone certifies PCI DSS compliance.
- [ ] No secret or real credential is present in source, tests, examples, or
  publish archive.
- [ ] Package version and `kSdkVersion` are synchronized for the release.
