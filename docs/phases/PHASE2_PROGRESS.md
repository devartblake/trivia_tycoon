# Phase 2: API Integration Progress

**Last Updated:** July 3, 2026
**Status:** Core Phase 2 complete; realtime updates deferred

## Summary

Phase 2 daily rewards, weekly rewards, and tier progression API integration has been started and completed for the core mobile app contract. The earlier mock-only tier plan is superseded: the backend progression endpoints now exist in `TycoonTycoon_Backend`, and the Flutter clients/providers are wired to the configured API base URL plus authenticated HTTP client.

The remaining Phase 2 item is optional realtime configuration refresh, which is deferred until the product needs live reward/tier updates.

## Completed

- Daily bonus API client and providers use the backend reward status/claim contract.
- Weekly rewards API client and providers use the backend schedule, streak, and claim contract.
- Tier progression client uses backend progression endpoints with fallback tier definitions.
- Reward/tier providers are connected to `EnvConfig.apiV1BaseUrl` and the authenticated HTTP client.
- Tier config caching is available through `TierConfigCache`.
- Backend DTO compatibility is covered by client contract tests.

## Verified Backend Endpoints

All of these are mapped under `/api/v1` in `TycoonTycoon_Backend`.

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

Backend source references:

- `Synaptix.Backend.Api/Features/Rewards/RewardsEndpoints.cs`
- `Synaptix.Backend.Api/Features/Rewards/AccountRewardsEndpoints.cs`
- `Synaptix.Backend.Api/Features/Progression/ProgressionEndpoints.cs`
- `Synaptix.Backend.Api/Program.cs`

## Frontend Contract Notes

The Flutter clients account for the current backend response shapes:

- Tier definitions can be returned as a raw array or wrapped in `{ "tiers": [...] }`.
- Player tier progress is parsed from the backend's flat DTO shape.
- XP award requests send `xpAmount`.
- Daily claim parsing supports `coinsGranted` and `newBalance`.
- Weekly schedule parsing supports `rewardType` and `displayLabel`.
- Weekly claim requests send `{ "day": currentDay }`.

## Verification

Passed on July 3, 2026:

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

Result: 22 tests passed.

`flutter analyze --no-pub` was attempted but did not complete before the command timeout. Existing analyzer warnings include `avoid_print`, unused imports, unused locals, and unnecessary casts; those are tracked separately from the Phase 2 backend contract work.

## Remaining Work

- Optional WebSocket/realtime reward and tier config updates.
- Broader manual QA against a deployed backend environment.
- Cleanup of unrelated analyzer warnings.
