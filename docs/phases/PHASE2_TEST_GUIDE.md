# Phase 2 Testing Guide

**Last Updated:** July 3, 2026
**Status:** Focused backend contract and provider tests passing

## Overview

Phase 2 covers three reward/progression systems:

- Daily bonus claims and streak status.
- Weekly reward schedule, streak status, and claims.
- Tier progression definitions, player progress, and XP awards.

The test suite now includes both provider behavior tests and backend DTO contract tests for the current `TycoonTycoon_Backend` response shapes.

## Key Test Files

| File | Purpose |
| --- | --- |
| `test/core/services/phase2_backend_contract_clients_test.dart` | Verifies daily, weekly, and tier clients parse current backend DTOs and send expected request bodies. |
| `test/game/providers/phase2_reward_providers_test.dart` | Verifies Phase 2 Riverpod provider behavior with fake clients. |
| `test/screens/rewards/daily_bonus_screen_test.dart` | Verifies daily bonus screen structure/loading behavior. |
| `test/screens/rewards/weekly_rewards_screen_test.dart` | Verifies weekly rewards screen structure/loading behavior. |
| `test/screens/rewards/tier_progress_widget_test.dart` | Verifies tier progress widget rendering behavior. |
| `test/features/synaptix_home/phase2_dashboard_integration_test.dart` | Verifies Phase 2 dashboard card integration and responsive layout. |

## Verified Backend Contract

All endpoints are mapped under `/api/v1`.

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

## Running The Focused Phase 2 Tests

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

July 3, 2026 result: 22 tests passed.

## Running Broader Phase 2 UI Tests

```bash
flutter test test/screens/rewards/ test/features/synaptix_home/phase2_dashboard_integration_test.dart --no-pub
```

Use these when reward screens, dashboard cards, or tier widgets change.

## Contract Coverage

The backend contract tests cover:

- Daily reward config parsing.
- Account reward status parsing.
- Daily claim response parsing, including `coinsGranted` and `newBalance`.
- Weekly schedule parsing, including `rewardType` and `displayLabel`.
- Weekly streak parsing, including claimed days and cycle start.
- Weekly claim request body `{ "day": currentDay }`.
- Tier definitions returned as a raw array or `{ "tiers": [...] }`.
- Flat backend player progression DTO parsing.
- XP award request body using `xpAmount`.

## Provider Test Strategy

Provider tests override the API client providers with fake clients. This keeps tests fast and deterministic while still exercising Riverpod wiring, derived state, claim flows, and provider invalidation behavior.

The production providers use:

- `EnvConfig.apiV1BaseUrl`
- authenticated HTTP client wiring
- token-derived current user ID
- `TierConfigCache` for tier data

## Known Gaps

- Manual QA against a deployed backend environment is still needed.
- Full app `flutter analyze --no-pub` timed out during July 3 verification.
- Existing analyzer warnings are unrelated to the Phase 2 backend contract and should be cleaned up separately.
- Optional WebSocket/realtime reward and tier config updates are not covered because that work is deferred.

## Related Documentation

- [Phase 2 Progress](PHASE2_PROGRESS.md)
- [Backend API Audit](../api/BACKEND_API_AUDIT.md)
- [Tier Reward System Status](../features/TIER_REWARD_SYSTEM_STATUS.md)
