# Tech Stack

## Language & runtime

- **Dart 3.x** (null-safety required, sealed classes, pattern matching)
- **Flutter 3.44.2+** — verified mobile targets: iOS 13+, Android API 23+
- Package type: **Flutter plugin** (not a pure Dart package — uses Platform Channels for fingerprinting)

## Package manager

- `pub` via `flutter pub`
- Lock file: `pubspec.lock` (committed)
- BOM: `pubspec.yaml`

## Core dependencies (production)

| Package | Purpose |
|---------|---------|
| `flutter` (SDK) | Widget framework |
| `http` | HTTP client |
| `uuid` | UUID v4 for session ID generation |

> No third-party state management or DI framework in production code.
> Internal architecture uses manual dependency injection.

## Dev / test dependencies

| Package | Purpose |
|---------|---------|
| `flutter_test` (SDK) | Unit and widget tests |
| `flutter_lints` ^3.0 | Lint rules |

## Key commands

```bash
# Complete local pull-request gate, including native builds supported by host
./tool/verify.sh

# Faster development loop; not sufficient as final merge evidence
./tool/verify.sh --without-native

# Run the complete gate with only one native target
./tool/verify.sh --android-only
./tool/verify.sh --ios-only
```

GitHub Actions are unavailable under the organization's security policy.
`tool/verify.sh` is therefore the reproducible pull-request gate and must run
with Flutter `3.44.2` or a compatible newer version. It enforces at least 80%
line coverage independently for `lib/src/domain/`,
`lib/src/core_methods/`, and `lib/src/pci/`. Android and iOS release-build
evidence must come from correctly provisioned hosts before merge.

## Project structure

```
lib/
  src/
    core/           # HTTP client, session, configuration
    domain/         # Models and repository interfaces
    core_methods/   # Tokenization, paymentMethods, installments, issuers
    pci/            # PCI field state, widgets, validation, token assembly
    analytics/      # Event tracking
    fingerprint/    # Platform Channel bridge
  mercadopago.dart  # Public API surface (barrel export)
example/            # Minimal Flutter app demonstrating the SDK
test/               # Mirror of lib/src/
android/            # Platform Channel native (Kotlin)
ios/                # Platform Channel native (Swift)
specs/              # SDD documentation
```

## Conventions

- Public API exported only via `lib/mercadopago.dart`
- All `src/` internals are private (no direct imports from outside)
- Errors modeled as sealed classes: `MercadoPagoResult<T>` with `Success` and `Failure`
- The supported public flow passes `PciFieldState` directly to tokenization;
  values are serialized only for the token request and are never persisted or
  logged by the SDK. This reduces exposure but is not a complete application
  compliance boundary.
- `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`
