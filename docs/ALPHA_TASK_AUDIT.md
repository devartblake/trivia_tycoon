# Synaptix Alpha Outstanding Task Audit

_Date: 2026-03-31 | Last updated: 2026-04-09_

## 0) ProfileSyncService 404/backoff root cause (resolved) ✅

- The app was attempting profile sync against fallback endpoints:
  - `/profile`
  - `/user/profile`
  - `/auth/profile`
- Those were returning `404`, which correctly triggered `ProfileSyncService` endpoint backoff logs.
- The repository API contract includes user profile updates on `/users/me` (`PATCH /users/me`).
- Resolution applied:
  - Added `/users/me` as the first profile-sync endpoint candidate.
  - Added `/users/me` to `ApiService` protected-path detection so 401 refresh handling applies consistently.

## 1) TODO/FIXME inventory ✅ RESOLVED

- `lib/` currently contains **0** TODO/FIXME comments (Dart files) — down from 46.
- The full repository contains **0** TODO/FIXME comments in source code — down from 71.

> Note: `android/app/build.gradle` contains 2 standard Android Studio boilerplate
> placeholder comments (application ID and signing config). These are not application
> source code and do not require resolution.

### Previously open Synaptix-branded frontend TODOs — now resolved ✅
- `lib/main.dart` — `TriviaTycoonApp` → `SynaptixApp` rename: **completed**
- `lib/synaptix/widgets/hub_daily_quest.dart` — mock → provider-driven quest data: **completed**
- `lib/synaptix/widgets/hub_featured_match.dart` — static → data-driven recommendations: **completed**
- `lib/synaptix/widgets/hub_live_ticker.dart` — static → provider/stream live data: **completed**

## 2) Synaptix markdown docs: outstanding work

## `docs/synaptix_frontend_plan.md`
Open checklists still indicate pending Phase 7 QA/stabilization work:

- App launch, auth/bootstrap, onboarding, hub rendering, mode mapping, and all major surface navigation checks remain unchecked.
- Consistency/brand checks remain unchecked, including:
  - No remaining visible "Trivia Tycoon" labels
  - No mixed old/new adjacent screen language
  - Mode-specific rendering validation
  - Frontend/backend label consistency verification

> **Status:** Blocked — requires a running device and live backend. Curl CONNECT
> tunnel failure prevents live smoke-checking in CI; Flutter SDK not on PATH in CI.

## `docs/synaptix_onboarding_production_implementation.md`
Implementation order and acceptance criteria are documented, but treated as work to execute (not marked complete):

- 14-step file-by-file conversion sequence for production onboarding.
- Acceptance criteria include persistence restore, mode mapping, first-session challenge completion, reward reveal before `/home`, and route gating correctness.

## `docs/synaptix_master_playbook.md`
This file presents strategic sequencing; it still lists the next execution path as:

1. Implement Flutter onboarding system
2. Build monetization backend (FastAPI)
3. Implement UI polish system
4. Prepare beta launch
5. Scale growth engine

## 3) Alpha-focused recommendation

For Synaptix **Alpha (mobile + web)**, the minimum outstanding execution set is:

1. ~~Close high-visibility Synaptix TODOs in hub widgets and app naming.~~ ✅ Done
2. Complete Phase 7 QA checklist in `synaptix_frontend_plan.md` and mark completed items. _(requires device)_
3. Run onboarding acceptance criteria from `synaptix_onboarding_production_implementation.md` as explicit test cases. _(requires device)_
4. ~~Decide whether Phase 8 technical rename (`TriviaTycoonApp` -> `SynaptixApp`) is in Alpha scope or deferred.~~ ✅ Done

## 4) 2026-04-04 execution plan update

A prioritized execution plan for tonight has been added:
- `docs/frontend_priority_execution_plan_2026-04-04.md`

Key operating target for tonight:
- Complete all P0 items and at least 2 P1 items (>=55% completion by weighted score).

Backend handoff note:
- The requested files `frontend_admin_security_rollout_plan` and `frontend_backend_handoff_alpha_2026-04-04` were not present in this repo when planning; this plan uses existing admin contract/smoke docs as source of truth until those files are added.

Progress update (2026-04-04 execution — complete):
- ✅ Planning doc created, priority breakdown finalized, smoke script dry-run validated
- ✅ Admin dashboard role-gate hardening implemented
- ✅ Known-good smoke response checklist documented
- ✅ Contract/error mapping pass implemented for Admin Users, Question Bank, Admin User Detail, activity-log, dataset-status, config-sync pathways
- ✅ Admin Audio invalid-asset retry suppression cache implemented
- ✅ `/users/me` profile-sync troubleshooting guide added
- ✅ Hub featured-match fallback policy implemented (including preferred-category source feed fix)
- ⏳ P1.2 test execution — requires Flutter-enabled environment
- ⏳ P1.3 fallback rendering test — requires Flutter-enabled environment

## 5) 2026-04-09 additional completions

### Phase 5 — Monolithic file refactoring ✅ COMPLETE
- `lib/game/providers/riverpod_providers.dart` reduced from 883 lines to 40 lines (pure barrel re-exporter).
  All 16 provider modules now live in dedicated specialized files with no duplication.
- `lib/screens/profile/profile_screen.dart` — no longer monolithic (336 lines).
- `lib/admin/user_management/admin_users_screen.dart` — no longer monolithic (951 lines).

### Phase 6 — TODO resolution ✅ COMPLETE
- All 53 source-code TODOs resolved. Count is now 0.

### 3D Renderer ✅ COMPLETE
- All 5 TODOs in `lib/animations/ui/widget_model.dart` implemented:
  multi-object named-map API, smooth shading via geometric normal averaging,
  load-time scale parameter, vertex deduplication, GPU-aware texture atlas,
  `shouldRepaint` state diff.
  See `docs/3d_renderer_improvement_plan.md` for full details.

### API service dual-import ✅ FIXED
- `lib/core/services/api_service.dart` removed unused `http` import; `getRequest()`
  now uses the already-present `Dio` client consistently.

### Phase 3 — Test Coverage ✅ SUBSTANTIALLY COMPLETE
- 8 new test files added; total test file count: 31 → **39**.
- New areas covered:
  - `PowerUpController` (activate, clear, expiry, restore, equipById)
  - `ChallengeService` (caching, refresh times, updateProgress)
  - `ArcadeRewardsService` (bounds, difficulty, time bonus, per-game tuning)
  - `ArcadeDailyBonusService` (claim, streak continuity, reward schedule)
  - `ArcadeMissionClaimService` (daily claim tracking, clearToday, persistence)
  - `ArcadePersonalBestService` (best score, per-game/difficulty isolation, persistence)
  - `ArcadeMissionService` (progress, claim anti-abuse, mergeById/preferLocal policies,
    serialization, `ArcadeMissionCatalog` validation)
  - `QuickMathController` (scoring, streaks, bounds, math correctness, toResult)
- Remaining coverage gaps: auth edge cases, widget tree tests, MemoryFlip/PatternSprint
  controllers, presence services.
