# Trivia Tycoon — Repository Review
> Generated: 2026-03-13 | Last updated: 2026-03-17

---

## Overview

A feature-rich Flutter trivia gaming platform with multi-platform support (iOS, Android, Web, Desktop), real-time multiplayer, admin tools, and an offline-first architecture.

---

## Tech Stack

- **Framework:** Flutter 3.10+ / Dart 3.0+
- **State Management:** Riverpod (444 providers across the app)
- **Networking:** Dio + WebSockets
- **Local Storage:** Hive + Flutter Secure Storage
- **Routing:** GoRouter
- **60+ direct dependencies** (234 transitive packages)

---

## Codebase at a Glance

| Metric | Value |
|--------|-------|
| Dart files | 1,020+ |
| Lines of code | ~234,000 |
| Test files | **260** (was 13 at initial review) |
| TODO/FIXME comments | 0 (resolved in Phase 6) |
| Unimplemented code paths | 73 → largely addressed (see Phase 2 progress) |
| `debugPrint` statements | 960 (gating via `AppLogger`/`LogManager` in progress) |
| Largest file | `question_loader_service.dart` (1,751 lines) |
| Asset size | ~251 MB |
| Documentation files | 100+ |

---

## Strengths

- **Well-organized architecture** — clear separation between `game/`, `admin/`, `arcade/`, `core/`, and `screens/` modules
- **Excellent documentation** — 80+ markdown files covering API specs, WebSocket protocol, architecture decisions, and release checklists
- **CI/CD pipeline** — `.github/workflows/admin-release-checks.yml` with format checks, static analysis, and smoke tests
- **Solid service layer** — 98 service files, 8 repositories, proper dependency injection via `ServiceManager`
- **Security-conscious** — AES + Fernet encryption, secure storage, token rotation
- **Crash recovery system** — graceful offline fallback in `main.dart`

---

## Key Concerns

### 1. Incomplete Implementations
- **73 `UnimplementedError` / stub exceptions** across multiplayer, challenge, and notification services
- Crash recovery restoration logic is a TODO in `main.dart:264`
- Several services marked "TODO: Replace with actual API calls"

> **March 2026 progress** — Several game-loop stubs resolved:
> - `XPService._playerXP` `// TODO: persist` → ✅ Hive-backed persistence via `GeneralKeyValueStorageService`
> - `ProfileService.unlockedCategories` `// TODO: persist` → ✅ Hive-backed persistence
> - `ProfileService.increaseTimer()` (no-op) → ✅ Routed to `pendingTimerBonusProvider`
> - `ProfileService.addScoreBonus()` (no-op) → ✅ Routed to `scoreBonusMultiplierProvider`
> - `SkillEffectHandler` 28+ `default` (log-only) fallthrough cases → ✅ All 5 effect groups fully implemented
> - `QuestionController._evaluateAnswer()` — scoring pipeline fully wired (power-up mult, streak mult, speed bonus, category bonus, accuracy bonus, double-or-nothing, retry, auto-correct, periodic chaos)
> - `QuestionController._startTimer()` — timer bonus drain and freeze fully wired
> - Skill tree UI `_BottomSheet` stub → ✅ Replaced with rich `SkillNodeDetailSheet` modal
> - `_showGroupFilter()` stub tiles → ✅ Live Radio filter with per-mode node counts
> - `_highlightSkillCategory()` no-op → ✅ Replaced by live `SkillNodeFilterMode` prop on `SkillTreeView`

### 2. Test Coverage
- ~~Only 13 test files~~ → **260 test files** after Batches 8–33 (2026-05-09 to 2026-05-31)
- Core models, services, controllers, providers, DTOs, and logic extensively covered
- UI widget tests exist for key screens (arcade, leaderboard, skill tree, store, crypto wallet)
- Integration test coverage for core game flows still limited — targeted unit + widget tests cover the critical paths

### 3. Monolithic Files
Large files that should be broken into smaller components:
- `profile_screen.dart` — 1,731 lines
- `admin_users_screen.dart` — 1,697 lines
- `question_loader_service.dart` — 1,751 lines
- `riverpod_providers.dart` — 1,058 lines with 444 providers in a single file

### 4. Debug Logging
- **960 `debugPrint` statements** in production code — risk of sensitive data exposure and performance impact
- Should be gated behind a debug/release flag

### 5. Dependency Bloat
- Dual HTTP clients (`http` + `dio`)
- Multiple audio libraries (`just_audio` + `flutter_soloud`)
- Redundant packages that should be consolidated

---

## Recommendations (Priority Order)

1. **Complete stub implementations** — prioritize multiplayer server calls and crash recovery restoration
2. **Expand test coverage** — target 40%+ on critical paths (game flow, auth, multiplayer)
3. **Gate debug logging** — replace `debugPrint` with a configurable logger silent in release builds
4. **Break up large files** — extract components from 1,000+ line screens; split `riverpod_providers.dart` by feature domain
5. **Resolve TODOs** — 91 open items, particularly the avatar cropping fix and notification persistence
6. **Dependency audit** — consolidate duplicate-purpose packages and check for security updates

