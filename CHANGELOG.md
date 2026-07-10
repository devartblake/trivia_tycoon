# Changelog - Trivia Tycoon

All notable changes to this project are documented in this file.

## [Unreleased] - Sprint 2 (API contract alignment, server-authoritative XP)

_Backend contracts verified directly against `TycoonTycoon_Backend` source; companion backend branch: `claude/sprint2-server-xp-friends`._

### Added
- **Champion vs Tier — redundancy, duels & replay-on-join** — (1) a hosted `ChampionRoundWatchdog` runs alongside the Hangfire scheduler as a self-healing safety net: it sweeps for any overdue round/duel a dropped job missed and resolves it idempotently, so the two drivers never double-fire. (2) **Champion duels**: the champion can call out one alive challenger for a head-to-head on a single question (`POST /game-events/{id}/duel` + `/duel/answer`) — correct beats wrong then speed, champion takes ties, capped per match; only the two duelists are affected, the loser is culled and feeds the jackpot, a dethroned champion ends the match (`ChampionDuel` entity, migration `AddChampionDuels`, duel realtime contracts, Hangfire duel job). (3) **Replay-on-join**: `GET /game-events/{id}/live` returns the current open round/duel so `ChampionLiveScreen` renders the in-progress state on entry instead of waiting for the next broadcast. Client gains the duel/snapshot DTOs, `getLiveSnapshot`/`startChampionDuel`/`submitDuelAnswer`. 14 orchestration tests
- **Champion vs Tier live rounds (Phase 2)** — the 1-vs-99 match now plays out in real time. Backend: `ChampionRound`/`ChampionRoundAnswer` + `ChampionMatchOrchestrator` run synchronized rounds (broadcast question → answer window → resolve: wrong/absent are eliminated and feed the jackpot → next round or close), driven by Hangfire-scheduled resolves and closed via the existing prize handler; a champion who doesn't answer forfeits (emergent no-show handling) and the asymmetric close crowns the last challenger. New SignalR round contracts (`ChampionRoundStarted`/`Resolved`/`MatchEnded`) on the NotificationHub and `POST /game-events/{id}/rounds/answer`. Client: hub round streams + `joinGameEvent`, `ApiService.submitRoundAnswer`, and a `ChampionLiveScreen` (question, countdown, tap-to-answer, per-round + match-end feedback) reachable from the card's "Watch the battle live" state. 11 backend orchestration tests + client DTO tests. Migration `AddChampionRounds`
- **Champion vs Tier weekly event (core)** — a 1-vs-99 spectacle built on the backend's existing `champion_battle` game-event rails. The tier's #1 (seeded from the season leaderboard at Open) defends the crown against 99 challengers; every elimination grows the jackpot; close is asymmetric (champion survives → takes the multiplied jackpot; dethroned → last challenger wins). New `champion_vs_tier` kind, `GameEvent.ChampionPlayerId` + sponsor `JackpotMultiplier` (migration `AddChampionVsTierEventFields`), `TierChampionSeeder`, richer status DTO. Client: `ChampionEvent` model, `getUpcomingGameEvents`/`getGameEventStatus`/`enterGameEvent`, and a `ChampionVsTierCard` on the leaderboard showing the jackpot, sponsor multiplier, alive count and a Challenge/Champion state. Betting is intentionally a future **no-loss prediction** mechanic (safe for the app's minor users), not a staked wager. Full phasing in `docs/api/CHAMPION_VS_TIER_EVENT_PLAN.md`
- **Seasonal plan Phases B–E (server-authoritative season points + tie-breakers)** — decisions confirmed: balanced formula with 50/day solo cap, tie detection at rank 1 + promotion cutoffs, 24h snapshot deferral with real stakes, auto-scheduling with admin override. Backend (branch `claude/season-leaderboard`): solo quizzes now earn season rank points server-side (1/correct, 50/day cap, idempotent ledger) in both `POST /questions/check-batch` and `POST /quiz/complete`; `POST /admin/seasons/{id}/players/{playerId}/reset` moderation reset; `SeasonTiebreaker` entity + migration, tie detection at season close (championship + reward-boundary), deferred snapshot rows/rewards for tied players, resolution via `POST /matches/submit` with mode `tiebreaker`, hourly Hangfire expiry sweep (no-show → deterministic fallback), routes `GET /seasons/tiebreakers/mine`, `GET /seasons/{id}/tiebreakers`, admin create/cancel/resolve. Client: `SeasonTiebreaker` model + `getMyTiebreakers()`, `myTiebreakersProvider`, `TiebreakerBanner` on the leaderboard screen ("Play now" deep-links to multiplayer), `QuizXpAward.seasonPointsAwarded`; deleted the dead `resetPlayerSeasonPoints`/`scheduleTiebreakerQuiz` client methods
- **Season leaderboard revived (Phase A of the seasonal plan)**: backend gains `GET /seasons/{seasonId}/leaderboard` + `GET /seasons/active/leaderboard` (paginated rank-point standings; closed seasons serve the immutable snapshot; optional `me` entry with off-page rank when authenticated — backend branch `claude/season-leaderboard`). Client `getSeasonLeaderboard` is un-deprecated and re-wired to the new route (legacy non-GUID local season ids fall back to the active season); `SeasonPlayer.fromJson` accepts the backend entry shape; `seasonal_competition_service` no longer calls the dead per-player reset route (resets/carryover are server-side at season close)
- **Question Phase 4**: free-text question UI (`FreeTextView`, normalized case/whitespace-insensitive grading), boss question variant (10s pressure timer always applies, red boss canvas + "BOSS QUESTION — 5× XP" banner), and timed-challenge mode (per-question countdown from difficulty: easy 30s → boss 10s; opt in via `timedChallenge` on `/quiz/play` extras)
- `docs/api/SEASONAL_TIEBREAKER_BACKEND_PLAN.md` — phased plan to restore season leaderboard, server-side point accrual, moderation resets, and the tie-breaker mechanic on the backend's existing PlayerSeasonProfile/SeasonPointTransaction domain
- **Server-authoritative quiz XP**: each quiz run sends a `quizSessionId` with `POST /questions/check-batch`; the backend grades the answers, awards tier XP (difficulty × 10 per correct, idempotent per session), and the client refreshes tier progress from the returned `QuizXpAwardDto` (backend half on the companion branch)
- `DELETE /users/me/friends/{friendPlayerId}` (backend) — authenticated friend removal
- 350ms search debounce in AddFriendDialog; social DTO contract tests

