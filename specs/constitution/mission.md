# Mission

## Purpose

The MercadoPago Flutter SDK provides an idiomatic Flutter integration layer over the MercadoPago payment platform. It enables mobile developers to add card tokenization, payment method detection, installment lookup, and controller-based sensitive card fields while reducing the need for application code to handle raw values directly. The SDK does not by itself certify an application as PCI DSS compliant.

## Target audience

Flutter developers building consumer-facing payment flows in Latin America who need full programmatic control through `CoreMethods` and PCI widgets.

## Supported countries

MercadoPago operates in 7 Latin American markets and the SDK is supported in all of them:
Argentina (ARG), Brazil (BRA), Chile (CHL), Colombia (COL), Mexico (MEX), Peru (PER), Uruguay (URY).

## In scope

- Card tokenization for new and saved cards
- Payment method lookup by BIN (brand, card type, security code config)
- Installment and issuer retrieval
- Identification type lookup per country
- PCI-oriented card input widgets (card number, CVV, expiration date)
- Android device fingerprinting for fraud prevention (via Platform Channel),
  with an empty compatibility fallback on iOS
- Automatic analytics event tracking
- Device session ID (`MPExtended` equivalent)

## Out of scope

- Payment processing / backend payment creation (token is handed to the integrator's backend)
- Subscription / recurring payments
- QR code payments
- MercadoPago Wallet flows
- Apple Pay (iOS-only feature; may be added in a future phase)
- Web / desktop Flutter targets
- Server-to-server API calls (this is a client-side SDK only)
