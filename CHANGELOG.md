# Changelog

All notable changes to **Trivia Tycoon** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added - Friends/social backend migration and presence playerId alignment (2026-04-15)

Completed the main frontend migration from local mock social state to the live
backend friends/presence contract, and patched the shared WebSocket connection
paths to satisfy the backend `?playerId=` requirement for presence delivery.

**Changes:**
- `lib/core/models/social/friend_list_item_dto.dart`,
  `lib/core/models/social/friend_request_dto.dart`,
  `lib/core/models/social/friend_suggestion_dto.dart`, and
  `lib/core/models/social/paginated_social_response.dart` - added typed social
  DTOs and paginated response support.
- `lib/core/services/social/backend_profile_social_service.dart` - expanded to
  cover backend friends list, incoming requests, sent requests, request send,
  accept, decline, and suggestions.
- `lib/game/providers/friends_providers.dart` - added Riverpod providers for
  backend-backed social data.
- `lib/screens/profile/friends_screen.dart` - migrated friend list, request
  inbox, suggestions, and request mutations to backend social endpoints.
- `lib/screens/profile/enhanced/add_friends_screen.dart` - add-by-username flow
  now checks backend friend/request state and sends backend-authored requests.
- `lib/screens/messages/dialogs/create_dm_dialog.dart` - message recipient
  picker now uses the backend friends roster instead of `FriendDiscoveryService`.
- `lib/core/bootstrap/app_init.dart` - shared app WebSocket initialization now
  appends `?playerId=<guid>` before connecting.
- `lib/game/providers/core_providers.dart` - `wsClientProvider` now aligns with
  the same `playerId` query-parameter requirement when a stored user id exists.

**Remaining for this workstream:**
- live runtime verification across two logged-in users/devices
- final cleanup or deprecation decision for `FriendDiscoveryService`
- formatter/analyzer/test pass in a Flutter-enabled environment

### Updated - Local web auth, onboarding profile restore, and persistence status (2026-04-14)

Closed the latest frontend-side gaps around local web auth diagnostics,
onboarding layout stability, and backend profile rehydration after emulator/data
wipes. This work also clarified the remaining backend/object-storage dependency
for portable avatar images.

**Changes:**
- `lib/core/env.dart` - confirmed web runtime rewrites `10.0.2.2` to
  `localhost` for browser-based API access.
- `assets/config/config.json` - local web API defaults aligned to
  `http://localhost:5000` instead of `https://localhost:5000`.
- `lib/core/services/analytics/config_service.dart` - local fallback/default API
  base URL aligned to `http://localhost:5000`.
- `.env.example` - updated local example API URL to the HTTP local backend path.
- `lib/screens/onboarding/steps/country_step.dart` - rebuilt onto the shared
  onboarding step shell with a scroll-safe layout to eliminate bottom overflow
  on shorter screens.
- `lib/core/services/settings/profile_sync_service.dart` - expanded profile sync
  from name/username-only to broader profile fields; added remote profile fetch
  and normalization for startup/login hydration.
- `lib/core/services/settings/player_profile_service.dart` - batch profile save
  now persists backend-hydrated preferred categories.
- `lib/screens/onboarding/onboarding_screen.dart` - onboarding completion now
  syncs country, age group, categories, Synaptix mode, preferred surface, and
  syncable avatar references to backend in addition to local Hive saves.
- `lib/game/providers/auth_providers.dart` - login/signup now attempt remote
  profile hydration after auth succeeds.
- `lib/core/bootstrap/app_init.dart` - logged-in bootstrap now prefers backend
  profile hydration and retries queued profile sync updates before falling back
  to local Hive-only state.

**Status note:**
- Profile text/preferences now persist locally and are wired to persist to the
  backend when the backend profile endpoint supports the normalized payload.
- Portable avatar image persistence is still **not complete** for picked device
  files; that requires a backend-backed upload flow (for example via MinIO) so
  the frontend can store a stable object URL/key instead of a local file path.

### Added - Alpha handoff partial frontend/backend wiring completion (2026-04-12)

Closed the remaining alpha handoff items that were already partly underway on
the frontend store/profile surfaces.