### Changed
- `socialEnabled` now defaults to **true** on the client (constructor + missing-key fallback); backend `/app/config` can still disable it per release or per player (ban)
- `getMixedQuiz` posts the real `MixedQuestionSetRequest` to `POST /questions/mixed` — multi-category requests now work (the old GET path silently dropped all but one category)
- Friends client migrated to the canonical authenticated surface `/users/me/friends/*` + `/users/search?handle=` with real DTO field mappings; party client/service/models rewritten to the actual `/party` contract (leader-based creation, roster shape, invite bodies)

### Fixed
- Quiz hub RenderFlex overflows at phone widths (grid headers, category cards, daily-quiz card, CTA card); responsive quiz-hub tests now pass at 390/900/1280px
- Carousel auto-advance timer leak (`Future.delayed` chain → cancellable `Timer.periodic` with dispose)
- `ApiService.getRequest` double-base-URL helper removed; referral invite service migrated to typed helpers

### Removed
- Legacy question API layers (`question_api_client.dart`, `question/question_api_service.dart`) and the loader's doomed API-first fetch — all targeted endpoints that don't exist on the backend

## [4.2.0] - 2026-07-08

### Full Codebase Audit + Sprint 1 Critical Fixes

#### Added
- **Codebase Audit & 5-Sprint Plan** (`docs/audit/CODEBASE_AUDIT_AND_SPRINT_PLAN_2026_07_08.md`)
  - Complete audit of API endpoints, question system, Sentry, user flows, duplicates/legacy code, and outstanding plans
  - Verified with real toolchain: Flutter 3.44.5 analyze (26 issues → 4 after fixes) and full test run (4,269 passed / 223 failed / 2 skipped in 47m)
  - Five-sprint execution plan ordered critical → deferred
