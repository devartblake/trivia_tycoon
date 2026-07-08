# Trivia Tycoon — Full Codebase Audit & 5-Sprint Plan

**Audit Date:** 2026-07-08
**Scope:** Entire Flutter client (`lib/`, 1,418 Dart files), config, assets, docs, CI
**Toolchain used:** Flutter 3.44.5 stable (`flutter pub get` + `flutter analyze` + `flutter test` run as part of this audit)
**Branch:** `claude/codebase-audit-sprint-plan-xwf38e`

---

## Executive Summary

| Area | Verdict | Severity |
|---|---|---|
| Compile/syntax health | ✅ Compiles clean — 0 errors, 26 analyzer issues (warnings/info) | Low |
| Question screen not displaying | 🔴 Root causes identified (startup health-gate + timeout cascade + status-provider duplication) | **Critical** |
| Sentry integration | 🔴 Effectively OFF in every shipped build — only the unused `main_with_sentry.dart` entrypoint initializes it | **Critical** |
| API endpoints | 🟠 Several client calls target endpoints that do not exist on the backend; two competing "friends" API surfaces; auth headers missing for some protected paths | High |
| Sprint 1 Friends system | 🟠 Built but **dark** — `FriendsListScreen` is not routed anywhere; `/friends` still points at the legacy profile screen | High |
| Duplicate/legacy code | 🟠 3 overlapping question API layers, duplicated providers/widgets/entrypoints, 29 wrong-depth imports | Medium |
| Performance | 🟡 Serial startup awaits, 10s timeout cascades, 13 sequential stats calls | Medium |
| Outstanding plans | 🟡 Friends polish, Parties UI, Question Phases 3–4, Operator Dashboard, Analytics, Realtime — inventoried below | Planning |

---

## 1. Build & Syntax Health (verified with real toolchain)

### 1.1 Results

- `flutter pub get` **fails on Flutter < 3.44.5** (transitive constraint via `model_viewer_plus`). The toolchain requirement should be pinned in docs/CI (`environment: flutter: '>=3.44.0'`) so contributors don't hit unexplained resolution failures.
- `flutter analyze` (3.44.5): **26 issues, 0 errors** — the app compiles.

### 1.2 The 26 analyzer issues worth fixing

| File | Issue | Why it matters |
|---|---|---|
| `lib/core/env.dart:33-35` | `_sentryDsn`, `_sentryEnvironment`, `_sentryTraceSampleRate` **unused fields** | Evidence Sentry env-plumbing was half-finished — EnvConfig parses nothing for these; `SentryService` reads dotenv directly |
| `lib/features/social/providers/social_providers.dart` (11×) | `unused_result` on `ref.refresh(...)` | Friends list/requests may not actually refresh after accept/decline/remove |
| `lib/game/providers/multiplayer_providers.dart:8` | Unused import of `matches_api_client.dart` | Dead wiring left from the REST migration |
| `lib/game/services/matches_service.dart:98` | `_refreshTimer` never used | Auto-refresh for match history likely never starts |
| `lib/screens/question/widgets/sorting_view.dart:83`, `lib/admin/questions/question_list_screen.dart:483` | Deprecated `onReorder` | Will break on future Flutter upgrade |
| `lib/ui_components/cards/slimy_card.dart:136,246` | Deprecated `axisAlignment` | Same |
| `lib/features/social/screens/friends_list_screen.dart:20`, `add_friend_dialog.dart:25` | Unused locals | Hygiene |

### 1.3 Wrong-depth relative imports (29 files)

29 non-commented imports have one `../` too many (e.g. `lib/arcade/leaderboards/local_arcade_leaderboard_screen.dart` imports `../../../core/navigation/navigation_extensions.dart`, which points **above** `lib/`). Dart happens to clamp `..` at the package root so these currently resolve, but they:

- break the moment a file is moved (silent fragility during refactors),
- confuse IDE navigation / tooling / import scanners,
- violate the intent of relative imports.

Affected clusters: `lib/arcade/leaderboards/*`, `lib/arcade/missions/*`, `lib/screens/menu/widgets/*`, `lib/admin/store/widgets/stock_preview_card.dart`, `lib/admin/questions/file_import_export_screen.dart`, `lib/admin/encryption/ecryption_manager_screen.dart` (also note the filename typo: *ecryption*), `lib/screens/invite_log_screen.dart`, `lib/screens/preferences_screen.dart`, `lib/screens/settings/settings_screen.dart`, `lib/ui_components/presence/message_reaction_picker.dart`, `lib/ui_components/mission/mission_scroll_row.dart`, `lib/admin/widgets/scan_sync_card.dart`, `lib/admin/analytics/scan_stats_card.dart`.

**Fix:** mechanical one-pass correction (~1 day incl. review), ideally enforced afterwards with `always_use_package_imports` lint.