**Changes:**
- `lib/core/services/store/store_service.dart` - added `POST /store/iap/validate`
  client support.
- `lib/core/services/social/backend_profile_social_service.dart` - new backend-facing
  profile/social client for user search, career summary, loadout, and unfriend flows.
- `lib/game/providers/profile_providers.dart` - added Riverpod providers for the new
  backend profile/social service plus loadout/career-summary fetches.
- `lib/screens/profile/enhanced/add_friends_screen.dart` - "add by username" now
  searches through `GET /users/search?handle=`.
- `lib/screens/profile/friends_screen.dart` - remove-friend action now calls
  `DELETE /friends`.
- `lib/screens/profile/enhanced/enhanced_profile_screen.dart` - enhanced profile now
  hydrates from backend career-summary and loadout endpoints when available.
- `lib/screens/profile/enhanced/sheets/edit_profile_bottom_sheet.dart` - profile edits
  now push backend loadout updates.
- `test/core/services/backend_profile_social_service_test.dart` - added request-contract
  coverage for search, career summary, loadout save, and unfriend routes.
- `test/core/services/store_service_payment_flows_test.dart` - added IAP validation
  request-path coverage.

### Added - Question gameplay backend contract migration (2026-04-12)

Moved quiz gameplay onto the alpha question contracts for retrieval and
authoritative answer validation while keeping legacy/local fallback behavior.

**Changes:**
- `lib/core/models/question_validation_models.dart` - added shared submission/result
  models for backend answer validation.
- `lib/game/services/question_hub_service.dart` - quiz retrieval now prefers
  `GET /questions/set`; answer validation and reconciliation now use
  `/questions/check` and `/questions/check-batch`.
- `lib/core/repositories/question_repository.dart` and
  `lib/game/repositories/question_repository_impl.dart` - added repository methods
  for per-answer and batched validation.
- `lib/game/state/quiz_state.dart` - adapted quiz flow now validates answers through
  the repository and stores submissions for end-of-quiz reconciliation.
- `lib/game/controllers/question_controller.dart` and
  `lib/game/controllers/game_controller.dart` - answer resolution now uses backend
  validation instead of local-only `correctAnswer` checks.
- `lib/screens/question/question_view_screen.dart` and
  `lib/screens/question/adapted_question_screen.dart` - feedback/result flows now
  consume authoritative validation results.
- `test/game/services/question_hub_service_test.dart` and
  `test/game/repositories/question_repository_impl_test.dart` - extended coverage
  for backend validation and repository delegation.

### Added - Store payments return routing and app-link wiring (2026-04-12)

Implemented the frontend-side completion path for external store payments and
subscriptions so Stripe and PayPal returns can finish inside the app instead of
ending at a dead browser redirect.

**Changes:**
- `lib/core/services/store/store_service.dart` - expanded store/payment endpoint coverage
  for one-time purchases, subscriptions, status refresh, PayPal capture, and Stripe portal flows.
- `lib/screens/store/store_screen.dart` and `lib/screens/store/offers_screen.dart` - wired
  store UI actions to backend payment/subscription endpoints and refresh flows.
- `lib/screens/store/store_payment_return_screen.dart` - added a dedicated in-app return
  screen for provider success/cancel/pending handling.
- `lib/core/navigation/app_router.dart` - added `/store/payment-return` and
  `/store/subscription-return` routes.
- `lib/core/services/store/store_return_url_builder.dart` - centralized return/cancel
  URL generation from environment config.
- `lib/core/env.dart` and `.env.example` - added `APP_REDIRECT_BASE_URL` support.

### Added - Android/iOS hosted app-link artifacts and runtime routing (2026-04-12)

Prepared the minimal hosted-domain and mobile configuration needed for verified
App Links / Universal Links on the production payment-return domain.

**Changes:**
- `android/app/src/main/AndroidManifest.xml` - added verified intent filters for
  `/store/payment-return` and `/store/subscription-return`.
- `ios/Runner/Runner.entitlements` and `ios/Runner.xcodeproj/project.pbxproj` - added
  associated-domains support and entitlements wiring.