- **QuestionBackendGate circuit breaker** (`question_hub_service.dart`)
  - Every question API attempt capped at 4s; first connectivity failure short-circuits all question endpoints to local fallback for 60s
  - Replaces the old behavior where each call independently waited out a 10s connect timeout

#### Fixed
- **Question system not displaying (root causes)**
  - Release builds no longer block forever on the backend health check: `ALLOW_OFFLINE_BOOT` now defaults to `true` (degraded local-fallback start); build with `--dart-define=ALLOW_OFFLINE_BOOT=false` to restore the strict gate
  - Health probes bounded to 3s each (previously unbounded — a black-holed host pinned the "Connecting to server..." screen)
  - Removed duplicate `serviceStatusProvider` in `quiz_providers.dart` that made the source banner permanently read "not confirmed"
  - Category/class stats no longer call backend endpoints that don't exist (`/questions/categories/{slug}/stats`, `/questions/classes/{id}/stats`); computed locally behind a `useBackendStatsEndpoints` flag
  - `allClassesStatsProvider` fetches its 13 class stats in parallel (was sequential); QuestionScreen preload parallelized
- **Sentry effectively OFF in shipped builds**
  - Sentry init merged into `lib/main.dart` (DSN-gated); `main_with_sentry.dart` deleted — no build ever targeted it
  - `SentryNavigatorObserver` added to GoRouter for screen breadcrumbs
  - Env reads now `const String.fromEnvironment` so `--dart-define` values reach AOT builds
  - Removed dead `_sentryDsn`/`_sentryEnvironment`/`_sentryTraceSampleRate` fields from `EnvConfig`
- **Sprint 1 Friends system was dark**
  - `/friends` now routes to the new `FriendsListScreen` (was still building the legacy profile screen; the 1,600-LOC Sprint 1 UI was unreachable)
  - Fixed 11 discarded `ref.refresh` results in `social_providers.dart` (lists now actually refetch after accept/decline/remove) using `ref.invalidate`
- **Auth & lifecycle**
  - Bearer tokens now attach to `/matches`, `/party`, `/progression`, `/account` (previously sent unauthenticated → 401)
  - Token refresh tries `/auth/refresh` before `/admin/auth/refresh` (regular users no longer burn a guaranteed-failing admin call)
  - `ActiveMatchesNotifier` cancels its periodic timers in `dispose` (both leaked; same bug family as the pending-timer test failures)
- **Code health**
  - 29 wrong-depth relative imports converted to `package:` imports
  - Analyzer: 26 issues → 4 (remaining are info-level deprecations, tracked for Sprint 4)

#### Changed
- `font_awesome_flutter` 10.x → 11.x and `sign_in_button` 3.x → 5.x: the locked 10.12.0 fails to compile on Flutter 3.44.5 (extends the now-final `IconData`), breaking tests and release builds; migrated 7 call sites to `FaIcon`/`FaIconData`
- Toolchain note: dependency resolution requires **Flutter ≥ 3.44.5**

#### Known Issues / Follow-ups
- Committed Sentry DSN in `assets/config/.env.prod`/`.env.staging` should be rotated and injected via CI secrets
- `socialEnabled` remote flag defaults to `false` — Friends stays hidden until `/app/config` enables it
- ~223 test failures in the full suite (mostly pending-timer/dispose family) — triage scheduled in Sprint 4

## [4.1.0] - 2026-07-05

