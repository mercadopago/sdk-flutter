# Tech Stack

## Language & runtime

- **Dart 3.x** (null-safety required, sealed classes, pattern matching)
- **Flutter 3.10+** — mobile targets: iOS 13+, Android API 23+
- Package type: **Flutter plugin** (not a pure Dart package — uses Platform Channels for fingerprinting)

## Package manager

- `pub` via `flutter pub`
- Lock file: `pubspec.lock` (committed)
- BOM: `pubspec.yaml`

## Core dependencies (production)

| Package | Purpose |
|---------|---------|
| `flutter` (SDK) | Widget framework |
| `http` or `dio` | HTTP client (decision in feature 001 requirements) |
| `uuid` | UUID v4 for session ID generation |

> No third-party state management or DI framework in production code.
> Internal architecture uses manual dependency injection.

## Dev / test dependencies

| Package | Purpose |
|---------|---------|
| `flutter_test` (SDK) | Unit and widget tests |
| `flutter_lints` ^3.0 | Lint rules |
| `mockito` or `mocktail` | Mocking in unit tests |

## Key commands

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Analyze (lint + type check)
flutter analyze

# Format
dart format .

# Build example app (Android)
cd example && flutter build apk

# Build example app (iOS)
cd example && flutter build ios
```

## Project structure

```
lib/
  src/
    core/           # HTTP client, session, configuration
    domain/         # Models, interfaces, use cases
    core_methods/   # Tokenization, paymentMethods, installments, issuers
    checkout/       # Hosted checkout UI flows
    components/     # PCI input widgets
    analytics/      # Event tracking
    fingerprint/    # Platform Channel bridge
  mercadopago_sdk.dart  # Public API surface (barrel export)
example/            # Minimal Flutter app demonstrating the SDK
test/               # Mirror of lib/src/
android/            # Platform Channel native (Kotlin)
ios/                # Platform Channel native (Swift)
specs/              # SDD documentation
```

## Conventions

- Public API exported only via `lib/mercadopago_sdk.dart`
- All `src/` internals are private (no direct imports from outside)
- Errors modeled as sealed classes: `MercadoPagoResult<T>` with `.success`, `.error`, `.userCancelled`
- Card data (number, CVV, expiry) lives only in `PciFieldState` — never serialized, never logged
- `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`