### 1.4 Dependency health

- `135 packages have newer versions incompatible with dependency constraints` (pub output).
- Duplicated capability deps inflate app size: **two audio engines** (`flutter_soloud` + `just_audio`), **two 3D viewers** (`flutter_3d_controller` + `model_viewer_plus`), `camera`, `signalr_netcore` + `grpc` + raw WebSocket — three realtime transports.
- `sentry_flutter` pinned exactly (`9.23.0`) while everything else uses caret ranges.

---

## 2. Question Screen / Question System Not Displaying — Root-Cause Analysis

The question pipeline itself is **structurally sound** (models → `QuestionHubService` → `QuestionRepositoryImpl` → `adaptedQuizProvider` → `AdaptedQuestionScreen` → `QuestionRenderer`, with local-asset fallback). The app compiles. The failure is **runtime gating + latency + wiring**, in this order of likelihood:

### 2.1 🔴 Release builds hard-block on backend health before the router ever loads

`lib/core/bootstrap/synaptix_app.dart` → `_runStartupChecks()`:

- After splash + crash-recovery, the app calls `synaptixApiClient.healthCheck()`.
- If the health check fails, `_allowOfflineStartup()` returns `false` in **release mode** unless built with `--dart-define=ALLOW_OFFLINE_BOOT=true`, and the app parks on the "backend unreachable" screen **forever**.
- Consequence: any staging/prod build pointed at an unreachable `API_BASE_URL` (e.g. `https://api.synaptixplay.com` not deployed yet) **never shows any screen, including the quiz**, even though a complete offline question fallback exists in the code.

This is the single most probable cause of "question system not displaying at all" in a release/staging build. The offline fallback investment (local question assets, `_recordFallback`, source banner) is unreachable in exactly the builds users touch.

### 2.2 🔴 Timeout cascade makes debug feel like "never loads"

- `EnvConfig.apiConnectTimeout` = **10s**; every question call (`/questions/set`, `/questions/categories`, `/questions/metadata`, per-category and per-class stats) independently waits out the full connect timeout before its fallback fires.
- `QuestionScreen` (the hub at `/quiz`) triggers on load: `questionStatsProvider`, `quizCategoriesProvider`, `serviceStatusProvider`, plus a `_preloadData()` that awaits `getDailyQuestions()` **and** `getAvailableCategories()` — serially.
- `allClassesStatsProvider` issues **13 sequential** `/questions/classes/{id}/stats` calls → worst case >2 minutes of spinners when backend is down.
- `AdaptedQuestionScreen` shows its loading spinner for the full 10s before local questions appear.

**Fix:** a shared backend-availability short-circuit (one failed health probe ⇒ skip straight to fallback for N seconds), shorter connect timeout for question endpoints (2–3s), and parallelized stats fetches.

### 2.3 🟠 `serviceStatusProvider` is defined twice with different semantics

- `lib/game/providers/question_providers.dart:131` — `Provider<Map>` fed by the real `questionSourceStatusProvider` (backend/localFallback). This is what `QuestionScreen` imports.
- `lib/game/providers/quiz_providers.dart:78` — a **second** `serviceStatusProvider` (`FutureProvider`) that hard-codes `'source': 'repository'`, a value the banner UI doesn't recognize (renders "Question source not confirmed yet").

Any screen importing the quiz_providers copy shows a permanently-unconfirmed source banner and creates import ambiguity. Delete the quiz_providers copy.

### 2.4 🟠 Missing stats endpoints guarantee fallback noise

`QuestionHubService` calls `GET /questions/categories/{slug}/stats` and `GET /questions/classes/{id}/stats`. Per `docs/api/BACKEND_API_AUDIT.md`, the backend exposes **neither**. Every stats read is a guaranteed timeout→fallback cycle that also flips the source banner to "local fallback" even when question fetching works.

### 2.5 🟡 Mixed-quiz endpoint mismatch

Backend has `POST /api/v1/questions/mixed`; `QuestionHubService.getMixedQuiz()` only calls `GET /questions/set` (and, when falling back, *labels* the fallback as `/questions/mixed`, which is misleading in the source banner). Multi-category requests silently drop all but one category (`categories.length == 1` filter).

### 2.6 Verification results from this audit

- Local fallback assets are present: `assets/questions/**` with `question_paths_index.json`, and `assets/questions/` **is** declared in `pubspec.yaml`.
- Routes exist and are wired: `/quiz` (hub) → `QuestionScreen`, `/quiz/play` + `/quiz/question` → `AdaptedQuestionScreen`, `/score-summary` exists.
- `.env.local` is **not** a bundled asset (only `.env.prod`/`.env.staging` are in pubspec assets), so debug builds silently fall back to the hard-coded `http://10.0.2.2:5000` — correct for Android emulator, but the dotenv file devs edit is not actually read on device builds. Worth bundling or documenting.

