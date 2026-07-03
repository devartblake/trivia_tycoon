# Backend API Audit - Available Endpoints

**Date:** July 3, 2026
**Status:** Current API Inventory
**Purpose:** Verify which endpoints exist and identify any remaining Phase 2 blockers

---

## Summary

| Feature | Status | Endpoints | Notes |
|---------|--------|-----------|-------|
| Questions | Ready | 6+ | Question fetch, metadata, preview, answer checking |
| Rewards | Ready | 6 | Daily, weekly, and spin reward configuration/claims |
| Account Rewards | Ready | 2 | Account daily status and claim |
| Missions | Ready | 4 | Daily/weekly/season support |
| Tiers | Ready | 3 | Progression endpoints implemented |
| Progression | Ready | 3 | Tier definitions, player progress, XP award |
| Categories | Partial | Via Questions | Available through `/questions/categories`; dedicated metadata endpoint still optional |

There are no known Phase 2 daily, weekly, or tier/progression endpoint blockers as of July 3, 2026.

---

## Verified: Questions Endpoints

**Location:** `Synaptix.Backend.Api/Features/Questions/QuestionsEndpoints.cs`

```text
GET  /api/v1/questions/set
POST /api/v1/questions/mixed
GET  /api/v1/questions/categories
GET  /api/v1/questions/metadata
POST /api/v1/questions/preview-set
POST /api/v1/questions/check
POST /api/v1/questions/check-batch
```

Notes:

- `GET /questions/set` supports category, difficulty, count, personalization, and mode parameters.
- `/questions/check` and `/questions/check-batch` keep grading server-side.
- `/questions/categories` can continue powering frontend category selection.

---

## Verified: Rewards Endpoints

**Location:** `Synaptix.Backend.Api/Features/Rewards/RewardsEndpoints.cs`

```text
GET  /api/v1/rewards/daily-config
POST /api/v1/rewards/daily/claim
GET  /api/v1/rewards/weekly-schedule
GET  /api/v1/rewards/weekly-streak/{userId:guid}
POST /api/v1/rewards/weekly/claim
POST /api/v1/rewards/weekly-streak/{userId:guid}/claim
GET  /api/v1/rewards/spin-reward-steps
```

Daily config returns the daily reward definition:

```json
{
  "rewardType": "coins",
  "coinsAmount": 100,
  "displayName": "Daily Mystery Box",
  "iconName": "daily_box"
}
```

Weekly schedule returns a raw list of `WeeklyRewardDay` records using backend DTO names such as `rewardType` and `displayLabel`.

Weekly claim expects a request body:

```json
{
  "day": 3
}
```

---

## Verified: Account Rewards Endpoints

**Location:** `Synaptix.Backend.Api/Features/Account/AccountRewardsEndpoints.cs`

```text
GET  /api/v1/account/rewards/status
POST /api/v1/account/rewards/claim
```

Notes:

- Both endpoints require authorization.
- Status returns daily claim eligibility plus weekly day/schedule data.
- Daily claim response uses backend DTO fields such as `coinsGranted` and `newBalance`.

---

## Verified: Tier/Progression Endpoints

**Location:** `Synaptix.Backend.Api/Features/Progression/ProgressionEndpoints.cs`

```text
GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

Notes:

- `GET /progression/tiers` returns a raw array of tier definitions.
- `GET /progression/player/{userId:guid}` requires authorization and returns a flat `PlayerTierProgress` DTO:

```json
{
  "currentTierId": "silver-scholar",
  "currentTierName": "Silver Scholar",
  "currentLevel": 2,
  "currentXp": 750.0,
  "xpInCurrentTier": 250.0,
  "xpNeededForNextTier": 450.0,
  "progressPercentage": 35.0
}
```

- `POST /progression/xp/award` requires authorization and expects:

```json
{
  "userId": "00000000-0000-0000-0000-000000000000",
  "xpAmount": 100,
  "reason": "quiz_completed"
}
```

Frontend Phase 2 clients now support the current backend DTO shapes.

---

## Verified: Missions Endpoints

**Location:** `Synaptix.Backend.Api/Features/Missions/MissionsEndpoints.cs`

```text
GET  /api/v1/missions?type={type}
POST /api/v1/missions/progress/match-completed
POST /api/v1/missions/progress/round-completed
POST /api/v1/missions/{missionId:guid}/claim?playerId={playerId}&type={type}
```

Notes:

- Mission types include daily, weekly, and season.
- Progress endpoints are designed for match/round completion events.

---

## Partial: Categories

Categories are available through:

```text
GET /api/v1/questions/categories
```

A dedicated category metadata endpoint remains optional if the frontend needs server-provided icons, colors, or ordering beyond the current questions category list.

---

## Phase 2 Implementation Status

### Complete

- Daily bonus API client and providers
- Weekly rewards API client and providers
- Tier/progression API client and providers
- Authenticated HTTP transport for Phase 2 clients
- Configured API base URL via `EnvConfig.apiV1BaseUrl`
- Backend DTO compatibility for current daily, weekly, and progression contracts
- Focused backend contract tests

### Deferred / Optional

- WebSocket realtime config updates
- Dedicated category metadata endpoint
- Operator dashboard tier controls
- Tier/progression analytics endpoints

---

## Frontend Files To Check

```text
lib/core/services/daily_bonus_api_client.dart
lib/core/services/weekly_rewards_api_client.dart
lib/core/services/tier_api_client.dart
lib/game/providers/phase2_reward_providers.dart
lib/game/providers/tier_progression_provider.dart
lib/game/providers/arcade_providers.dart
test/core/services/phase2_backend_contract_clients_test.dart
test/game/providers/phase2_reward_providers_test.dart
```

---

## Backend Files Reviewed

```text
Synaptix.Backend.Api/Features/Questions/QuestionsEndpoints.cs
Synaptix.Backend.Api/Features/Rewards/RewardsEndpoints.cs
Synaptix.Backend.Api/Features/Account/AccountRewardsEndpoints.cs
Synaptix.Backend.Api/Features/Progression/ProgressionEndpoints.cs
Synaptix.Backend.Api/Features/Missions/MissionsEndpoints.cs
Synaptix.Backend.Api/Program.cs
```

---

## Next Steps

1. Keep Phase 2 contract tests green as backend DTOs evolve.
2. Run real-device/manual claim testing with an authenticated user.
3. Decide whether optional realtime updates belong in Phase 2 or a later operator/config phase.
4. Add a category metadata endpoint only if the UI needs richer category data than `/questions/categories` supplies.

---

**Last Updated:** July 3, 2026
