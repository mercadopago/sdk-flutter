# MercadoPago Flutter SDK example

This app demonstrates card tokenization with `CoreMethods` and the SDK-managed
PCI widgets. It does not create a payment: after tokenization, a real
integration sends the opaque token to its backend.

## Requirements

- Flutter 3.44.2 or later
- Android API 23+ or iOS 13+
- A MercadoPago `TEST-*` public key for testing

## Run

Get test credentials from the
[MercadoPago developer panel](https://www.mercadopago.com/developers/panel/app),
then provide the public key at build time with `--dart-define`:

```bash
flutter pub get
flutter run \
  --dart-define=MERCADOPAGO_PUBLIC_KEY=TEST-your-public-key \
  --dart-define=MERCADOPAGO_COUNTRY_CODE=ARG
```

The country defaults to `ARG`. Supply another supported ISO 3-letter code with
`MERCADOPAGO_COUNTRY_CODE`: `ARG`, `BRA`, `CHL`, `COL`, `MEX`, `PER`, or
`URY`.

Use testing credentials and MercadoPago test cards in this example. Do not use
a production `APP_USR-*` public key or real cardholder data for local testing.
Do not add credentials to source control. A public key is designed for
client-side use, but an access token is secret and must never be embedded in a
Flutter app.

Enter card data only through `CardNumberField`, `ExpirationDateField`, and
`SecurityCodeField`. Do not log, persist, or read raw card numbers or security
codes outside those SDK-managed fields. Treat the returned card token as
sensitive: send it to your backend and do not log or persist it on the device.
The Android example enables `FLAG_SECURE` so card-entry screens are excluded
from screenshots and recent-app thumbnails. On iOS, production hosts must
obscure the route before the scene becomes inactive and define their active
screen-capture response; the platform cannot generally prevent screenshots.

For Android repository configuration, platform privacy requirements, the iOS
release constraint, and the complete API guide, see the
[package README](../README.md).