---

## 3. API Endpoints — Current vs Missing

### 3.1 Verified working alignment (client ↔ backend, per backend audit doc)

| Backend endpoint | Client |
|---|---|
| `GET /api/v1/questions/set`, `POST /questions/check`, `POST /questions/check-batch`, `GET /questions/categories`, `GET /questions/metadata` | `QuestionHubService` ✅ (ApiService base = `EnvConfig.apiV1BaseUrl`) |
| `GET /rewards/daily-config`, `GET/POST /account/rewards/*` | `DailyBonusApiClient` ✅ |
| `GET /rewards/weekly-schedule`, `weekly-streak`, claims | `WeeklyRewardsApiClient` ✅ |
| `GET /progression/tiers`, `GET /progression/player/{id}`, `POST /progression/xp/award` | `TierApiClient` ✅ |
| `/matches/start`, `/matches/submit`, `/matches/{id}`, `/matches/{id}/abandon` | `MatchesApiClient` ✅ |
| Missions `GET /missions?type=`, progress, claim | mission services ✅ |

### 3.2 Client calls with **no backend endpoint** (missing/broken)

| Client call | Where | Status |
|---|---|---|
| `GET /questions/categories/{slug}/stats` | `QuestionHubService.getCategoryStats` | ❌ Not on backend — always falls back |
| `GET /questions/classes/{id}/stats` | `QuestionHubService.getClassStats` (13 IDs) | ❌ Not on backend |
| `POST /questions/mixed` | Backend has it; client never calls it | ⚠️ Unused backend capability |
| `GET /questions`, `POST /questions/bulk`, `DELETE /questions/{id}` | `lib/core/services/question/question_api_service.dart` (raw `http`, static) | ❌ Legacy layer, endpoints don't exist |
| `GET /questions` | `lib/core/services/question_api_client.dart` | ❌ Legacy layer |
| `/leaderboard` (GET/POST), `/achievements`, `/quiz/complete`, `/app/config`, `/events/{name}`, `/seasons/*`, `/admin/seasons/*` | legacy methods inside `ApiService` itself | ⚠️ Unverified against backend; several predate the v1 API redesign |

### 3.3 Two competing Friends/Social API surfaces

- **Surface A (Sprint 1, 2026-07-05):** `SocialApiClient` → `/friends`, `/friends/request`, `/friends/request/{id}/accept|decline`, `/friends/{id}/remove`, `/party/*` — used by `features/social/*`.
- **Surface B (legacy):** `SynaptixApiClient` + `backend_profile_social_service.dart` → `/users/me/friends`, `/users/me/friends/request`, `/users/me/friends/requests/sent`, `/users/me/friends/suggestions`, `/users/me/block` — used by `screens/profile/*`.

Both are live in the codebase; only one can match the real backend. This must be resolved (pick canonical surface, migrate the other) before Friends ships.

### 3.4 Auth-header gaps in `ApiService._isProtectedPath`

The bearer-token injection list covers `/admin`, `/store`, `/crypto`, `/rewards`, `/spins`, `/arcade`, `/missions`, `/users/me`, `/friends`, `/profile` — but **not** `/matches`, `/party`, `/progression`, `/account`, `/quiz`. The backend audit explicitly marks `/account/rewards/*` and `/progression/player` as requiring authorization. Clients that route those paths through the plain `ApiService` (rather than the authenticated transport) will 401. Audit each client's transport and either extend `_isProtectedPath` or standardize on the authenticated `AuthHttpClient` for all protected features.

### 3.5 Minor defect

`ApiService.getRequest()` builds `_dio.get('$baseUrl/$endpoint')` even though `_dio` already carries `baseUrl` in its `BaseOptions` — works only because the string is absolute; inconsistent with every other method and double-joins if base ever becomes relative. Remove or normalize.

---

## 4. Sentry Integration (Client + Server)

### 4.1 Current state — effectively disabled

| Item | State |
|---|---|
| `lib/main.dart` (the entrypoint every build uses) | ❌ **No Sentry init at all** |
| `lib/main_with_sentry.dart` | ✅ Correct init — but **no build script, CI workflow, or run script targets it** (verified: no `-t lib/main_with_sentry.dart` anywhere in `scripts/`, `run_web.sh`, `.github/workflows/`) |
| `SentryNavigatorObserver` on GoRouter | ❌ Absent — no screen breadcrumbs/transactions |
| Dio instrumentation (`sentry_dio`) | ❌ Absent — no HTTP breadcrumbs or trace propagation to the backend |
| `runZonedGuarded` / `FlutterError.onError` capture in `main.dart` | ❌ Absent |
| DSN configuration | ⚠️ Real DSN **committed** in `assets/config/.env.prod` & `.env.staging` (should be injected via CI secrets; rotate the committed one) |
| `EnvConfig` Sentry fields | ⚠️ Declared but unused (`_sentryDsn` etc. — analyzer confirms) |
| `docs/SENTRY_SETUP_FLUTTER.md` | ⚠️ Claims "Status: ✅ Implemented" — inaccurate for shipped builds |