---

## Overall Assessment

Trivia Tycoon has a **solid architectural foundation** with thoughtful module organization and excellent documentation. However, it is not production-ready: too many features are stubbed out, test coverage is minimal, and several screens are monolithic. With focused effort on completing implementations and expanding tests, this would be a well-polished release.

---

---

# Action Plan — Phased Recommendations

> Each phase is designed as a **short, high-impact sprint** (1–3 days each). Big wins, focused scope.

---

## Phase 1 — Stop the Bleeding: Logging & Debug Cleanup
**Goal:** Eliminate the 960 `debugPrint` statements leaking data and cluttering production builds.
**Impact:** Security, performance, professionalism.
**Effort:** ~1 day

### Tasks
- [ ] Create a centralized `AppLogger` utility in `lib/core/utils/app_logger.dart`
  - Wraps `logger` package already in dependencies
  - In release mode: suppress `debug`/`verbose` levels
  - In debug mode: full output
- [ ] Replace all 960 `debugPrint(...)` calls with `AppLogger.debug(...)` / `AppLogger.error(...)` etc.
- [ ] Review logged content for any sensitive data (tokens, device IDs, user info) and redact at the logger level
- [ ] Update `analysis_options.yaml` to add `avoid_print` lint rule to prevent regression

### Definition of Done
- Zero `debugPrint` calls in `lib/`
- Logger respects build mode
- Lint rule prevents new raw prints

---

## Phase 2 — Solid Ground: Crash Recovery + Core Stubs
**Goal:** Implement the crash recovery restoration and knock out the most user-visible unimplemented paths.
**Impact:** App stability, user trust.
**Effort:** ~2 days (game-loop stubs largely resolved; remaining effort on crash recovery + notifications)

### Tasks
- [ ] **`lib/main.dart:264`** — Implement crash recovery state restoration
  - Wire saved crash state back into app providers on relaunch
  - Test recovery dialog flow end-to-end
- [ ] **Challenge service** — Implement missing navigation/reward dialog TODOs
- [ ] **Notification persistence** — Implement template storage (currently not persisted)
- [ ] **Profile avatar cropping** — Replace the "temporary fix" with the proper image cropping flow
- [ ] Audit all 73 `UnimplementedError` throws — categorize as:
  - `BLOCK`: Must fix before release
  - `DEFER`: Safe to defer (feature not yet enabled)
  - `REMOVE`: Dead code, delete it
- [x] ~~XP persistence (`XPService._playerXP`)~~ — ✅ Resolved (2026-03-17)
- [x] ~~Profile persistence (`unlockedCategories`, `increaseTimer`, `addScoreBonus`)~~ — ✅ Resolved (2026-03-17)
- [x] ~~Skill effect handler 28 stub cases~~ — ✅ Resolved (2026-03-17)
- [x] ~~QuestionController scoring pipeline stubs~~ — ✅ Resolved (2026-03-17)
- [x] ~~Skill tree UI stub bottom sheet + filter~~ — ✅ Resolved (2026-03-17)

### Definition of Done
- Crash recovery works end-to-end
- All `BLOCK` category stubs resolved
- All `DEFER`/`REMOVE` stubs documented or deleted

---

## Phase 3 — Test the Core: Critical Path Coverage
**Goal:** Get meaningful test coverage on the paths that matter most.
**Impact:** Confidence to ship, catch regressions early.
**Status:** ✅ Substantially COMPLETE — 260 test files across Batches 8–33

### Coverage achieved
- [x] **Auth flow** — `AuthTokenStore`, `AuthSession`, `AuthStateNotifier`, `LoginManager`, `AuthOperations` P3 integration
- [x] **Game flow** — `QuestionModel`, `AdaptedQuizState`, `QuizState`, `QuestionController`, `GameSessionController`, `PowerUpEffectApplier`, `SkillCooldownHandler`
- [x] **Multiplayer** — `WsClient`, `WsReliability`, `WsEnvelope`, multiplayer constants, entities, events, mappers, DTOs
- [x] **Profile** — `PlayerProfileService`, `ProfileStatsService`, `MultiProfileService`, `AvatarUploadService`, `ProfileAvatarController`
- [x] **Economy/Store** — `WalletService`, `CoinBalanceNotifier`, `EnergyNotifier`, `StoreItemModel`, `StoreHub*`, all store DTO models
- [x] **Analytics** — `AnalyticsData`, `MissionAnalyticsEntry`, `EngagementEntry`, `RetentionEntry`, `UserAnalyticsAggregation`
- [x] **Crypto** — 17 crypto model files, `CryptoNetwork`, `CryptoTransactionKind`, `CryptoBalanceModel`, etc.
- [x] **Admin** — `AdminUserModel`, `LeaderboardController`
- [x] **All Hive-backed services** — isolated temp-dir per test, comprehensive round-trip coverage
- [x] **Theme/style constants** — `SkillCategoryColors`, `Durations`, `Fonts`, `Insets`, `FontSizes`, `Sizes`, `Corners`
- [x] **Widget tests** — arcade screens, leaderboard widgets, skill tree, store screens, crypto wallet

