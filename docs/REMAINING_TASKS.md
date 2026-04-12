# Remaining Tasks & Work Backlog

_Last updated: 2026-04-12 (updated: Phase 2 completion pass)_

> This file is the canonical "what is left to do" reference.
> For completed work, see [`docs/ALPHA_TASK_AUDIT.md`](ALPHA_TASK_AUDIT.md).
> For the full project status report, see the plan file at `/root/.claude/plans/mellow-wiggling-hopper.md`.

---

## Summary Table

| Area | Priority | Status | Blocked? |
|------|----------|--------|----------|
| Phase 2 — Crash recovery stubs | 🔴 High | Code complete; device validation pending | No |
| Phase 3 — Test coverage (remaining gaps) | 🟡 Medium | ~4.1% → 40% target | No |
| Phase 4 — Dependency audit | 🟡 Medium | Partial | No |
| Sprint 1 — Auth integration verification | 🟡 Medium | Unknown | No |
| Sprint 2 — Networking layer | 🔴 High | Not started | No |
| Synaptix runtime validation | 🟡 Medium | Blocked | ✅ Needs device + backend |
| Backend Packet E | ⬇ Deferred | Not started | Intentional deferral |

---

## 1. Phase 2 — Crash Recovery + Core Stubs

### 1a. Crash recovery state restoration ✅ COMPLETE
- **Files:** `lib/main.dart`, `lib/core/services/crash_recovery_service.dart`,
  `lib/core/services/state_persistence_service.dart`
- **Completed:** Crash/restart recovery now rehydrates saved quiz progress, player progress,
  and persisted profile/session metadata. Recovery acceptance also clears the crash flag so
  the restore prompt does not loop on the next clean launch.

### 1b. Notification persistence ✅ COMPLETE
- **Files:** `lib/core/bootstrap/app_init.dart`,
  `lib/game/providers/notification_history_store.dart`,
  `lib/game/providers/notification_template_store.dart`
- **Completed:** Notification templates and notification history are now restored from
  persistent storage during app bootstrap, so restart no longer drops the in-app notification
  context/history used by the admin and notification surfaces.

### 1c. Profile avatar cropping ✅ COMPLETE
- **Files:** `lib/game/controllers/profile_avatar_controller.dart`
- **Completed:** The active avatar picker flow already performs a centered square crop and
  JPEG re-encode before persisting the chosen avatar path. This backlog item was stale and has
  been reclassified as complete.

### 1d. Remaining UnimplementedError throws ✅ RESOLVED

| File | Line | Detail | Resolution |
|------|------|--------|------------|
| `lib/game/providers/core_providers.dart` | 41 | Provider stub | Intentional design-time guard; doc comment added clarifying it is overridden at startup |
| `lib/core/services/analytics/app_lifecycle.dart` | 18 | Lifecycle provider stub | Intentional design-time guard; doc comment added clarifying override via `AppLifecycleObserver` |
| `lib/screens/rewards/spin_earn_screen.dart` | — | Stale comment referencing a replaced UnimplementedError | Stale comment removed |

---

## 2. Phase 3 — Test Coverage Remaining Gaps

**Current:** 45 test files / 1,088 source files ≈ **4.1%** (target: **40%** on `lib/game/` and `lib/core/`)

### 2a. Arcade game controllers ✅ COMPLETE

| File added | Coverage |
|---|---|
| `test/arcade/games/memory_flip_controller_test.dart` | `MemoryFlipController` — initial state, deck structure, `flip()` (first/match/miss/ignored), `allMatched→isOver`, `toResult()`, `dispose()` |
| `test/arcade/games/pattern_sprint_controller_test.dart` | `PatternSprintController` — initial state, `answer()` (correct/wrong/lock), streak multiplier, question generation across all difficulties, `toResult()`, `dispose()` |

### 2b. Presence services (not yet tested)

#### `RichPresenceService` (`lib/core/services/presence/rich_presence_service.dart`, 357 lines)
- **Dependency:** Singleton — test using `initialize(useWebSocket: false)` (legacy polling mode)
  to avoid real WebSocket connections.

