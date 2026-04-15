# Synaptix Alpha Outstanding Task Audit

_Date: 2026-03-31 | Last updated: 2026-04-14_

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

### Phase 3 — Test Coverage ✅ SUBSTANTIALLY COMPLETE (Pass 1)
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

### Phase 3 — Test Coverage Pass 2 ✅ COMPLETE
- 6 more test files added; total test file count: 39 → **45**.
- New areas covered:
  - `MemoryFlipController` (deck structure, flip/match/miss/ignored, allMatched→isOver, toResult)
  - `PatternSprintController` (answer correct/wrong/lock, streak, all-difficulty question generation, toResult)
  - `ArcadeSessionService` (startSession, endSession, attachDuration)
  - `TypingIndicatorService` (startTyping, stopTyping, peer typing, handleTextInput, handleMessageSent, clearConversationTyping)
  - `ArcadeRegistry` (all 3 game definitions, IDs, difficulties, ArcadeGameId completeness)
  - `LocalArcadeLeaderboardService` (recordRun, top sort order/limit, best, wouldBeNewBest, clearBoard, clearAll, persistence, topForGame)

**Remaining coverage gaps** (tracked in [`docs/REMAINING_TASKS.md`](REMAINING_TASKS.md)):

| Gap | File(s) | Key methods to cover |
|-----|---------|----------------------|
| `RichPresenceService` | `lib/core/services/presence/rich_presence_service.dart` | `initialize()`, `updateCurrentUserPresence()`, `setGameActivity()`, `canUserJoinGame()`, `watchUserPresence()` |
| Auth edge cases | `lib/core/services/auth_service.dart` | Social login, concurrent 401 refresh, offline login, logout clears tokens |
| Widget tree tests | Various screens | `ArcadeGameShell`, `DailyBonusScreen`, `ArcadeMissionsScreen` |

### Phase 2 — UnimplementedError stubs ✅ RESOLVED
- `core_providers.dart` (`serviceManagerProvider`) — documented as intentional design-time guard
- `app_lifecycle.dart` (`appLifecycleProvider`) — documented as intentional design-time guard
- `spin_earn_screen.dart` — removed stale comment referencing a replaced `UnimplementedError`

## 6) 2026-04-09 web / Edge browser fix ✅ COMPLETE

### Root cause — Flutter web startup cascade failure
- `lib/core/services/api_service.dart` unconditionally imported `dart:io` and
  `package:path_provider/path_provider.dart`. DDC (debug) / dart2js (release) cannot
  use `dart:io` on web; this caused a module-cascade that reported as
  `"Library not defined: …/referral_invite_adapter.dart. Failed to initialize."` at
  runtime.
- `lib/core/services/auth_error_messages.dart` also imported `dart:io` for
  `SocketException`/`HttpException` type checks, cascading through `auth_providers.dart`
  → `main.dart`.

### Fix applied
- Created `lib/core/services/_api_cache_store.dart` (web stub → `MemCacheStore()`) and
  `lib/core/services/_api_cache_store_io.dart` (native → `HiveCacheStore(tempDir.path)`).
- `api_service.dart`: removed `dart:io`, `path_provider`, `http_cache_hive_store`
  imports; wired in conditional import; `_initializeCache()` calls `createCacheStore()`.
- `auth_error_messages.dart`: removed `dart:io`; exception-type guards replaced with
  `runtimeType.toString()` / `toString().startsWith()` checks.
- `web/index.html` + `web/manifest.json`: branding updated (`trivia_tycoon` → `Synaptix`).

> **Result:** Web and Edge startup cascade failure eliminated. App can now load on web
> in both debug (DDC) and release (dart2js) modes.

## 7) 2026-04-12 additional completions

### Store payments integration ✅ IMPLEMENTED
- Frontend store/payment wiring is now in place for:
  - Stripe one-time checkout
  - PayPal one-time create + capture
  - Stripe subscriptions
  - Stripe billing portal redirection
  - PayPal subscriptions with post-return status polling
- In-app return routing has been added for:
  - `/store/payment-return`
  - `/store/subscription-return`
- Supporting implementation includes route registration, environment-driven return
  URL generation, and provider-specific post-return refresh handling.

### Hosted app-link / universal-link setup ✅ IMPLEMENTED IN REPO
- Android manifest intent filters added for the hosted Synaptix return domain.
- iOS associated-domains entitlements added and wired into the Runner target.
- Hosted verification templates added under `docs/app-links/`.
- `APP_REDIRECT_BASE_URL` added as the frontend return URL base input.

### App-link runtime routing ✅ IMPLEMENTED
- Runtime incoming-link handling added via `app_links`:
  - initial-link handling
  - foreground-stream handling
  - deferred routing until GoRouter is ready
- Guard rails added so builds that do not yet contain the native plugin do not
  crash the app at startup.