- `docs/app-links/assetlinks.json` and `docs/app-links/apple-app-site-association` -
  added hosted verification templates.
- `docs/app-links/README.md` - added deployment checklist for hosted verification.
- `pubspec.yaml` / `pubspec.lock` - added `app_links`.
- `lib/core/services/store/store_link_router.dart` - added URI-to-route mapping for
  supported payment/subscription return URLs.
- `lib/core/bootstrap/app_launcher.dart` - added initial-link handling, foreground
  link-stream handling, deferred routing until GoRouter is ready, and fallback
  guards for `MissingPluginException` / `PlatformException`.

**Operational note:**
- After adding `app_links`, Android requires a full native rebuild/reinstall.
  Hot reload or hot restart against an older APK can produce:
  `MissingPluginException(No implementation found for method listen on channel com.llfbandit.app_links/events)`.

### Added - Payment/app-link tests (2026-04-12)

- `test/core/services/store_return_url_builder_test.dart` - verifies payment/subscription
  return URL generation.
- `test/core/services/store_link_router_test.dart` - verifies incoming-link mapping to app routes.
- `test/screens/store/store_payment_return_screen_test.dart` - verifies return-screen flow handling.
- `test/core/services/store_service_payment_flows_test.dart` - verifies the PayPal
  subscription cancel request path and payload.
- `test/core/services/api_service_test.dart` - adds protected store-route coverage for:
  - wrong-player ownership `403 FORBIDDEN` envelopes
  - provider-disabled / unavailable `503 Service Unavailable` envelopes

### Added - Phase 2 crash recovery completion pass (2026-04-12)

Completed the remaining code-side recovery and notification persistence work that
was still open in the backlog.

**Changes:**
- `lib/core/services/crash_recovery_service.dart` - new focused restore service for
  persisted quiz/player/profile session recovery.
- `lib/main.dart` - recovery flow now restores real persisted state instead of only logging.
- `lib/core/services/state_persistence_service.dart` - recovery summary now includes
  user-session data; crash flag is cleared after successful restore handling.
- `lib/core/bootstrap/app_init.dart` - startup now loads persisted notification stores.
- `lib/game/providers/notification_history_store.dart` - notification history is now persisted and reloadable.
- `test/core/services/crash_recovery_service_test.dart` - verifies persisted recovery restore behavior.
- `test/game/providers/notification_history_store_test.dart` - verifies notification history/template reload behavior.

### Updated - Phase 2 backlog status and implementation notes (2026-04-12)

- `docs/REMAINING_TASKS.md` - updated Phase 2 from partial to code-complete, with
  device validation still pending.
- Avatar-cropping backlog item reclassified as complete after verifying the active
  centered square crop + JPEG re-encode flow in
  `lib/game/controllers/profile_avatar_controller.dart`.

### Fixed – Flutter web / Edge browser startup failure (2026-04-09)

Root cause: `lib/core/services/api_service.dart` unconditionally imported `dart:io`
and `package:path_provider/path_provider.dart`. On Flutter web (DDC), this caused a
module-cascade failure at startup: `service_manager.dart` → `app_init.dart` failed to
initialize, producing the misleading DDC error
`"Library not defined: …/referral_invite_adapter.dart"`.
A secondary cascade from `auth_error_messages.dart` (`import 'dart:io'` for
`SocketException`/`HttpException`) also caused `auth_providers.dart` → `main.dart`
to fail. Both failures affected all web browsers equally (Chrome, Edge, etc.).

**Changes:**
- `lib/core/services/_api_cache_store.dart` — new web stub: returns `MemCacheStore()`
- `lib/core/services/_api_cache_store_io.dart` — new native helper: returns
  `HiveCacheStore(tempDir.path)` (keeps Hive-backed persistence on iOS/Android/desktop)
- `lib/core/services/api_service.dart` — removed `import 'dart:io'`,
  `import 'package:path_provider/…'`, `import 'package:http_cache_hive_store/…'`;
  added `import '_api_cache_store.dart' if (dart.library.io) '_api_cache_store_io.dart'`;
  `_initializeCache()` now calls `await createCacheStore()`.