| Method / scenario | What to test |
|---|---|
| `initialize(useWebSocket: false)` | `currentUserPresence` is not null after init |
| `updateCurrentUserPresence()` | `currentUserPresence` reflects new status/activity |
| `setGameActivity()` | Presence activity updated; notifies listeners |
| `clearGameActivity()` | Activity cleared; notifies listeners |
| `canUserJoinGame(userId)` | Returns `true` when user is `online`/`idle`; `false` when `inGame`/`offline` |
| `watchUserPresence(userId)` | Stream emits when `updateFriendPresence` is called |
| `dispose()` | No throw; timers cancelled |

#### `TypingIndicatorService` ✅ COMPLETE
- `test/core/services/presence/typing_indicator_service_test.dart` added
- Coverage: `isAnyoneTyping`, `isCurrentUserTyping`, `startTyping`, `stopTyping`,
  `updateUserTypingStatus`, `handleTextInput`, `handleMessageSent`, `clearConversationTyping`,
  `getTypingText`, `getTypingStats`

### 2c. Auth flow edge cases (not yet tested)
- Social login flows (OAuth token injection, account linking)
- Token refresh when `AuthHttpClient` encounters a 401 on a concurrent request
- Offline login attempt (cached credentials vs. no cache)
- Logout clears all stored tokens and in-memory state

### 2d. Widget tree tests (not yet tested)
- Leaderboard screen renders `AnimatedRankBadge` and `EnhancedScoreDisplay` correctly
  (basic rendering exists in `test/widgets/leaderboard_widgets_test.dart` — extend with
  interaction tests)
- `ArcadeGameShell` mounts the correct game widget for each `ArcadeGameId`
- `DailyBonusScreen` renders correct coins/gems/streak values from `ArcadeDailyBonusService`
- `ArcadeMissionsScreen` renders claimed vs. unclaimed missions correctly

### 2e. Other service gaps ✅ COMPLETE

| File added | Coverage |
|---|---|
| `test/arcade/services/arcade_session_service_test.dart` | `startSession()`, `endSession()`, `attachDuration()` |
| `test/arcade/services/arcade_registry_test.dart` | All 3 game definitions, IDs, titles, difficulties, `ArcadeGameId` completeness |
| `test/arcade/leaderboards/local_arcade_leaderboard_service_test.dart` | `recordRun()`, `top()` (sort order, limit), `best()`, `wouldBeNewBest()`, `clearBoard()`, `clearAll()`, persistence, `topForGame()` |

---

## 3. Phase 4 — Dependency Audit

### 3a. Outdated packages
- **Action:** Run `flutter pub outdated` in a Flutter-enabled environment.
- **Goal:** Apply security fixes; identify packages with breaking-change upgrades.
- **Note:** `just_audio` (music streaming) and `flutter_soloud` (low-latency SFX) are
  intentionally kept separate — different use cases, not consolidatable.

### 3b. Unused transitive dependencies
- **Action:** Run `flutter pub deps --style=compact` and cross-reference with imports.
- **Goal:** Remove any transitive packages pulled in by old features that were removed.

---

## 4. Sprint 1 — P2 Auth Integration Verification

Status is unknown — may already be complete. Needs explicit verification:

- [ ] `AuthHttpClient` provider is registered in the Riverpod provider graph (confirm in
  `lib/game/providers/core_providers.dart` or `auth_providers.dart`)
- [ ] Login screen shows correct error messages for 401, 403, 422, network timeout
- [ ] Signup screen validates and surfaces backend error codes
- [ ] Auto-refresh (token renewal on 401) tested end-to-end with a live or stub backend

---

## 5. Sprint 2 — Networking Layer

Not started. Estimated ~70 min.

- [ ] Copy 4 networking files into `lib/core/networking/`
- [ ] Add `web_socket_channel` and `uuid` to `pubspec.yaml`
- [ ] Add 3 new Riverpod providers (WebSocket connection, message stream, reconnect logic)
- [ ] Integrate with existing HTTP layer (`AuthHttpClient` → `HttpClient` → WebSocket upgrade)

---

## 6. Synaptix Runtime Validation

**Blocked** — requires a running physical/simulator device and a live backend.
Curl CONNECT tunnel failure blocks live smoke-checking in CI. Flutter SDK not on PATH in CI.

- [ ] App launch — no crash, no ANR
- [ ] Auth/bootstrap flow — login, token refresh, session establishment
- [ ] Onboarding — age group selection → mode mapping (`Kids`/`Teen`/`Adult`)
- [ ] Hub rendering — correct mode-specific content for each Synaptix mode
- [ ] Arena/Labs/Pathways/Journey/Circles/Command navigation — all routes reachable
- [ ] Brand validation — no visible "Trivia Tycoon" strings anywhere in the UI
- [ ] Retention hooks — daily bonus prompt, mission notification after first session
- [ ] Premium Hub — upgrade prompt, feature gating, paywall rendering