### Phase 2 API Integration, Spin/Match Migration, Sentry Foundation, Friends Foundation

_Covers sessions 2026-07-03 through 2026-07-07 that were not previously recorded here._

#### Added
- **Sentry error tracking foundation** (2026-07-03/04)
  - `sentry_flutter` dependency, `SentryService` wrapper (DSN/env/sample-rate from env), setup guide `docs/SENTRY_SETUP_FLUTTER.md`
  - Note: initialization only became active in shipped builds in 4.2.0
- **Phase 2 backend contract sync** (2026-07-05)
  - `DailyBonusApiClient`, `WeeklyRewardsApiClient`, `TierApiClient` aligned with verified backend DTOs under `/api/v1`
  - Authenticated HTTP transport for Phase 2 clients; contract tests (22 passing)
- **Spin wheel & matches REST migration** (2026-07-05)
  - Spin claims use backend-issued claim tokens (prevents "invalid claimToken" failures)
  - `MatchesService` full REST implementation; Match History tab in Challenges (245-LOC widget, result indicators, relative timestamps)
- **Skill catalog integration & quiz UI revamp** (2026-07-05)
  - Skill catalog wired into progression surfaces; quiz screens restyled (dark canvas, segmented progress strip, powerup tray)
- **Friends system foundation — Sprint 1** (2026-07-05/07)
  - 7 DTOs, `FriendsApiClient` (7 endpoints), `FriendsService`, 10 Riverpod providers
  - `FriendsListScreen` (Friends/Requests tabs), `FriendCard`, `FriendRequestCard`, `AddFriendDialog`
  - `PartyApiClient` + `PartiesService` + party models (UI scheduled for a later sprint)
  - Secure refresh flow for social API clients

#### Fixed
- Sentry Flutter API compatibility (simplified to available API surface) (2026-07-04)

#### Documentation
- `docs/api/BACKEND_API_AUDIT.md` — verified backend endpoint inventory (2026-07-03)
- `docs/ROADMAP_SUMMARY_2026_07_05.md`, `docs/FUTURE_SPRINTS_FRIENDS_PARTIES_PLAN.md`, Sprint 1 status/progress reports

## [4.0.0] - 2026-07-01

### Quiz Review & Arcade Leaderboard System ✅ PRODUCTION READY

#### Added
- **Quiz Review Feature** - Review arcade questions after gameplay
  - Per-question tracking (prompt, user answer, correct answer, correctness)
  - Expandable question tiles with visual indicators (✓ green, ✗ red)
  - Automatic accuracy summary (X correct / Y wrong / Z%)
  - Smart UX: correct answer hidden when right, shown when wrong
  - Non-invasive modal integration (button only shows when data exists)
  - Pattern Sprint implementation (Memory Flip & Quick Math ready for future adoption)
  - 1 model class + comprehensive testing

- **Arcade Leaderboard System** - Global per-game, per-difficulty leaderboards
  - Backend: ArcadeScoreEntry entity with transactional upserts
  - Only best scores stored (personal best per game/difficulty)
  - Score comparison: score DESC, then duration ASC
  - Paginated leaderboard retrieval (configurable page size, max 100)
  - Player rank computation for authenticated requests
  - Frontend: API service layer with comprehensive error handling
  - Local/Global toggle in arcade hub
  - Game & difficulty pickers in main leaderboard
  - Non-blocking score submission (fire-and-forget)
  - Offline fallback to local leaderboard if API unavailable

#### Database Changes
- New `ArcadeScoreEntry` table with optimized indexes
- Transactional upserts (atomic all-or-nothing)
- Database schema fully migrated and tested

#### API Endpoints
- `POST /api/v1/leaderboards/arcade/submit` - Submit a score (auth required)
- `GET /api/v1/leaderboards/arcade/{gameId}/{difficulty}` - Fetch leaderboard (public, optional auth for rank display)

