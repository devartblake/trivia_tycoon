# Demo Data Inventory

**Original Audit:** June 26, 2026
**Last Updated:** July 3, 2026
**Status:** Phase 2 reward/progression API replacements verified; other demo-data categories remain tracked separately

## Current Summary

The original inventory listed daily bonuses, weekly rewards, and tier progression as demo-data/API replacement candidates. Those three areas are now integrated with backend endpoints for the core Phase 2 mobile app contract.

Still pending outside this Phase 2 pass:

- Admin user fixtures.
- Missions/challenges frontend replacement.
- Category configuration replacement.
- Store catalog replacement.
- Game difficulty/config replacement.
- Optional reward-step preset replacement.
- Optional onboarding/country/reference-data cleanup.

## Updated Inventory

| Area | Current Status | Backend/API Status | Notes |
| --- | --- | --- | --- |
| Questions | API/fallback implemented | `/api/v1/questions` | Phase 1 question loading path uses API with asset fallback. |
| Daily Bonus | Phase 2 complete | `/api/v1/rewards/daily-config`, `/api/v1/account/rewards/status`, `/api/v1/account/rewards/claim` | Client/provider integration verified. |
| Weekly Rewards | Phase 2 complete | `/api/v1/rewards/weekly-schedule`, `/api/v1/rewards/weekly-streak/{userId:guid}`, `/api/v1/rewards/weekly/claim` | Client/provider integration verified. |
| Tier Progression | Phase 2 complete | `/api/v1/progression/tiers`, `/api/v1/progression/player/{userId:guid}`, `/api/v1/progression/xp/award` | Backend contract verified; fallback definitions retained. |
| Missions | Pending/separate | Endpoints present in backend audit | Frontend replacement not covered by current Phase 2 pass. |
| Challenges | Pending/separate | Needs current verification before implementation | Not part of current Phase 2 reward/progression pass. |
| Categories | Pending/separate | Needs current verification before implementation | Hardcoded categories may still be used in UI/navigation. |
| Admin Users | Pending/separate | Needs admin endpoint verification | Security/data cleanup track. |
| Store Items | Pending/separate | Needs store endpoint verification | Future store integration. |
| Game Configs | Pending/separate | Needs per-game config endpoint verification | Future balance/config integration. |
| Email Samples | Demo/test-only candidate | N/A | Keep isolated or move to fixtures if unused in production. |
| Onboarding Questions | Optional | N/A or future onboarding endpoint | Can remain static if product wants fixed onboarding. |
| Countries | Optional/static reference | N/A or future reference endpoint | Can remain static unless localization/admin control is needed. |

## Verified Phase 2 Endpoints

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

## Verification

Passed on July 3, 2026:

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

Result: 22 tests passed.

## Next Recommended Pass

1. Verify current backend support for missions, challenges, categories, store items, and game configs.
2. Update this inventory with exact endpoint paths and DTO shapes.
3. Replace frontend demo data category by category, keeping the API-with-fallback pattern where offline support is valuable.
4. Add focused contract tests for each replacement.