- `lib/core/services/auth_error_messages.dart` — removed `import 'dart:io'`;
  `SocketException`/`HttpException` type checks replaced with `runtimeType.toString()`
  and `toString().startsWith(…)` guards, which work identically on all platforms.
- `web/index.html` — title and `apple-mobile-web-app-title` updated from
  `trivia_tycoon` → `Synaptix`.
- `web/manifest.json` — `name`, `short_name`, and `description` updated to Synaptix
  branding.

### Added – Phase 3: Test Coverage Pass 2 (2026-04-09)

6 new test files covering the remaining untested arcade controllers and services.
Test file count increased from 39 → **45** files.

#### New test files

| File | Coverage |
|------|----------|
| `test/arcade/games/memory_flip_controller_test.dart` | `MemoryFlipController` — deck structure (gridSize per difficulty, pair ids, card indices), `flip()` (first/match/miss/ignored), `allMatched→isOver`, score bounds, `toResult()` metadata, `dispose()` |
| `test/arcade/games/pattern_sprint_controller_test.dart` | `PatternSprintController` — initial state, `answer()` correct/wrong/lock, streak multiplier, `maxStreak`, question generation correctness across all difficulties (answer in options, no duplicates, `'?'` in sequence), `toResult()` accuracy, `dispose()` |
| `test/arcade/services/arcade_session_service_test.dart` | `ArcadeSessionService` — `startSession()` timestamp bounds, `endSession()` duration bounds, `attachDuration()` field copy fidelity |
| `test/core/services/presence/typing_indicator_service_test.dart` | `TypingIndicatorService` — `isAnyoneTyping`, `isCurrentUserTyping`, `startTyping`, `stopTyping`, peer typing via `updateUserTypingStatus`, `handleTextInput`, `handleMessageSent`, `clearConversationTyping`, `getTypingText`, `getTypingStats` |
| `test/arcade/services/arcade_registry_test.dart` | `ArcadeRegistry` — 3 game definitions, IDs, titles, subtitles, `supportedDifficulties`, builder non-null, all `ArcadeGameId` values represented |
| `test/arcade/leaderboards/local_arcade_leaderboard_service_test.dart` | `LocalArcadeLeaderboardService` — `recordRun()`, `top()` sort order (score DESC / duration ASC), limit, `best()`, `wouldBeNewBest()`, `clearBoard()`, `clearAll()`, `topForGame()`, persistence across re-creation |

### Fixed – Phase 2: UnimplementedError documentation (2026-04-09)

- `lib/game/providers/core_providers.dart` (`serviceManagerProvider`) — added doc
  comment clarifying that the `UnimplementedError` is an intentional design-time guard
  overridden at app startup; not a production bug.
- `lib/core/services/analytics/app_lifecycle.dart` (`appLifecycleProvider`) — same
  treatment; doc comment clarifies override via `AppLifecycleObserver`.
- `lib/screens/rewards/spin_earn_screen.dart` — removed stale comment that referenced
  a replaced `UnimplementedError` (the actual implementation was already in place).

### Added – Remaining Tasks tracking document (2026-04-09)

- `docs/REMAINING_TASKS.md` — new canonical backlog file. Lists every remaining
  task with file paths, specific methods, and priority. Covers: Phase 2 crash recovery
  stubs, Phase 3 test coverage gaps (9 specific classes), Phase 4 dependency audit,
  Sprint 1/2 networking, Synaptix runtime validation, Backend Packet E.

### Added – Phase 3: Test Coverage (2026-04-09)

8 new test files covering previously untested subsystems. Test file count increased
from 31 → 39 files. Coverage now spans all major game and arcade service layers.

#### New test files