### 4.2 Recommended target state

1. **One entrypoint.** Fold Sentry init into `lib/main.dart` (conditional on DSN presence — the existing graceful-degradation logic in `main_with_sentry.dart` is good, promote it) and delete `main_with_sentry.dart`; evaluate whether `main_mobile.dart` / `main_web.dart` still earn their keep (`SynaptixApp` already abstracts the platform).
2. Wrap `_runApp()` in `SentryFlutter.init(appRunner:)` so framework errors funnel automatically; keep `SentryService.captureException` for manual capture.
3. Add `SentryNavigatorObserver` to the GoRouter `observers:` and `sentry_dio` on the shared Dio instances (this also propagates `sentry-trace` headers → enables **distributed tracing into the .NET backend**).
4. Move DSN to `--dart-define` injected from GitHub Secrets in `release.yml`; rotate the committed DSN.
5. **Server side (Synaptix.Backend.Api):** add `Sentry.AspNetCore` with the same environment naming + release tagging convention (`version+build`) so client and server events correlate; enable trace-header continuation so a failed `/questions/set` call shows one linked trace across Flutter → API.
6. Alert rules: crash-free-sessions, `ApiRequestException` volume by endpoint, question-fallback frequency (custom event) — the source-status reporter already computes this, it just needs a Sentry breadcrumb/metric hook.

---

## 5. User Flow Design

### 5.1 Boot flow (as implemented)

```
main() → EnvConfig.load → AppInit.initialize (fully serial)
  → ProviderScope(overrides) → SynaptixApp
    → Splash → crash-recovery check → backend health gate → force-update check
      → AppLauncher → GoRouter (initialLocation: /home)
        → NavigationRedirectService (identity → login → onboarding → profile-selection → home)
```

Findings:

- **Failure fallback is broken:** if `AppInit.initialize()` throws, `main()` re-runs `SynaptixApp()` inside a `ProviderScope` **without the `serviceManagerProvider` override**. `SynaptixApp._init()` re-attempts init, but the auth/mode overrides (`isLoggedInSyncProvider`, `userAgeGroupProvider`, `synaptixModeProvider`) are never installed in that scope — a partially broken session state rather than a clean recovery. Recovery should rebuild the same override set.
- **Health gate vs offline design conflict** (see §2.1) — decide the product stance: either the game is playable offline (let the question fallback do its job, show a degraded-mode banner) or it isn't (then the local fallback layers are dead weight in release).
- **Redirect logic** (`NavigationRedirectService`) is clean and centralized 👍. Identity → onboarding → profile-selection ordering is coherent.
- **Route sprawl:** 169 `GoRoute`s in one 1,482-line `app_router.dart`. Split per feature (`quiz_routes.dart`, `admin_routes.dart`, `social_routes.dart`…) — this is also what makes dead screens (below) hard to notice.
- **Duplicate quiz entry routes:** `/quiz/play` and `/quiz/question` both construct `AdaptedQuestionScreen`; `PlayQuizScreen` survives only as the no-payload fallback of `/quiz/play`. Consolidate to one canonical launch route with typed extras.
- **Bottom-nav pushes instead of switching:** `QuestionScreen._onBottomNavTap` uses `context.push(canonicalHomeRoute)` etc., stacking screens on every tab tap instead of `go`/shell-branch switching — back-stack grows unboundedly.

### 5.2 Friends flow — Sprint 1 output is dark 🔴

`features/social/screens/friends_list_screen.dart` (+ cards, dialog, providers, service, client — the entire 1,600-LOC Sprint 1 deliverable) is **not referenced by the router or any screen**. `/friends` still builds the legacy `screens/profile/friends_screen.dart`. Users cannot reach the new system. This is the highest-leverage 1-line-ish fix in the repo (route it, then delete or migrate the legacy screen).

Compounding this, the `/friends` route is gated by `featureFlagGuard(... f.socialEnabled)`, and `AppConfig.socialEnabled` **defaults to `false`** — it only turns on if the remote `/app/config` endpoint (itself unverified, §3.2) returns `socialEnabled: true`. So Friends is doubly dark: flag off by default *and* the new UI unrouted.

---

## 6. Components & Widgets

**Working well:** the dashboard modularization is genuinely done (31 focused files + barrel; the old 1,900-line `synaptix_dashboard_widgets.dart` is now a 47-line shim). The question renderer system (8+ type views, dispatcher, power-up tray, segmented progress) is a solid foundation.

