# Questions API Implementation

**Original Date:** June 26, 2026
**Last Updated:** July 3, 2026
**Status:** Phase 1 question API/fallback implementation complete

## Current Update

This document describes the Phase 1 question loading work. The later Phase 2 reward/progression work referenced in the original version has since been implemented for daily bonuses, weekly rewards, and tier progression. For current Phase 2 status, see:

- [Backend API Audit](BACKEND_API_AUDIT.md)
- [Phase 2 Progress](../phases/PHASE2_PROGRESS.md)

## Implemented Question API Client

File:

```text
lib/core/services/question_api_client.dart
```

Supported operations:

- Fetch questions by category.
- Fetch questions for multiple categories.
- Fetch multiplayer questions.
- Parse common backend response shapes.
- Fall back gracefully through the loader path when API data is unavailable.

## Question Loader Integration

File:

```text
lib/game/services/question_loader_service.dart
```

The loader uses a dual-mode pattern:

1. Check local cache.
2. Try API data.
3. Fall back to bundled asset data.
4. Cache successful results.

This keeps existing gameplay working when the backend is unavailable while allowing production question data to come from the API.

## App Initialization

File:

```text
lib/core/bootstrap/app_init.dart
```

Question preload is non-blocking so app startup is not held hostage by question network requests.

## API Contract

```text
GET /api/v1/questions?category={categoryId}&count={count}&difficulty={level}
GET /api/v1/questions/multiplayer?matchId={matchId}&categories={csv}&count={count}
```

Supported response shapes:

```json
[
  { "id": "q1", "question": "...", "options": ["A", "B"], "correctAnswer": 0 }
]
```

```json
{
  "data": [
    { "id": "q1", "question": "...", "options": ["A", "B"], "correctAnswer": 0 }
  ]
}
```

```json
{
  "questions": [
    { "id": "q1", "question": "...", "options": ["A", "B"], "correctAnswer": 0 }
  ]
}
```

## Caching Strategy

| Data | TTL | Notes |
| --- | --- | --- |
| Questions | 24 hours | Fresh enough for daily content rotation. |
| Tiers | App/session cache plus `TierConfigCache` | Current Phase 2 tier integration is documented separately. |
| Missions | 24 hours | Future/separate frontend replacement work. |
| Configs | 6 hours | Future/separate replacement work. |

## Phase 2 Status

The following Phase 2 scope is complete as of July 3, 2026:

- Daily bonus API integration.
- Weekly rewards API integration.
- Tier progression API integration.
- Backend DTO contract tests.

Passed:

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

Result: 22 tests passed.

## Remaining Follow-Up

- Manual QA against deployed backend services.
- Cleanup of unrelated analyzer warnings.
- Keep question and reward/progression contract tests current as backend DTOs evolve.
