# Test-suite triage

Tracks the work to make `flutter test` reliably terminate and pass in CI
(`.github/workflows/test-coverage.yml`, `flutter test --coverage`, 30-min job
timeout).

## 1. The hang (fixed — root of the CI timeouts)

**Symptom:** the full suite never finished; a `flutter_tester` isolate sat at
0% CPU indefinitely, so the CI job hit its 30-minute cap and failed. `flutter
test --timeout=Ns` could **not** preempt it (the block is native, not an async
gap the Dart timer can interrupt).

**Located to a single file** by bisecting per top-level dir, then per file:
`test/arcade/screens/arcade_screens_widget_test.dart`. It wedges on the very
first `tester.pumpWidget(DailyBonusScreen)` — `setUp` (`AppCacheService.initialize`
→ `Hive.openBox`) completes fine (the service-only arcade tests share it and
pass), and the screen itself has no timers/animations/futures, so the block is
in the headless widget pump path and is uninterruptible.

**Action:** the two widget groups are **quarantined** with `skip:` and a clear
reason, so the file terminates instantly and the suite completes. This is a
containment fix, not a root-cause fix.

**Follow-up (root cause, not yet done):** reproduce the pump hang for
`DailyBonusScreen` / `ArcadeMissionsScreen` in isolation and determine whether
it's a Hive/box interaction under the test binding or a layout path that blocks
natively; then restore the tests. Until then the two screens have no widget
coverage (their underlying services — `ArcadeDailyBonusService`,
`ArcadeMissionService` — are still covered by passing unit tests).

## 2. Verifying the suite terminates

Per-dir wall-clock (bisect, `flutter test <dir>`), post-quarantine:

| dir | result | ~time |
|-----|--------|-------|
| admin | pass | 68s |
| arcade | 261 pass / 9 skip / 15 fail | 18s |
| core | fail | 102s |
| features | fail | 34s |
| game | fail | 107s |
| integration | pass (2 skip) | 7s |
| screens | fail | 38s |
| synaptix | pass | 7s |
| ui_components | fail | 26s |
| widgets | fail | 9s |

Total ≈ 7 min — comfortably under the 30-min CI cap now that nothing hangs.

## 3. Remaining failures (in progress)

The dirs marked "fail" carry the historical ~223 pre-existing failures. These
do not block the suite from completing, but they do keep it red. Categorization
by root-cause bucket and the fix plan are tracked below as they land.