---

## 7. Synaptix Backend — Packet E (Deferred)

Intentionally deferred to after Alpha launch. No urgency.

- [ ] Namespace rename: `Tycoon.Backend.*` → `Synaptix.Backend.*` across all backend projects
- [ ] Service/telemetry identifier rename
- [ ] Docker/CI/issuer/audience configuration naming cleanup

---

## 8. Web Platform — Remaining `dart:io` Screen Files

**Startup fixed ✅** — `api_service.dart` and `auth_error_messages.dart` no longer import
`dart:io`, eliminating the startup cascade failure on web.

The following files still import `dart:io` unconditionally. They are **not** in the startup
path so the app loads on web, but these screens/features will throw when visited on web:

| File | Used in | Impact on web |
|------|---------|---------------|
| `lib/ui_components/spin_wheel/services/prize_log_export_service.dart` | Spin-wheel export | File export will fail |
| `lib/ui_components/shimmer_avatar/widgets/avatar_content.dart` | Avatar display | Avatar widget will throw |
| `lib/ui_components/shimmer_avatar/utils/avatar_helpers.dart` | Avatar helpers | Avatar feature will throw |
| `lib/ui_components/profile_avatar/profile_image_picker.dart` | Avatar upload | File picker unavailable on web |
| `lib/ui_components/depth_card_3d/core/depth_card_3d.dart` | 3D cards | May throw if `dart:io` class is instantiated |
| `lib/ui_components/confetti/utils/confetti_log_manager.dart` | Confetti debug overlay | Debug-only; low impact |
| `lib/ui_components/color_picker/utils/color_log_manager.dart` | Color picker | Debug-only; low impact |
| `lib/screens/profile/widgets/profile_avatar_preview.dart` | Profile screen | Avatar preview will throw |
| `lib/screens/profile/widgets/shimmer_avatar.dart` | Profile screen | Shimmer avatar will throw |
| `lib/screens/profile/widgets/avatar_image_card.dart` | Profile screen | Avatar card will throw |
| `lib/screens/profile/widgets/avatar_package_image.dart` | Profile screen | Avatar image will throw |
| `lib/screens/profile/tabs/collection_tab.dart` | Profile → Collections tab | Collections tab will throw |
| `lib/game/services/avatar_package_service.dart` | Avatar packages | Service will throw on web |
| `lib/game/services/collection_items_loader.dart` | Collection items | Loader will throw on web |
| `lib/game/controllers/profile_avatar_controller.dart` | Profile avatar | Controller will throw on web |
| `lib/admin/widgets/encrypted_file_preview.dart` | Admin | Admin only; low web priority |
| `lib/admin/widgets/question_editor_form.dart` | Admin | Admin only; low web priority |
| `lib/admin/questions/question_list_screen.dart` | Admin | Admin only; low web priority |
| `lib/admin/questions/file_import_export_screen.dart` | Admin | Admin only; low web priority |

**Recommended action:** For each file, either add `kIsWeb` guards around file-system calls
or use conditional imports to provide web-safe stubs.

---

## Release Readiness Checklist

| Item | Status |
|------|--------|
| Zero `debugPrint` in production business logic | ✅ Done |
| Zero `UnimplementedError` in user-facing paths | ✅ §1d resolved — intentional design-time guards documented |
| Web startup crash (`dart:io` cascade) | ✅ Fixed — `api_service.dart` + `auth_error_messages.dart` |
| Crash recovery tested on iOS and Android | ❌ Not implemented |
| Test coverage ≥ 40% on `lib/game/` and `lib/core/` | ❌ ~4.1% currently (45 test files) |
| No critical CVEs in dependency tree | ⏳ Needs `flutter pub outdated` run |
| No single Dart file exceeds 1,700 lines | ✅ Done |
| CI pipeline enforces coverage + lint + no raw prints | ❌ Not configured |
| All source-code TODO/FIXME resolved | ✅ Done (0 remaining) |
| Runtime validation of all Synaptix screens | ❌ Blocked (needs device) |
| Sprint 2 networking layer | ❌ Not started |
| Remaining `dart:io` in screen-level files (web) | ⏳ 19 files — app loads, affected screens throw |
