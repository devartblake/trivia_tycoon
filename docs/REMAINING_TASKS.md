# Remaining Tasks & Work Backlog

_Last updated: 2026-04-09_

> This file is the canonical "what is left to do" reference.
> For completed work, see [`docs/ALPHA_TASK_AUDIT.md`](ALPHA_TASK_AUDIT.md).
> For the full project status report, see the plan file at `/root/.claude/plans/mellow-wiggling-hopper.md`.

---

## Summary Table

| Area | Priority | Status | Blocked? |
|------|----------|--------|----------|
| Phase 2 — Crash recovery stubs | 🔴 High | ~70% complete | No |
| Phase 3 — Test coverage (remaining gaps) | 🟡 Medium | ~3.6% → 40% target | No |
| Phase 4 — Dependency audit | 🟡 Medium | Partial | No |
| Sprint 1 — Auth integration verification | 🟡 Medium | Unknown | No |
| Sprint 2 — Networking layer | 🔴 High | Not started | No |
| Synaptix runtime validation | 🟡 Medium | Blocked | ✅ Needs device + backend |
| Backend Packet E | ⬇ Deferred | Not started | Intentional deferral |

---

## 1. Phase 2 — Crash Recovery + Core Stubs

### 1a. Crash recovery state restoration
- **File:** `lib/main.dart:264`
- **What's missing:** On crash/restart, the app does not restore in-progress game state. The
  restoration hook is present but the body is a stub.
- **Action:** Implement state snapshot on key game events; restore from snapshot in the
  `main.dart` startup sequence.

### 1b. Notification persistence
- **File:** Notification service (template storage)
- **What's missing:** Push notification payloads are processed but not persisted to storage.
  If the app restarts mid-session, queued notifications are lost.
- **Action:** Store notification templates in Hive/AppCacheService; replay on restart.

### 1c. Profile avatar cropping
- **What's missing:** Current avatar upload uses a temporary workaround. Proper crop/resize
  flow (using an image cropper plugin) is not implemented.
- **Action:** Integrate a crop widget; replace temp fix with the proper crop → upload pipeline.

### 1d. Remaining UnimplementedError throws

| File | Line | Detail |
|------|------|--------|
| `lib/game/providers/core_providers.dart` | 41 | Provider stub — throws at runtime if reached |
| `lib/core/services/analytics/app_lifecycle.dart` | 18 | Analytics lifecycle hook stub |
| `lib/screens/rewards/spin_earn_screen.dart` | — | Comment only (no actual throw); verify and remove comment |

---

## 2. Phase 3 — Test Coverage Remaining Gaps

**Current:** 39 test files / 1,088 source files ≈ **3.6%** (target: **40%** on `lib/game/` and `lib/core/`)

### 2a. Arcade game controllers (not yet tested)

#### `MemoryFlipController` (`lib/arcade/games/memory_flip/memory_flip_controller.dart`, 251 lines)
| Method / scenario | What to test |
|---|---|
| `start()` | Timer ticks decrement `remaining`; `isOver` set when time runs out |
| `flip(index)` | Returns `'match'`/`'miss'`; matched pairs stay face-up; `inputLocked` during resolution |
| `flip` — all pairs matched | `allMatched` → `isOver` before timer expires |
| `toResult()` | `gameId == memoryFlip`; metadata contains `matches`, `moves`, `misses`, `accuracy` |
| `dispose()` | No throw |

#### `PatternSprintController` (`lib/arcade/games/pattern_sprint/pattern_sprint_controller.dart`, 356 lines)
| Method / scenario | What to test |
|---|---|
| Initial state | `score == 0`, `streak == 0`, `isOver == false`, question options contain answer |
| `answer(correct)` | Score increases; `correct` count increments; streak increments |
| `answer(wrong)` | Score decreases (not below 0); `wrong` count increments; streak resets |
| `answer` — streak multiplier | Score scales up with consecutive correct answers |
| `toResult()` | `gameId == patternSprint`; metadata contains `correct`, `wrong`, `maxStreak`, `accuracy` |
| Pattern generation | Answer is always present in `options`; options have no duplicates |

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

#### `TypingIndicatorService` (`lib/core/services/presence/typing_indicator_service.dart`, 268 lines)
| Method / scenario | What to test |
|---|---|
| `isAnyoneTyping(conversationId)` | `false` before any typing |
| `startTyping(conversationId)` | `isCurrentUserTyping` → `true` |
| `stopTyping(conversationId)` | `isCurrentUserTyping` → `false` |
| `isAnyoneTyping` after peer update | `true` after `updateUserTypingStatus` for another user |
| `handleTextInput` — non-empty | Calls `startTyping` |
| `handleMessageSent` | Calls `stopTyping` |
| `clearConversationTyping` | All typing states cleared for that conversation |

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

### 2e. Other service gaps
- `ArcadeSessionService` — session start/end tracking, score aggregation
- `ArcadeRegistry` — game definition lookup, valid `ArcadeGameId` for each definition
- `LocalArcadeLeaderboardService` — insert score, retrieve top-N, sorted order

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

## Release Readiness Checklist

| Item | Status |
|------|--------|
| Zero `debugPrint` in production business logic | ✅ Done |
| Zero `UnimplementedError` in user-facing paths | ❌ 2 remain (see §1d) |
| Crash recovery tested on iOS and Android | ❌ Not implemented |
| Test coverage ≥ 40% on `lib/game/` and `lib/core/` | ❌ ~3.6% currently |
| No critical CVEs in dependency tree | ⏳ Needs `flutter pub outdated` run |
| No single Dart file exceeds 1,700 lines | ✅ Done |
| CI pipeline enforces coverage + lint + no raw prints | ❌ Not configured |
| All source-code TODO/FIXME resolved | ✅ Done (0 remaining) |
| Runtime validation of all Synaptix screens | ❌ Blocked (needs device) |
| Sprint 2 networking layer | ❌ Not started |
