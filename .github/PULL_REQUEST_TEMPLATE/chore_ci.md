<!-- Chore / CI / tooling PR — tests, CI workflows, scripts, dependency bumps,
     refactors with no intended behavior change. -->

## Why

<!-- What this improves (flaky test, red CI job, dependency, dev ergonomics).
     Link the issue: Closes #___ -->

## What changed

<!-- The concrete tooling/test/CI/dependency change. -->
-

## Behavior impact

<!-- "No runtime behavior change" for pure refactors/tooling, or describe the
     effect (e.g. new CI gate, changed test scope, upgraded package surface). -->

## Verification

- [ ] `flutter analyze` clean
- [ ] `dart format --set-exit-if-changed lib test` passes
- [ ] `flutter test` (or affected suites) pass
- [ ] CI jobs green on this branch (or explain remaining reds)

## Dependency notes

<!-- For bumps: package(s), version delta, breaking-change scan, why now.
     Delete if not a dependency change. -->