**Duplicates to consolidate** (same basename, different implementations):

| Duplicate | Locations | Keep |
|---|---|---|
| `add_friend_dialog.dart` | `features/social/widgets/` vs `screens/profile/dialogs/` | features/social (after routing fix) |
| `daily_bonus_screen.dart` | `arcade/ui/screens/` vs `screens/rewards/` | decide per product |
| `performance_chart_screen.dart` | `ui_components/analytics/` vs `screens/analytics/` | screens/analytics |
| `skill_tree_visualization.dart` | `screens/skills/` vs `screens/analytics/` | screens/skills |
| `multiplayer_providers.dart` | `game/providers/` vs `game/multiplayer/providers/` | merge |
| `arcade_providers.dart` | `game/providers/` vs `arcade/providers/` | merge |
| `ws_client.dart`, `http_client.dart`, `ws_protocol.dart`, `ws_reliability.dart` | `core/networking/` vs `game/multiplayer/data/sources/` | core/networking |

**Oversized files needing decomposition** (top offenders): `question_loader_service.dart` (2,029), `spin_earn_screen.dart` (1,677), `enhanced_profile_screen.dart` (1,615), `login_screen.dart` (1,552), `admin_user_detail_screen.dart` (1,485), `app_router.dart` (1,482), `favorites_quiz_screen.dart` (1,472), `crypto_wallet_screen.dart` (1,346).

---

## 7. Services — Broken or Needing Backend Alignment

| Service | Issue | Action |
|---|---|---|
| `question_api_service.dart` + `question_api_client.dart` | Legacy layers hitting nonexistent endpoints; `QuestionHubService` is canonical | Delete after confirming no admin flow depends on them (admin import/export screen imports the model path — verify) |
| `SynaptixApiClient` (1,160 lines) vs `synaptix_api_client_enhanced.dart` | Two clients; enhanced variant only referenced in `core_providers` | Merge/retire one |
| `backend_profile_social_service.dart` | Uses Surface-B friends endpoints (see §3.3) | Migrate to canonical surface |
| `MatchesService` `_refreshTimer` unused | 30s auto-refresh advertised in docs likely inert | Fix or remove |
| `ConfigService` | Constructs its **own** `ApiService(baseUrl: apiBaseUrl)` (not `apiV1BaseUrl`), separate cache/interceptors | Point at shared service; verify `/app/config` exists server-side |
| Realtime stack | SignalR hubs (`match/presence/notification/leaderboard/matchmaking`) **and** gRPC (`mobile.proto` + generated pb) **and** raw WS client | Pick per-feature transports deliberately; delete the unused generation path (gRPC generated code appears unreferenced by screens) |
| `ApiService` auth-path list | Missing `/matches`, `/party`, `/progression`, `/account` | Extend or unify on `AuthHttpClient` |
| Token refresh | Implemented in **both** `ApiService._refreshSessionToken` and the auth client stack; tries `/admin/auth/refresh` before `/auth/refresh` for every user | Consolidate into one refresh authority; ordering means normal users always burn a failed admin-refresh call |

---

## 8. Performance Optimization Targets

1. **Startup:** `AppInit.initialize()` is a fully serial await chain (Hive boxes → persistence → notification stores → device id → token store → ServiceManager (which serially initializes ~15 more services) → session → multi-profile). Parallelize independent groups with `Future.wait`; defer non-critical services (notifications templates, asset sync already deferred 👍) — target: cut cold-start by 30–50%.
2. **Timeout tuning + availability short-circuit** (see §2.2) — biggest perceived-performance win in the app.
3. **`allClassesStatsProvider`:** 13 sequential network round-trips → `Future.wait` + a single backend batch endpoint later.
4. **Question hub `_preloadData`** awaits two fetches serially on `initState` — parallelize or drop (providers already fetch).
5. **Bottom-nav `push` stacking** (§5.1) — memory + navigator depth.
6. **Dependency prune** (§1.4) — app size: two audio engines, two 3D stacks, camera, three realtime transports.
7. **Caching:** `dio_cache_interceptor` is initialized async *after* construction (`_initializeCache` un-awaited race — first requests may run uncached or interceptor added mid-flight); make construction async-safe.
8. Spin-wheel rendering was already optimized in Phase 1 (cache/repaint isolation) — no action.

---

## 9. Project Structure — Duplicates, Legacy, Dead Code

