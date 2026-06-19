# Spec-Driven Development (SDD)

This project follows a Spec-Driven Development workflow. All features are designed before implemented.

## Structure

```
specs/
  constitution/       # Project-wide constraints and goals
    mission.md        # Purpose, scope, target audience
    tech-stack.md     # Languages, tools, commands
    roadmap.md        # Feature phases and IDs
  features/
    v{X.Y}/
      {NNN}-{slug}/
        plan.md         # What and why — groups of work
        requirements.md # Technical constraints and decisions
        validation.md   # Acceptance criteria and tests
  _templates/         # Canonical templates for new specs
```

## Statuses

`draft` → `accepted` → `implemented`

## Branch convention

Each feature lives in `feature/{NNN}-{slug}`, branched from `main`, merged back when complete.