### Phase 2 crash recovery + notification persistence ✅ CODE COMPLETE
- Crash recovery now restores persisted quiz/player/profile state instead of only logging.
- Notification history is now persisted and restored on startup.
- Notification template state is restored during bootstrap.
- Backlog updated in `docs/REMAINING_TASKS.md` to reflect code completion.

### Tests added ✅
- Payment/app-link tests:
  - `test/core/services/store_return_url_builder_test.dart`
  - `test/core/services/store_link_router_test.dart`
  - `test/screens/store/store_payment_return_screen_test.dart`
  - `test/core/services/store_service_payment_flows_test.dart`
  - `test/core/services/backend_profile_social_service_test.dart`
  - `test/core/services/api_service_test.dart` (store `403`/`503` error-path coverage)
- Recovery/notification tests:
  - `test/core/services/crash_recovery_service_test.dart`
  - `test/game/providers/notification_history_store_test.dart`

### Backend handoff partials âœ… CLOSED
- The alpha handoff partials for store/profile integration are now implemented:
  - `POST /store/iap/validate` client support added in `StoreService`
  - backend user search wired for add-friend-by-username
  - backend career-summary fetch wired into the enhanced profile screen
  - backend loadout `GET`/`PUT` wiring added for enhanced profile data + profile edit save
  - backend `DELETE /friends` wiring added for unfriend
- Question gameplay handoff wiring is now implemented:
  - quiz retrieval prefers `GET /questions/set`
  - per-question validation uses `POST /questions/check`
  - end-of-quiz reconciliation uses `POST /questions/check-batch`
- This closes the previously partial store/profile slices from
  `docs/frontend_backend_handoff_alpha_2026-04-04.md`.
- The larger handoff items for crypto surfaces and ML UX usage
  remain separate work items.
- The canonical remaining-work tracker for those open handoff items is now
  `docs/REMAINING_TASKS.md`.

### Remaining operational validation
- Hosted-domain verification still requires production deployment of:
  - `assetlinks.json`
  - `apple-app-site-association`
- Clean native rebuild/reinstall still required after adding `app_links` to avoid
  stale-build `MissingPluginException` on Android.
- Payment handoff QA scenarios for PayPal subscription cancel plus store `403` and `503`
  responses are now covered by automated tests and no longer remain open in the
  handoff document.

## 8) Outstanding work — full backlog

See **[`docs/REMAINING_TASKS.md`](REMAINING_TASKS.md)** for the prioritized, detailed backlog
covering all remaining work across:

- Frontend/backend alpha handoff remaining work (crypto surfaces, ML UX consumption)
- Phase 2 crash recovery stubs (3 items - §1d UnimplementedErrors resolved)
- Phase 3 test coverage gaps (9 specific classes/scenarios)
- Phase 4 dependency audit (outdated packages, unused transitive deps)
- Sprint 1 auth integration verification
- Sprint 2 networking layer (not started)
- Synaptix runtime validation (device-blocked)
- Backend Packet E (deferred)

## 9) 2026-04-14 profile persistence and local web auth follow-up

### Onboarding country-step overflow ✅ FIXED
- `lib/screens/onboarding/steps/country_step.dart` was still using an older
  fixed-height Column layout and could overflow on shorter devices by more than
  100 px.
- The step now uses the shared onboarding shell and a scroll-safe content area,
  which removes the RenderFlex bottom overflow seen on emulator/device.

### Local web auth diagnosis ✅ FRONTEND-SIDE CAUSE NARROWED
- The earlier 2026-04-09 fix resolved Flutter web startup failure.
- Follow-up tracing on 2026-04-14 showed a separate local auth/runtime mismatch:
  some frontend config still pointed at `https://localhost:5000`, while the
  locally reachable backend path was `http://localhost:5000`.
- Frontend local defaults were aligned to HTTP for local browser testing.

### Profile restore after emulator wipe ✅ FRONTEND HYDRATION PATCHED
- Root cause:
  - onboarding only synced `displayName` + `username` to backend
  - startup profile load only re-read local Hive state
  - after clearing emulator data, there was no local state to restore and no
    backend profile fetch to repopulate it
- Resolution applied:
  - onboarding profile sync expanded to include country, age group, preferred
    categories, Synaptix mode, and preferred home surface
  - login/signup now attempt backend profile hydration immediately after auth
  - bootstrap now attempts backend profile hydration for logged-in users before
    falling back to local Hive
  - queued profile sync retries are now triggered during bootstrap

### Remaining profile-storage gap ⚠️ STILL OPEN
- Picked avatar image files are still only local-device file paths unless they
  already resolve to an asset path or backend-served URL.
- Full portable avatar persistence requires an upload flow backed by object
  storage (MinIO or equivalent), returning a stable object URL or object key
  that can be stored in both backend profile data and Hive.
