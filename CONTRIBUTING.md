# Contributing to mercadopago

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
./tool/verify.sh
```

GitHub Actions are unavailable under the organization's security policy, so
the script is the reproducible pull-request gate. It checks formatting,
analyzes the package and example, runs all tests, enforces the focused 80%
coverage thresholds, validates the pub.dev archive, and builds every native
target supported by the host. Attach the successful output to the pull request
as review evidence.

For faster iteration, `./tool/verify.sh --without-native` skips platform
builds. It is not sufficient as final merge evidence: Android and iOS release
builds must both be provided from correctly provisioned hosts before merge.

---

## Pull request checklist

- [ ] `./tool/verify.sh` passes and its output is attached to the PR
- [ ] Android and iOS release-build evidence is included
- [ ] Focused coverage remains at or above 80% for domain, Core Methods, and PCI
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

**The PCI boundary is a single Dart library.** Everything that can observe a
raw PAN or CVV lives in `lib/src/pci/`, whose value is private to that library
and therefore enforced by the compiler. When contributing there:

- Do **not** add a public top-level symbol that returns, or hands to a
  caller-supplied sink, a raw card value. `test/pci/pci_public_surface_test.dart`
  fails if a new public symbol appears — that guard is deliberate, so extend the
  allowlist only with a justification in the PR.
- Part files cannot declare their own imports; add them to `lib/src/pci/pci.dart`.
- An `@internal` annotation is **not** a boundary. It is an analyzer hint that a
  consuming app can ignore with a single `// ignore:` comment, so it must never
  be the only thing standing between application code and a card value.

---

## Reporting bugs

Open an issue at https://github.com/mercadopago/sdk-flutter/issues.
Include: Flutter version, reproduction steps, and the full error output.
