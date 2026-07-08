# Master Task Tracking - Trivia Tycoon Project

**Last Updated:** July 8, 2026
**Project Status:** Production-ready core systems; full codebase audit complete with Sprint 1 critical fixes landed (question reachability, Sentry, Friends routing)
**Overall Completion:** Core gameplay, reward, progression, quiz review, and arcade leaderboard tracks are production-oriented; operator/analytics/realtime work remains future scope

> **See also:** [Codebase Audit & 5-Sprint Plan (2026-07-08)](audit/CODEBASE_AUDIT_AND_SPRINT_PLAN_2026_07_08.md) — the current execution plan. Sprint 1 (critical) items landed 2026-07-08.

## Current Snapshot

| Area | Status | Notes |
| --- | --- | --- |
| Quiz Review | Complete | Pattern Sprint integration, expandable review tiles, visual indicators. |
| Arcade Leaderboard | Complete | Backend/frontend integration, score submission, global/local leaderboard UI. |
| Daily Bonus | Complete | Backend config/status/claim API wired through Phase 2 providers. |
| Weekly Rewards | Complete | Backend schedule/streak/claim API wired through Phase 2 providers. |
| Tier Progression | Complete for Phase 2 | Backend progression endpoints verified; fallback tier definitions retained. |
| Spin Wheel Rendering | Complete | Rendering optimization and cache work completed in Phase 1. |
| Operator Controls | Planned | Requires operator API and dashboard work. |
| Analytics Dashboard | Planned/In Progress | Separate feature track; not a Phase 2 backend blocker. |
| Realtime Config Updates | Deferred | Optional WebSocket/config refresh work. |
| Sentry (client) | Complete | Initialized in `lib/main.dart` (DSN-gated), navigator observer on router (2026-07-08). DSN rotation + CI secret injection still pending. |
| Friends (Sprint 1) | Routed & functional | `/friends` → `FriendsListScreen`; refresh bugs fixed. Gated by remote `socialEnabled` flag (default false). Tests/debounce/a11y remain. |
| Question Reachability | Complete | Offline-boot default, health-probe timeouts, `QuestionBackendGate` circuit breaker, local stats (2026-07-08). |
| Parties (Sprint 2) | Not started (UI) | Models/API client/service exist; screens pending. |

## Phase 2 Verification Update

Phase 2 daily, weekly, and tier/progression API integration has been started and completed for the core mobile app contract. The earlier "backend needed for tier progression" blocker is resolved in `TycoonTycoon_Backend`.

Verified backend endpoints under `/api/v1`:

```text
GET  /api/v1/rewards/daily-config
GET  /api/v1/account/rewards/status
POST /api/v1/account/rewards/claim

GET  /api/v1/rewards/weekly-schedule
GET  /api/v1/rewards/weekly-streak/{userId:guid}
POST /api/v1/rewards/weekly/claim

GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

Frontend integration status:

- `DailyBonusApiClient` parses backend config/status/claim DTOs.
- `WeeklyRewardsApiClient` parses backend schedule/streak/claim DTOs.
- `TierApiClient` parses backend tier definitions and player progress DTOs.
- Phase 2 providers use `EnvConfig.apiV1BaseUrl` and authenticated HTTP.
- XP award requests send `xpAmount`.
- Weekly reward claims send `{ "day": currentDay }`.
- `TierConfigCache` is available for tier data caching.

## Active Tasks

### Immediate

- Deploy/QA production-ready quiz review and arcade leaderboard work.
- Run manual QA against deployed reward/progression backend services.
- ~~Clean up unrelated analyzer warnings reported by `flutter analyze`.~~ Done 2026-07-08 (26 issues → 4 info-level deprecations).
- Rotate the committed Sentry DSN and inject via CI secrets (`release.yml`).
- Decide default for the remote `socialEnabled` flag (Friends hidden until backend enables it).
- Triage the ~223 full-suite test failures (pending-timer/dispose family) — see audit Appendix B.

### Next

- Learning Hub integration.
- Seasonal leaderboard enhancements.
- Performance caching for leaderboard/reward surfaces.
- Operator dashboard API and UI planning.

### Deferred

- WebSocket/realtime reward and tier config updates.
- Tier/progression analytics dashboard.
- Operator controls for changing tier thresholds/rewards.

## Phase Status

| Phase | Status | Notes |
| --- | --- | --- |
| Phase 1: Spin Wheel Rendering | Complete | Rendering cache, text cache, repaint isolation, benchmarking. |
| Phase 2: API Integration | Complete for core scope | Daily, weekly, and tier/progression API contract verified. |
| Phase 3: Tier Progression Enhancements | Complete for player-facing scope | Tier services, providers, UI, rewards, leaderboard integration. |
| Phase 3 Legacy: Operator Control | Planned | Requires backend/admin dashboard implementation. |
| Phase 4: Analytics & Monitoring | Planned/In Progress | Separate analytics components exist; full backend/dashboard scope remains. |

## Tier Reward System Status

The tier reward system is no longer mock-only.

Completed:

- Core tier models and logic.
- Player-facing tier UI and dashboard cards.
- Riverpod provider integration.
- Backend progression API integration.
- Contract tests for current backend DTO shapes.
- Fallback definitions for offline/error resilience.

Remaining:

- Operator controls.
- Tier analytics/monitoring.
- Optional realtime config refresh.

## Verification

Passed on July 3, 2026:

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

Result: 22 tests passed.

Passed on July 8, 2026 (Flutter 3.44.5):

```bash
flutter analyze --no-pub
```

Result: 4 info-level deprecation notices remain (`onReorder` ×2, `axisAlignment` ×2); all warnings/errors cleared.

Full suite (July 8, 2026): 4,269 passed / 223 failed / 2 skipped in 47m25s. Failure triage tracked for Sprint 4 (audit item 4.8).

Note: dependency resolution requires Flutter >= 3.44.5 (`model_viewer_plus` constraint); `font_awesome_flutter` 11.x + `sign_in_button` 5.x migrated 2026-07-08.

## Key Documents

- [Phase 2 Progress](phases/PHASE2_PROGRESS.md)
- [Phase 2 Test Guide](phases/PHASE2_TEST_GUIDE.md)
- [Backend API Audit](api/BACKEND_API_AUDIT.md)
- [Tier Reward System Status](features/TIER_REWARD_SYSTEM_STATUS.md)
- [Tier System Decision Record](architecture/CRITICAL_DECISION_TIER_SYSTEM.md)
- [Progress README](progress/README.md)

## Known Risks

- Manual QA against deployed backend services is still needed.
- ~223 failing tests in the full suite mean it is not yet a reliable regression gate.
- Committed Sentry DSN needs rotation.
- Two competing friends API surfaces (`/friends/*` vs `/users/me/friends/*`) must be reconciled before Friends ships broadly (audit item 2.2).
- Operator/analytics/realtime scopes require additional product and backend decisions.

## Success Criteria

### Core Phase 2

- [x] Daily bonus API integration.
- [x] Weekly rewards API integration.
- [x] Tier progression API integration.
- [x] Authenticated/configured Phase 2 providers.
- [x] Backend DTO contract tests.
- [x] Tier cache integration.
- [ ] Manual deployed-backend QA.

### Future Operator/Analytics Scope

- [ ] Operator can adjust tier thresholds and rewards.
- [ ] Operator changes are audited.
- [ ] Tier progression analytics are available.
- [ ] Realtime config refresh is implemented if prioritized.