| File | Coverage |
|------|----------|
| `test/game/controllers/power_up_controller_test.dart` | `PowerUpController` — activate, clear, usePowerUp, isEquipped, isExpired, getRemainingTime, restoreFromStorage, equipById, loadEquipped, checkAndClearIfExpired |
| `test/game/services/challenge_service_test.dart` | `ChallengeService` — getChallenges (all types), caching, cache invalidation, refresh times, updateProgress, Challenge model properties |
| `test/arcade/services/arcade_rewards_service_test.dart` | `ArcadeRewardsService` — output bounds, difficulty scaling, time bonus, per-game tuning knobs, coins proportional to XP |
| `test/arcade/services/arcade_daily_bonus_service_test.dart` | `ArcadeDailyBonusService` — initial state, tryClaimToday (first/second claim), streak continuity (yesterday/gap), reward schedule (Day 7 cap), previewTomorrowReward, serialization |
| `test/arcade/services/arcade_mission_claim_service_test.dart` | `ArcadeMissionClaimService` — isClaimedToday, markClaimedToday (single/multiple/idempotent), persistence across re-creation, clearToday |
| `test/arcade/services/arcade_personal_best_service_test.dart` | `ArcadePersonalBestService` — getBest (initial zero), trySetBest (accept/reject/no-decrease), per-difficulty/per-game isolation, persistence across re-creation |
| `test/arcade/missions/arcade_mission_service_test.dart` | `ArcadeMissionService` — initial load, progressFor, onArcadeRunCompleted (playRuns/scoreAtLeast/setNewPb), canClaim, tryClaim (anti-double-claim), markClaimed, progressRatio, missionsForTier, mergeById/preferLocal policies, refreshFromBackend; `ArcadeMission`/`ArcadeMissionProgress` serialisation; `ArcadeMissionCatalog` validation |
| `test/arcade/games/quick_math_controller_test.dart` | `QuickMathController` — initial state, correct/wrong answer scoring, streak tracking, score bounds, score never negative, toResult() metadata, mathematical correctness (subtraction non-negative for easy/normal, division always integer), optionCount, `QuickMathConfig` per difficulty, dispose |

#### Test patterns
- Manual fakes (extends `GeneralKeyValueStorageService`) for Riverpod provider override tests
- Hive temp-directory isolation (per test `setUp`/`tearDown`) for `AppCacheService`-backed services
- Seeded `Random` for deterministic question-generation tests
- `ProviderContainer` with `overrideWithValue()` for controller isolation

### Added – Phase 5: Riverpod barrel refactor (2026-04-09)

- `lib/game/providers/riverpod_providers.dart` converted from 883-line monolith to a
  40-line pure barrel re-exporter of 16 specialized provider modules.
- Circular import chain eliminated: 9 provider files updated to import their specific
  dependency module instead of the barrel.
- Zero provider duplication — each provider is defined exactly once.

### Added – Phase 6: Source-code TODO resolution (2026-04-09)

- All 53 source-code TODO/FIXME comments resolved. Dart source count: **0**.
- Hub widget TODOs: `hub_daily_quest`, `hub_featured_match`, `hub_live_ticker` — all
  replaced with provider-driven / data-driven implementations.
- App rename: `TriviaTycoonApp` → `SynaptixApp` completed in `lib/main.dart`.

### Added – 3D renderer improvements (2026-04-09)

Implemented all 5 TODO items in `lib/animations/ui/widget_model.dart`:

- **Multi-object support** — `parse()` now returns `Map<String, VertexMesh>` keyed by
  sub-object name (`o` directive). `MultiMeshCustomPainter` renders all sub-objects.
- **Smooth shading** — `s` directive parsed as shading-group per OBJ spec. Two-pass
  geometric normal averaging produces smooth curved surfaces on `flutter_dash.obj`
  and `cartoon_character.obj`.
- **Load-time scale** — `OBJLoader` and `loadVertexMeshFromOBJAsset` accept a `scale`
  parameter applied to all vertex positions at parse time.
- **Vertex deduplication** — canonical key dedup with smooth-shaded vertices excluding
  the normal component to enable cross-face merging.
- **GPU-aware texture atlas** — 512 px/cell cap, 2048 × 2048 total warn threshold.
  Single-texture fast path bypasses atlas entirely.
- **`shouldRepaint` state diff** — per-instance dirty flag prevents unnecessary repaints.

### Fixed – API service dual HTTP import (2026-04-09)

- `lib/core/services/api_service.dart` — removed unused `http` import; `getRequest()`
  now uses the already-present `Dio` client throughout.

---