- **4 entrypoints:** `main.dart`, `main_mobile.dart`, `main_web.dart`, `main_with_sentry.dart` — near-identical bodies (drift already visible: only the Sentry one captures init failures). Consolidate to `main.dart` + platform detection (which `SynaptixApp`/`PlatformConfig` already do).
- **Dark features:** entire `features/social/` UI (unrouted), gRPC generated stack (unreferenced), `PlayQuizScreen` (fallback-only), `main_with_sentry.dart`.
- **Docs sprawl:** 60+ status/summary/phase docs across `docs/` root + repo root (`SPRINT1_STATUS.md`, `SESSION_SUMMARY_*`, `IMPLEMENTATION_SUMMARY.md`, `_START_HERE.md`, 19 `docs/phases/*`). Multiple docs describe the same phases with conflicting status ("Sentry ✅ Implemented"; master tracker says analyzer has "known warnings" that are now fixed/different). Consolidate: one `docs/STATUS.md` as source of truth + `docs/archive/`.
- **Legacy scripts:** `scripts/fix_all_deprecations.py`, `generate_proto.*` (if gRPC is retired), `.bat`/`.sh` build duplication.
- **Typos as landmines:** `ecryption_manager_screen.dart`, `lib/ui_components/spin_wheel/acessibility/`.
- 12 TODO/FIXME, 14 `UnimplementedError` throws (notably `core_providers.dart` — intentional guard — and `platform_config.dart`, `app_lifecycle.dart`), 9 `@Deprecated` members still referenced internally.

---

## 10. Outstanding Plans Inventory (started / not started / stalled)

| Plan | Source doc | State | Evidence |
|---|---|---|---|
| **Sprint 1 Friends** | `SPRINT1_STATUS.md` (60% claimed) | 🟠 Code complete, **unrouted**, untested; 11 `unused_result` refresh bugs | §5.2 |
| **Sprint 2 Parties** | `FUTURE_SPRINTS_FRIENDS_PARTIES_PLAN.md` | 🔴 Not started (models + `PartyApiClient` + `parties_service.dart` exist; zero screens) | `features/social/screens/` has only the friends screen |
| **Sprint 3 Social integration/polish** | same | 🔴 Not started | — |
| **Sprint 4 Realtime social** | same | 🔴 Deferred by design | — |
| **Question Phase 3 (progression integration)** | `QUESTION_SYSTEM_CURRENT_STATE.md` | 🟡 ~60% — tier XP hookup & multiplier audit unverified | needs `POST /progression/xp/award` wiring at quiz completion |
| **Question Phase 4 (advanced types)** | same | 🟡 ~70% — classification/labeling unverified; free-text UI, boss & timed variants missing | — |
| **Admin question workflow** (draft/publish, preview) | same | 🟡 Needs verification | — |
| **Phase 3 Operator Dashboard** | `docs/deferred_plans/phase3_operator_dashboard/` | 🔴 Deferred — 5 blocking architecture questions unanswered since 2026-06-28 | — |
| **Phase 4 Analytics & Monitoring** | `MASTER_TASK_TRACKING.md` | 🟡 Partial components, no backend dashboard | — |
| **Realtime config updates (WebSocket)** | master tracker | 🔴 Deferred | — |
| **Learning Hub integration** | master tracker "Next" | 🔴 Not started | `screens/learn_hub` exists as shell |
| **Web companion** | `docs/web-companion/` | 🔴 Plan only | — |
| **Skill-tree navigation fixes** | `ops/issues/skill_tree_navigation_github_issues.json` | 🟠 Issue backlog exported, not imported/executed | — |
| **Analyzer cleanup** | master tracker "Immediate" | 🟢 Mostly done — down to 26 issues | §1.2 |
| **Category metadata endpoint** | backend audit | 🔵 Optional | — |

---

# The 5-Sprint Plan (Critical → Deferred)

Assumes 1 sprint = 2 weeks, 1–2 developers. Each sprint has a theme, a definition of done, and explicitly sequenced items. Items reference audit sections.

---

## 🔴 Sprint 1 — "Make the Game Reachable & Observable" (Critical)

**Theme:** A user on a real build can reach and play a quiz, and we can see every failure in Sentry.

