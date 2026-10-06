# Roadmap

## v0.1 — Core SDK Foundation

**Goal**: Deliver a fully functional SDK covering CoreMethods and PCI fields.
This is the initial implementation; store publication remains subject to the
native privacy blockers below.

| ID | Feature | Status | Branch |
|----|---------|--------|--------|
| 001 | core-methods-pci-widgets | implemented; local/native evidence required | — |

### v0.1 includes
- Project scaffold, package metadata, and a reproducible local verification gate
- Core HTTP infrastructure (headers, session UUID, timeout, error mapping)
- Domain layer (models and repository interfaces)
- CoreMethods: tokenization (new + saved card), paymentMethods, installments, issuers, identificationTypes
- PCI Fields: CardNumberField, SecurityCodeField, ExpirationDateField
- Android device fingerprinting via Platform Channel; empty iOS fallback
- Analytics auto-tracking
- Example app

### Release actions

- Verify the final iOS archive and privacy report. Enriched iOS fingerprinting
  is deliberately disabled and must not be reintroduced without licensing and
  privacy review.
- Complete Android host review for the transitive `AD_ID` permission, including
  Play Data Safety, advertising-ID, consent, and privacy disclosures.

---

## v0.2 — Hardening & DX

**Goal**: Production readiness — documentation, error messages, retry logic, edge cases.

| ID | Feature | Status |
|----|---------|--------|
| 002 | tbd | planned |

### v0.2 candidates
- Retry with exponential backoff for network errors
- Full API reference documentation (dartdoc)
- Pub.dev publishing and release credentials (dry-run is already gated locally)
- Integration tests (`integration_test` package)

---

## v0.3 — Extended Features

**Goal**: Close gap with native SDKs on platform-specific capabilities.

| ID | Feature | Status |
|----|---------|--------|
| 003 | tbd | planned |

### v0.3 candidates
- ESC (Encrypted Security Code) for saved cards
- Apple Pay support (iOS only, via Platform Channel)

---

## Version policy

- `0.x.y` = pre-release (no stability guarantees)
- `1.0.0` = first stable release (after v0.3 is complete and pub.dev published)
