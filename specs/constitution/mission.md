# Mission

## Purpose

The MercadoPago Flutter SDK provides a secure, idiomatic Flutter integration layer over the MercadoPago payment platform. It enables mobile developers to add card tokenization, payment method detection, installment selection, and a complete hosted checkout UI to any Flutter application — without handling raw card data directly.

## Target audience

Flutter developers building consumer-facing payment flows in Latin America. The SDK targets developers who want either a low-code hosted checkout or full programmatic control via CoreMethods.

## Supported countries

MercadoPago operates in 7 Latin American markets and the SDK is supported in all of them:
Argentina (ARG), Brazil (BRA), Chile (CHL), Colombia (COL), Mexico (MEX), Peru (PER), Uruguay (URY).

## In scope

- Card tokenization for new and saved cards
- Payment method lookup by BIN (brand, card type, security code config)
- Installment and issuer retrieval
- Identification type lookup per country
- PCI-compliant card input widgets (card number, CVV, expiration date)
- Hosted checkout UI flows: CardSave and CardTransaction
- Device fingerprinting for fraud prevention (via Platform Channel to native SDKs)
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