| # | Task | Ref | Est |
|---|---|---|---|
| 1.1 | **Resolve the release health-gate:** product decision + implementation — allow degraded/offline start (recommended: proceed with warning banner; the fallback stack already exists) or fix/deploy backend URL. Add `ALLOW_OFFLINE_BOOT` to release build docs either way | §2.1 | 2d |
| 1.2 | **Backend-availability short-circuit + timeout tuning** for question endpoints (2–3s connect timeout, shared circuit-breaker so one failure stops the 10s-per-call cascade) | §2.2 | 2d |
| 1.3 | Delete duplicate `serviceStatusProvider` (quiz_providers copy); stop `getClassStats`/`getCategoryStats` from hitting nonexistent endpoints (compute locally until backend ships them); parallelize `allClassesStatsProvider` | §2.3, §2.4, §8.3 | 2d |
| 1.4 | **Sentry live in shipped builds:** merge `main_with_sentry.dart` into `main.dart` (guarded zone, `appRunner`), add `SentryNavigatorObserver` + `sentry_dio`, DSN via `--dart-define` from GitHub Secrets, rotate committed DSN, fix unused `EnvConfig` sentry fields, correct the setup doc | §4 | 3d |
| 1.5 | **Route the Friends system:** point `/friends` at `FriendsListScreen`; fix the 11 `unused_result` refresh bugs in `social_providers.dart`; smoke-test the flow | §5.2, §1.2 | 1d |
| 1.6 | Fix remaining analyzer warnings (unused import/fields, `_refreshTimer` in `MatchesService`) + the 29 wrong-depth imports; add `always_use_package_imports` (or depth-correct) lint & make `flutter analyze` a required CI gate at 0 warnings | §1.2, §1.3 | 2d |
| 1.7 | Extend `_isProtectedPath` (or move `/matches`, `/party`, `/progression`, `/account` to the authenticated client); single token-refresh authority; user-path refresh should not try `/admin/auth/refresh` first | §3.4, §7 | 2d |

**Done when:** fresh staging build reaches a playable quiz with backend down *and* up; Sentry shows a test crash with screen breadcrumbs + HTTP spans; `flutter analyze` = 0; Friends screen reachable in-app.

---

## 🟠 Sprint 2 — "One Truthful API Layer + Question System Completion" (High)

**Theme:** Client and backend agree on every endpoint; question system phases 3–4 closed out.

| # | Task | Ref | Est |
|---|---|---|---|
| 2.1 | **API contract reconciliation:** generate a single endpoint matrix from OpenAPI spec; delete `question_api_service.dart` + `question_api_client.dart` legacy layers; migrate `getMixedQuiz` to `POST /questions/mixed`; fix misleading fallback endpoint labels | §3.2, §2.5 | 3d |
| 2.2 | **Resolve dual friends surface:** confirm backend canonical routes; migrate `backend_profile_social_service`/`SynaptixApiClient` callers or the Sprint-1 client accordingly; delete the loser; merge `synaptix_api_client_enhanced` | §3.3, §7 | 3d |
| 2.3 | **Question Phase 3 closure:** wire quiz completion → `POST /progression/xp/award`, audit difficulty multiplier application end-to-end, verify tier advancement + leaderboard scoring consistency | §10 | 3d |
| 2.4 | **Question Phase 4:** verify/fix classification & labeling renderers, add free-text UI, boss + timed variants | §10 | 3d |
| 2.5 | Friends polish backlog from Sprint-1 plan: search debouncing, unit tests for `FriendsApiClient`/providers, a11y & dark-mode pass | §10 | 2d |
| 2.6 | Verify legacy `ApiService` endpoints (`/leaderboard`, `/achievements`, `/quiz/complete`, `/app/config`, `/events/*`, `/seasons/*`) against backend; delete or fix; remove `getRequest()` double-base bug | §3.2, §3.5 | 2d |

**Done when:** every network call in `lib/` maps to a documented backend endpoint (or an intentional fallback); question→XP→tier flow verified with a real account; contract tests green.

---

## 🟡 Sprint 3 — "Social Completion & Flow Polish" (Medium-High)

**Theme:** Ship Parties; make navigation coherent.

| # | Task | Ref | Est |
|---|---|---|---|
| 3.1 | **Parties UI** (legacy plan Sprint 2): parties list screen, party detail, create dialog, invite/accept/decline/leave/disband — service + client + models already exist | §10 | 5d |
| 3.2 | Cross-system integration: challenge-friend → match creation, quick-party from friend card (legacy plan Sprint 3 scope) | §10 | 3d |
| 3.3 | **Router refactor:** split `app_router.dart` (1,482 lines / 169 routes) into per-feature route modules; remove duplicate quiz routes; retire `PlayQuizScreen` or make it the single canonical launcher | §5.1, §6 | 3d |
| 3.4 | Fix bottom-nav `push`-stacking → shell/`go` navigation; back-stack sanity pass on quiz → summary → home loop | §5.1 | 2d |
| 3.5 | Admin question workflow verification (draft/review/publish, preview renderer, bulk import validation) | §10 | 2d |
| 3.6 | Widget/provider dedup: `add_friend_dialog`, `daily_bonus_screen`, `performance_chart_screen`, `skill_tree_visualization`, `multiplayer_providers`, `arcade_providers`, ws/http clients | §6 | 2d |

**Done when:** a user can create a party, invite a friend, and start a match; router files ≤300 lines each; zero duplicate-basename widgets.

---

## 🟢 Sprint 4 — "Performance, Size & Code Health" (Medium)

**Theme:** Faster starts, smaller app, maintainable modules.