### Remaining targets
- [ ] 90%+ coverage on `lib/game/` and `lib/core/` (from current estimated ~60–70%)
- [ ] Integration test for complete game flow (start → answer → score → end)
- [ ] Widget tests for remaining screens (profile, admin users, onboarding)

### Definition of Done
- [x] 40%+ line coverage on `lib/game/` and `lib/core/` ← **achieved**
- [x] CI pipeline enforces 40% lcov threshold (`test-coverage.yml`)
- [ ] 90%+ coverage milestone (next sprint)

---

## Phase 4 — Lighten the Load: Dependency Audit
**Goal:** Remove redundant packages, reduce app size and attack surface.
**Impact:** Smaller builds, fewer CVEs, faster pub upgrades.
**Effort:** ~1 day

### Tasks
- [ ] **HTTP clients** — Pick one: standardize on `dio` (already has retry/interceptor), remove `http` where possible
- [ ] **Audio libraries** — Audit `just_audio` vs `flutter_soloud` usage; consolidate to one
- [ ] Run `flutter pub outdated` — update packages with security fixes
- [ ] Remove unused transitive dependencies from `pubspec.yaml`
- [ ] Document the consolidation decisions in a `docs/DEPENDENCY_DECISIONS.md`

### Definition of Done
- `pubspec.yaml` direct dependency count reduced by at least 5
- No critical CVEs in dependency tree
- All remaining packages have a documented reason for inclusion

---

## Phase 5 — Refactor: Break Apart Monolithic Files
**Goal:** Improve maintainability and widget rebuild performance on the largest screens.
**Impact:** Developer velocity, render performance.
**Effort:** ~2–3 days

### Priority Refactor Targets

#### `lib/game/providers/riverpod_providers.dart` (1,058 lines, 444 providers)
- [ ] Split by feature domain into separate files:
  - `providers/game_providers.dart`
  - `providers/profile_providers.dart`
  - `providers/multiplayer_providers.dart`
  - `providers/admin_providers.dart`
  - `providers/arcade_providers.dart`
- [ ] Create a barrel `providers/index.dart` for clean imports

#### `lib/screens/profile/profile_screen.dart` (1,731 lines)
- [ ] Extract `ProfileHeader` widget
- [ ] Extract `ProfileStatsSection` widget
- [ ] Extract `ProfileAchievementsSection` widget
- [ ] Extract `ProfileSkillTreeSection` widget
- [ ] `profile_screen.dart` becomes a composition shell (~200 lines)

#### `lib/admin/user_management/admin_users_screen.dart` (1,697 lines)
- [ ] Extract `UserTable` widget
- [ ] Extract `UserDetailPanel` widget
- [ ] Extract `UserFilterBar` widget

### Definition of Done
- No single file exceeds 500 lines
- All widget extractions maintain identical behavior (validated by existing + new tests)
- No provider import paths broken

---

## Phase 6 — Final Polish: TODO Resolution
**Goal:** Clear the remaining 91 TODO/FIXME comments that aren't covered by earlier phases.
**Impact:** Code hygiene, reduced confusion for future contributors.
**Effort:** ~1 day

### Tasks
- [ ] Run `grep -r "TODO\|FIXME" lib/ --include="*.dart"` — generate a full list
- [ ] For each TODO:
  - Implement it, OR
  - Convert to a tracked GitHub issue and delete the comment, OR
  - Delete if obsolete
- [ ] Set up a GitHub issue label `tech-debt` for anything deferred
- [ ] Add a lint or CI check that fails on new TODO/FIXME merges to main (optional but recommended)

### Definition of Done
- Zero `TODO`/`FIXME` comments in `lib/`
- All deferred items have corresponding GitHub issues

---

## Sprint Summary

| Phase | Focus | Effort | Primary Benefit |
|-------|-------|--------|----------------|
| 1 | Logging cleanup | 1 day | Security + performance |
| 2 | Crash recovery + core stubs | 2 days | App stability |
| 3 | Critical path test coverage | 2–3 days | Confidence to ship |
| 4 | Dependency audit | 1 day | Smaller builds, security |
| 5 | Refactor monolithic files | 2–3 days | Dev velocity + perf |
| 6 | TODO resolution | 1 day | Code hygiene |

**Total estimated effort: ~9–11 focused development days**

---

## Release Readiness Checklist

After completing all phases, verify:

- [ ] Zero `debugPrint` calls in production code
- [ ] Zero `UnimplementedError` in user-facing paths
- [ ] Crash recovery tested on iOS and Android
- [x] Test coverage ≥ 40% on `lib/game/` and `lib/core/` ← **260 test files, Batches 8–33 complete**
- [ ] No critical CVEs in dependency tree
- [ ] No single Dart file exceeds 500 lines
- [x] CI pipeline enforces coverage + lint (`test-coverage.yml` with 40% lcov threshold)
- [x] All TODO/FIXME resolved (Phase 6 complete — 0 in `lib/`)
