# Changelog

All notable changes to **Trivia Tycoon** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

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
