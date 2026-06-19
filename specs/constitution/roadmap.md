# Roadmap

## v0.1 — Core SDK Foundation

**Goal**: Deliver a fully functional SDK covering all CoreMethods + PCI fields + Checkout UI.
This is the initial complete implementation — the SDK ships as useful from v0.1.

| ID | Feature | Status | Branch |
|----|---------|--------|--------|
| 001 | mercadopago-flutter-sdk | accepted | feature/001-mercadopago-flutter-sdk |

### v0.1 includes
- Project scaffold (pubspec.yaml, folder structure, CI stub)
- Core HTTP infrastructure (headers, session UUID, timeout, error mapping)
- Domain layer (models, interfaces, use cases)
- CoreMethods: tokenization (new + saved card), paymentMethods, installments, issuers, identificationTypes
- PCI Fields: CardNumberField, SecurityCodeField, ExpirationDateField
- Checkout UI: CardSave flow, CardTransaction flow
- Device fingerprinting via Platform Channel
- Analytics auto-tracking
- Example app

---

## v0.2 — Hardening & DX

**Goal**: Production readiness — documentation, error messages, retry logic, edge cases.

| ID | Feature | Status |
|----|---------|--------|
| 002 | tbd | planned |

### v0.2 candidates
- Retry with exponential backoff for network errors
- Full API reference documentation (dartdoc)
- Pub.dev publishing setup
- Integration tests (flutter_driver or integration_test package)

---

## v0.3 — Extended Features

**Goal**: Close gap with native SDKs on platform-specific capabilities.

| ID | Feature | Status |
|----|---------|--------|
| 003 | tbd | planned |

### v0.3 candidates
- ESC (Encrypted Security Code) for saved cards
- Configurable checkout appearance / theming
- Apple Pay support (iOS only, via Platform Channel)

---

## Version policy

- `0.x.y` = pre-release (no stability guarantees)
- `1.0.0` = first stable release (after v0.3 is complete and pub.dev published)