| # | Task | Ref | Est |
|---|---|---|---|
| 4.1 | Parallelize `AppInit`/`ServiceManager` init groups; measure cold-start before/after (target −30%) | §8.1 | 3d |
| 4.2 | Fix `ApiService` cache-interceptor init race; confirm cache policy per endpoint class | §8.7 | 1d |
| 4.3 | Dependency prune: choose one audio engine, one 3D stack; decide gRPC's fate (delete `protos/` + generated code if unused); measure APK/AAB delta | §1.4, §7 | 3d |
| 4.4 | Decompose the 8 files >1,300 lines (`question_loader_service` first — split dataset registry from loading logic) | §6 | 4d |
| 4.5 | Upgrade deprecated Flutter APIs (`onReorder`, `axisAlignment`); dependency upgrade wave for the 135 outdated packages (staged, with test runs) | §1.2, §1.4 | 3d |
| 4.6 | Entrypoint consolidation (delete `main_mobile/web/with_sentry` variants); fix `main()` fallback to rebuild full override set | §9, §5.1 | 1d |
| 4.7 | Docs consolidation: single STATUS.md source of truth, archive the ~60 historical phase/session docs, fix inaccurate claims (Sentry doc) | §9 | 1d |
| 4.8 | Test-suite health: fix/triage failures from this audit's `flutter test` run; add CI job running full suite; coverage report baseline | §1 | 3d |

**Done when:** cold start measurably improved; app size reduced; CI runs analyze+test on every PR; one entrypoint; docs tell one story.

---

## 🔵 Sprint 5 — "Realtime, Operator & Growth" (Deferred/Strategic)

**Theme:** The deliberately-deferred backlog, now unblocked by Sprints 1–4.

| # | Task | Ref | Est |
|---|---|---|---|
| 5.1 | Realtime social: presence (online/offline) via existing SignalR presence hub, party invite push, live friend status in FriendCard | §10 | 4d |
| 5.2 | Realtime config updates (reward/tier config refresh) — the deferred WebSocket work | §10 | 2d |
| 5.3 | **Operator Dashboard kickoff:** answer the 5 blocking architecture questions (auth model, realtime vs polling, framework, migration strategy, deployment), then execute `docs/deferred_plans/phase3_operator_dashboard/` plan | §10 | 5d+ |
| 5.4 | Analytics & monitoring dashboard (Phase 4): wire question/fallback/source metrics (already collected client-side) into backend analytics endpoints | §10 | 4d |
| 5.5 | Learning Hub integration (fills the `learn_hub` shell) | §10 | 3d |
| 5.6 | Skill-tree navigation issue backlog: import `ops/issues/skill_tree_navigation_github_issues.json` and burn down | §10 | 2d |
| 5.7 | Web companion plan review → go/no-go | §10 | 1d |

**Done when:** presence works in Friends list; operator dashboard has an approved architecture and a started implementation; analytics dashboard shows question-source health in production.

---

## Appendix A — Evidence Index

- Analyzer output: 26 issues (0 errors) — Flutter 3.44.5, 2026-07-08.
- Endpoint inventory: grep of all quoted paths across `lib/` (≈180 distinct paths) cross-referenced with `docs/api/BACKEND_API_AUDIT.md` (2026-07-03).
- Friends-screen reachability: `FriendsListScreen` has zero references outside `features/social/`; `app_router.dart:1082` routes `/friends` → `screens/profile/friends_screen.dart`.
- Sentry entrypoint usage: zero references to `main_with_sentry.dart` in `scripts/`, `run_web.sh`, `.github/workflows/*`.
- Wrong-depth import list: 29 files (§1.3); resolution behavior verified with a Dart URI-resolution test (`..` clamps at package root).
- Startup gate: `synaptix_app.dart` `_runStartupChecks`/`_allowOfflineStartup` (`kDebugMode`-only bypass without `ALLOW_OFFLINE_BOOT`).

## Appendix B — Test Run

Full `flutter test` (Flutter 3.44.5, 2026-07-08, 47m25s):

```
4,269 passed · 223 failed · 2 skipped  (~95% pass rate)
```

- ~5% of the suite fails — the suite is **not currently a reliable regression gate**, which matters because several docs claim "ready for QA" based on green targeted runs only.
- Representative failure mode (last recorded): `test/widgets/leaderboard_widgets_test.dart` — "A Timer is still pending even after the widget tree was disposed" (`!timersPending` assertion). Widgets that start timers (score displays, auto-refresh, countdowns) are not disposing them, or tests are missing `pumpAndSettle`/fake-async handling. The unused `_refreshTimer` finding in `MatchesService` (§1.2) is the same family of bug in production code.
- Action (Sprint 4, item 4.8): triage the 223 failures by suite, fix timer/dispose leaks first (they indicate production-code lifecycle bugs, not just test debt), then make the full suite a required CI gate.
