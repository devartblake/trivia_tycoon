# Alpha Release — Known Issues

**Release:** alpha-june-2026
**Last updated:** 2026-05-16

---

## P1 — Launch Blockers

None currently known.

---

## P2 — Mitigated Issues (Not Blocking)

### KI-001 — Client-side reward guard is widget-state scoped

**Description:** `ScoreSummaryScreenWrapper._hasProcessedResults` prevents double-call to `ProfileDataUpdater.updateAfterQuiz()` within a single widget lifecycle. If the widget is recreated (e.g., edge-case navigation), the guard resets.

**Mitigation:** `POST /quiz/complete` uses a UUID `eventId` deduplication on the backend via a unique index (`ProcessedGameplayEvent`). Even if the client sends two requests, the backend grants rewards only once.

**Status:** Accepted for Alpha. Full client-session tracking can be added post-Alpha.

---

### KI-002 — Smoke test not validated in automated CI against staging

**Description:** `test/integration/live_backend_smoke_test.dart` exists and is correct, but has not yet been executed against a live staging environment with real credentials.

**Mitigation:** Manual run required before sign-off. Test is credential-gated and auto-skips without env vars, so it does not block the standard `flutter test` CI run.

**Status:** Required manual step in `ALPHA_RELEASE_CRITERIA.md`. Blocked on staging environment availability.

---

## P3 — Post-Alpha Improvements

### KI-003 — Tournaments and Advanced Seasons have no dedicated feature flag

**Description:** Both `tournamentsEnabled` and `advancedSeasonsEnabled` are in the Flutter `FeatureFlags` model and shown in `ALPHA_DISABLED_FEATURES.md`, but no dedicated backend endpoint group exists for them. They are currently controlled by the `realtimeMultiplayerEnabled` gate at the matchmaking level.

**Impact:** Low. Neither system is user-accessible in Alpha. Dedicated flags can be wired when tournament endpoints are implemented.

**Status:** Accepted. Post-Alpha.

---

### KI-004 — Spin & Earn flag status not confirmed in `/api/v1/app/config`

**Description:** The smoke test (`live_backend_smoke_test.dart`) covers `/arcade/spin/segments` and `/arcade/spin/claim`, but Spin & Earn is not listed in `ALPHA_ENABLED_FEATURES.md`. Verify whether it is enabled in the alpha config or should be gated.

**Impact:** Low. Smoke test accepts 400/404/409/422 from `/arcade/spin/claim` as valid responses.

**Status:** Verify flag state before launch and update `ALPHA_ENABLED_FEATURES.md` accordingly.

---

### KI-005 — `info`-level redundant import warnings in login screens

**Description:** `flutter analyze` reports 7 pre-existing `info`-level warnings about redundant imports in `login_screen.dart` and `login_screen_mobile.dart`. These were present before any Alpha/Beta work and do not affect functionality.

**Impact:** None. Cosmetic only.

**Status:** Accepted for Alpha. Clean up post-Alpha.