### Added – `windows/runner` enhancements

#### 1. Branding Customizations (`Runner.rc`)
- Updated `CompanyName` from the internal bundle ID to the full human-readable
  name **"Theoretical Minds Technologies"**.
- Updated `FileDescription` to **"Trivia Tycoon - Interactive Trivia Game"**
  to give Windows users a clear description in Explorer properties.
- All other version fields (`LegalCopyright`, `ProductName`, `OriginalFilename`)
  were already correct and are left unchanged.

#### 2. Build Configuration (`runner/CMakeLists.txt`)
- Added a `TRIVIA_TYCOON_DEBUG_BUILD` preprocessor definition that is set only
  for `Debug` configurations, enabling conditional debug code paths in C++.
- Source file list is clearly delimited to make it easy to append new `.cpp`
  files in future feature work.

#### 3. Runtime Configuration (`utils.h` / `utils.cpp`)
- Introduced `LogLevel` enum (`kInfo`, `kWarning`, `kError`, `kVerbose`) for
  structured console output.
- Added `LogMessage(LogLevel, const std::string&)` helper that prefixes each
  message with the application name and log level and forwards it to both
  `OutputDebugStringA` and `stdout`.
- `CreateAndAttachConsole` now checks the return value of `freopen_s` and
  emits verbose `OutputDebugStringA` diagnostics on failure, as well as
  reporting the Win32 error code when `AllocConsole` fails.
- Added `HasCommandLineFlag(args, flag)` – returns `true` when an exact flag
  (e.g. `--verbose`) is present in the argument list.
- Added `GetCommandLineFlagValue(args, key, default)` – extracts the value from
  a `--key=value` argument pair, returning `default` when the key is absent.

#### 4. Environment Variable Support (`main.cpp`)
- Reads the `TRIVIA_TYCOON_ENV` environment variable at startup.  When set,
  its value is forwarded to the Dart entry-point as `--trivia-env=<value>`,
  allowing runtime environment switching (e.g. `staging`, `production`).

#### 5. Performance Optimizations (`main.cpp`)
- Calls `SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL)`
  on the UI thread at startup to deliver smoother Flutter animations.
- Pre-loads common OS resources (`IDI_APPLICATION`, `IDC_ARROW`) before the
  window is created, priming the OS resource cache and reducing first-paint
  latency.

#### 6. DPI and Theme Awareness (`win32_window.cpp`)
- `runner.exe.manifest` already declared `PerMonitorV2` DPI awareness; no
  change required.
- Added handling of `WM_SETTINGCHANGE` to call `UpdateTheme()` whenever the
  system broadcasts an `ImmersiveColorSet` notification, ensuring the window
  frame switches between light and dark mode without requiring a restart.

#### 7. Keyboard Shortcuts (`win32_window.cpp`)
- Added `WM_KEYDOWN` handler: pressing **F1** posts `WM_APP` to the window,
  which is caught by `FlutterWindow::MessageHandler` and forwarded to the
  Flutter engine as a platform message on channel
  `com.theoreticalmindstech/shortcuts` with payload `"help"`.

#### 8. Accessibility Support (`win32_window.cpp`)
- Added a `WM_GETOBJECT` case so that the window is visible to UI Automation
  and screen-reader tools.  The default `DefWindowProc` response provides the
  standard UIA root element.

#### 9. Flutter-Specific Optimizations (`flutter_window.cpp` / `flutter_window.h`)
- Enforces minimum window size of **800 × 600** logical pixels and a maximum
  of **3840 × 2160** (4K), both scaled by the current monitor DPI.
  Implemented via `WM_GETMINMAXINFO` using `FlutterDesktopGetDpiForHWND`.
- Added `WM_APP` handler in `FlutterWindow::MessageHandler` to relay the F1
  shortcut to the Dart layer via `SendPlatformMessage`.
- Added `<flutter_windows.h>` include to `flutter_window.h` to expose
  `FlutterDesktopGetDpiForHWND`.

#### 10. Window Title
- Changed the Win32 window title from the internal package name `trivia_tycoon`
  to the branded title **"Trivia Tycoon"** in `main.cpp`.
