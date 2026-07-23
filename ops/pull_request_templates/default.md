<!--
General-purpose PR template. For a type-specific layout, use one of the
siblings in this directory (feature / bugfix / backend_api / chore_ci / docs)
or, on GitHub, append ?template=<name>.md to the compare URL once these are
wired into .github/ (see README.md).
-->

## Why

<!-- The problem or motivation. Link the issue: Closes #___ -->

## What changed

<!-- Bullet the concrete changes. Reference files/areas, not line numbers. -->
-

## Testing

<!-- How you verified: commands run, suites that pass, manual steps. -->
- [ ] `flutter analyze` clean
- [ ] `flutter test` (or the affected suites) pass
- [ ] Manually exercised the change on device/emulator where relevant

## Notes / risk

<!-- Follow-ups, known gaps, backend coordination, rollout considerations. -->
