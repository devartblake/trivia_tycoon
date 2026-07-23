<!--
General-purpose PR template (used by default). For a type-specific layout,
open the compare page and append a template query param, e.g.:
  ?template=feature.md   — new user-facing capability or system
  ?template=bugfix.md    — fixing a defect (symptom → root cause → fix)
  ?template=backend_api.md — client changes tracking a backend contract
  ?template=chore_ci.md  — tests / CI / tooling / dependency bumps / refactors
  ?template=docs.md      — documentation, status notes, changelog-only
The type templates live in .github/PULL_REQUEST_TEMPLATE/. All share this
Why → What changed → Testing spine.
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
