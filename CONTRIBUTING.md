# Contributing to mercadopago_flutter_sdk

Thank you for your interest in contributing. This guide covers how to set up
the project locally, run tests, and submit a pull request.

---

## Development setup

```bash
git clone git@github.com:mercadopago/sdk-flutter.git
cd sdk-flutter
flutter pub get
```

---

## Running tests

```bash
# Unit and widget tests
flutter test

# Static analysis (must be 0 issues)
flutter analyze

# Run the example app
cd example && flutter run
```

All pull requests must pass both `flutter analyze` (0 issues) and
`flutter test` (all tests green) before they can be merged.

---

## Pull request checklist

- [ ] `flutter analyze` passes with 0 issues
- [ ] `flutter test` passes — all existing tests green
- [ ] New behavior is covered by tests
- [ ] Public API changes are reflected in the DartDoc comments
- [ ] `CHANGELOG.md` updated with a summary of the change
- [ ] No raw card data is introduced in any code path (PCI rule)
- [ ] No `Co-Authored-By: AI` or similar lines in commit messages

---

## Commit style

Use conventional commit prefixes:

```
feat:     new capability
fix:      bug fix
docs:     documentation only
refactor: no behavior change
test:     adding or fixing tests
chore:    build, deps, config
```

---

## Security

If your contribution touches tokenization, PCI widgets, or fingerprinting,
review the [security model](README.md#security) before opening the PR.

Do **not** introduce `rawValue` reads in any integrator-facing code path.

---

## Reporting bugs

Open an issue at https://github.com/mercadopago/sdk-flutter/issues.
Include: Flutter version, reproduction steps, and the full error output.
