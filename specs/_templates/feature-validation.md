# Feature Validation: {Feature Name}

> Feature ID: {NNN}
> Phase: v{X.Y}

## Automated checks
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `flutter test --coverage` meets threshold
- [ ] `flutter build apk` compiles (example/)
- [ ] `flutter build ios --no-codesign` compiles (example/)

## Manual verification
- [ ] {Step-by-step manual check}

## Test coverage
- [ ] {What is tested}
- [ ] {Edge cases}
- [ ] {Error paths}

## Spec alignment
- [ ] Implementation matches plan.md groups
- [ ] All requirements.md items met
- [ ] No undocumented deviations

## Review checklist
- [ ] No secrets committed
- [ ] Public API exported only via `lib/mercadopago_sdk.dart`
- [ ] README / docs updated if user-facing
- [ ] CHANGELOG.md updated
- [ ] No TODOs or FIXMEs in lib/