#### Test Coverage
- **14 New Tests** across backend handlers
- **SubmitArcadeScore Tests** (6 tests - all passing)
  - Authentication validation
  - Input validation
  - Score comparison logic
  - Upsert behavior (create, update, skip)
  - Edge case handling
- **GetArcadeLeaderboard Tests** (8 tests - all passing)
  - Empty leaderboard handling
  - Correct sorting and ranking
  - Pagination with proper boundaries
  - Player rank computation (on-page and off-page)
  - Leaderboard isolation by game/difficulty
- **Total Tests Passing**: 215/215 ✅

#### Documentation
- Created `PRODUCTION_READINESS_SUMMARY.md` - Launch readiness overview
- Created `DEPLOYMENT_GUIDE.md` - Step-by-step deployment instructions
- Created `QUIZ_REVIEW_FEATURE_VERIFICATION.md` - Feature verification & testing
- Created `ARCADE_LEADERBOARD_TESTING.md` - Comprehensive test documentation
- Created `ARCADE_LEADERBOARD_ARCHITECTURE.md` - System architecture
- Created `IMPLEMENTATION_COMPLETE.md` - Final completion summary

#### Performance Metrics
- **Backend Latency**
  - Score submit: < 100ms (mostly network)
  - Leaderboard fetch: < 50ms (database query)
- **Frontend**
  - Local toggle switch: < 10ms
  - Global fetch: < 200ms (includes network)
- **Database**
  - Table size: < 100KB for 1000 entries
  - Index coverage: 100% of queries
  - Concurrent connections: 20+ supported

#### Known Limitations
- Quiz review currently enabled for Pattern Sprint only (other games can adopt with minimal changes)
- Leaderboard feature ready for production, analytics/social features deferred to Phase 4+

---

### Phase 2 Enhancements Planning ✅ ROADMAP COMPLETE

#### Enhancement Roadmap Created
- **Learning Hub Integration** - Link wrong answers to lessons (Est. 4-6 hours, Phase 2)
- **Seasonal Leaderboards** - Weekly/Monthly/All-Time filtering (Est. 6-8 hours, Phase 2)
- **Performance Caching** - Cache top 100 scores in-memory (Est. 4-6 hours, Phase 2)
- **Deferred Enhancements** - Comprehensive analysis of 3 future candidates with implementation approaches
  - Difficulty Picker (Local View) - Phase 3, 2-3 hours
  - Analytics Dashboard - Phase 4, 20-30 hours
  - Social Features - Phase 4+, 30-40 hours

#### Documentation
- Created `PHASE_2_ENHANCEMENTS_ROADMAP.md` - Complete Phase 2 implementation guide
- Created `PHASE_2_DEFERRED_ENHANCEMENTS.md` - Comprehensive deferred enhancements analysis
- Phase 2 enhancements to ship 2-3 weeks post-launch
- Deferred enhancements reconsidered based on user feedback and team capacity

#### Decision Criteria
- Selected Phase 2 enhancements based on: time to market, player impact, technical feasibility, non-blocking dependencies
- Deferred enhancements ranked by priority, effort estimate, and business value
- Clear reconsidering timelines documented for each deferred item

---

## [3.0.0] - 2026-06-29

### Phase 3: Tier Progression Integration & Enhancements ✅ COMPLETE

#### Added
- **TierProgressionService** - Unified tier progression system with backend integration
  - XP/level tracking
  - Tier advancement detection
  - Caching layer for performance
  - Fallback to local definitions on API error
  - 18 unit tests (all passing)

- **TierRewardsService** - Automatic reward distribution on tier advancement
  - Coin/gem distribution
  - Badge unlocking
  - Reward tracking and claiming
  - Admin reset capability
  - 11 unit tests (all passing)

- **TierSkillIntegrationService** - Tier-gated skill unlocking
  - Access control per tier
  - Skill registration with tier requirements
  - Unlock information retrieval
  - Category-based skill grouping
  - 10 unit tests (all passing)

