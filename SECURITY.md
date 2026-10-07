# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅ Current |

## Reporting a vulnerability

If you discover a security vulnerability in this SDK, **do not** open a
public GitHub issue. Instead, report it privately so it can be addressed
before disclosure.

**Contact**: sdk-security@mercadopago.com

Please include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested mitigation

We aim to acknowledge reports within 48 hours and provide a resolution
timeline within 7 business days.

## Security model

This SDK is designed to reduce unnecessary handling of card data:

- **Controller-based tokenization.** Applications pass `PciFieldState`
  controllers directly to `CoreMethods` instead of copying raw card values into
  strings.
- **The boundary is a Dart library, not an annotation.** Every piece of code
  that can observe a raw PAN or CVV — the field state, the three input widgets,
  the validators and the request assembly — lives in the single `lib/src/pci/`
  library, and the value is private to it. **No symbol in the package,
  exported or not, returns that value**, so the boundary is enforced by the Dart
  compiler rather than by convention. Importing `lib/src/…` no longer yields an
  accessor to bypass, which is the difference from an `@internal` annotation:
  that is only an analyzer hint and a consuming app can ignore it.
- **What this does not cover.** It is not an isolated native secure element and
  it does not certify the application as PCI DSS compliant. The value still
  lives in the Dart heap, so a debug build, a fork of the package, an attached
  debugger, or an integrator collecting card data in their own `TextField`
  remain outside the boundary. Moving capture into native secure fields
  (Platform Views), so the value never exists in Dart at all, is tracked as
  post-v0.1.0 work.
- **Memory lifecycle.** Field values are cleared when their widget is removed,
  when the app enters `inactive`, `paused`, or `detached`, when the owning application disposes
  the controller, and after successful tokenization. Validation/network
  failures retain values for correction or retry. Clearing updates the logical
  Dart value; it is not a byte-level memory-zeroization guarantee. The SDK does
  not persist card data or tokens.
- **Screen capture.** The host application must protect card-entry routes from
  screenshots and recent-app thumbnails. Use Android `FLAG_SECURE`. On iOS,
  obscure card UI before the scene becomes inactive and define a response to
  active screen capture; iOS cannot generally prevent screenshots. The SDK's
  lifecycle clearing reduces exposure but is not a screenshot-control API.
- **Direct tokenization.** The SDK sends the required card data to
  MercadoPago's HTTPS tokenization endpoint and returns a short-lived token.
- **Device fingerprinting.** Android DeviceSDK collects platform-dependent
  device and application signals for fraud prevention. Native failures produce
  no device payload. The iOS channel deliberately returns an empty payload and
  collects no fallback identifiers. Android signal fields can evolve with the
  native dependency, so integrators must review merged permissions and privacy
  notices.

## SDK analytics and privacy

Analytics are enabled by default for native-SDK parity and can be disabled by
passing `analyticsEnabled: false` to `MercadoPagoSDK.initialize` and to each
subsequent `setNewConfiguration` call. A disabled analytics service neither
queues nor sends events.

When enabled, the SDK sends fire-and-forget HTTPS requests to Mercado
Libre/Mercado Pago's `https://api.mercadolibre.com/tracks` endpoint for
operational and product measurement. Payloads contain event IDs, paths and
times; the public key; locale/debug/SDK/site/platform/OS context; an in-memory
random process UID and session UUID; and operation metadata. Depending on the
operation, metadata can include saved-card status, document **type**, payment
method/issuer identifiers, card brand, security-code length, error category,
and installment `transaction_amount`. The current analytics schema does not
send PAN, CVV, expiration date, cardholder name, or identification number.

The SDK does not persist analytics events or identifiers. It uses a bounded
in-memory queue of at most 20 pending events, serial delivery, and a
five-second HTTP timeout. Analytics failures and queue-capacity drops are
discarded and do not fail the payment flow.

The Mercado Pago privacy owner must confirm the permitted use and retention of
all analytics data before release, especially `transaction_amount`. No
server-side retention period is asserted here. The host application remains
responsible for consent, notices, and applicable store privacy declarations.

## Native privacy release actions

### iOS

The iOS release does not bundle a fingerprint framework. Its compatibility
channel returns an empty payload, so it does not collect device, location, or
fallback application identifiers for fingerprinting. The release owner must
still inspect the final application archive and privacy report because the host
application and other dependencies can introduce additional declarations.

### Android

The DeviceSDK dependency contributes
`com.google.android.gms.permission.AD_ID` to the merged Android manifest. The
plugin itself does not request optional runtime permissions, but the host app
must inspect its final manifest and accurately complete Google Play Data
Safety, advertising-ID policy, consent, and privacy disclosures. Documentation
must not claim that fingerprinting excludes personal or location-related data.

Using the SDK does not by itself make an application PCI DSS compliant. The
integrator remains responsible for the complete application and backend data
flow, diagnostics, analytics, access controls, and compliance assessment.

See the [README security section](README.md#security) for full details.