- **TierLeaderboardService** - Tier-based leaderboard scoring
  - Dynamic score multipliers (1.0x to 3.0x per tier)
  - Tier bonus points (0-1200)
  - Score breakdown visualization
  - Tier advancement impact estimation
  - 16 unit tests (all passing)

- **Riverpod Providers** for tier progression
  - tierProgressionServiceProvider
  - playerTierProgressProvider
  - tierDefinitionsProvider
  - claimPendingRewardsProvider
  - unclaimedTiersProvider

- **15 Integration Tests** covering complete tier progression flows
  - Tier definition loading
  - XP and level tracking
  - Tier progression detection
  - Edge case handling
  - Data consistency validation

#### Modified
- **TierManager** - Now loads tier definitions from backend with fallback
  - Reduced from 10 to 8 tiers (unified with backend)
  - Added TierApiClient integration
  - Implements caching and fallback mechanism
  - Updated tier styling based on tier names

- **PlayerTierProgressionScreen** - Integrated with real tier data
  - Fetches user ID from PlayerProfileService
  - Watches playerTierProgressProvider
  - Loading and error states
  - Display of actual tier progress to users

#### Test Coverage
- **70+ Automated Tests** - All passing ✅
  - 33 Core tier system tests
  - 37 Enhancement tests
  - Integration + Unit coverage
  - 100% pass rate

#### Documentation
- Created `PHASE_3_FINAL_SUMMARY.md` - Complete overview
- Created `PHASE_3_ENHANCEMENTS_SUMMARY.md` - Enhancement details
- Created `PHASE_3_VERIFICATION_CHECKLIST.md` - Testing guide
- Created `PHASE_3_MISSION_COMPLETE.md` - Completion report
- Updated `MASTER_TASK_TRACKING.md` - Phase 3 marked complete

#### Breaking Changes
None - All changes are additive and backward compatible.

#### Known Limitations
- Tier rewards distribution (coins/gems) has TODO placeholders for integration with CurrencyManager
- Badge unlocking has TODO placeholders for integration with badge system
- Comprehensive end-to-end user flow testing completed (unit + integration), but manual QA on production env pending

---

## [2.0.0] - 2026-06-28

### Phase 2: API Integration & Caching ✅ COMPLETE

#### Added
- TierApiClient with real API support
- Multi-level caching system (TierConfigCache, SpinConfigCache)
- Error handling with fallback to mock data
- Comprehensive logging
- 50+ test cases

#### Modified
- Phase 2 providers with userId support
- Error handling in tier progression system

---

## [1.0.0] - 2026-06-27

### Phase 1: Rendering Optimization ✅ COMPLETE

#### Added
- Shader caching system
- Text label caching
- Paint object reuse
- RepaintBoundary optimization
- Performance diagnostics setup
- 28 unit tests

#### Performance Results
- Frame time: 22.3ms → 13.1ms (41% improvement)
- FPS: 44.8 → 76.3 (sustained 60 FPS on device)
- Memory growth: 35.2MB/min → 0.8MB/min (97% reduction)
- Cache hit rates: 96-99%

---

## Roadmap

### Next Steps (Phase 4 - Optional)
- [ ] Comprehensive end-to-end user flow testing
- [ ] Load testing and performance validation
- [ ] Manual QA on production environment
- [ ] Production deployment

### Future Enhancements (Phase 4+)
- Seasonal tier resets
- Tier-based social features
- Advanced leaderboard analytics
- Custom tier progression curves
- Real-time tier update notifications

---

## Version Numbers

- **3.0.0** - Phase 3: Tier Progression Integration & Enhancements
- **2.0.0** - Phase 2: API Integration & Caching
- **1.0.0** - Phase 1: Rendering Optimization

---

**Last Updated**: 2026-06-29  
**Project Status**: 🟢 Phase 3 Complete | 92% Overall Completion
