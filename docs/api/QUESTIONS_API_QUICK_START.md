# Questions API Quick Start

**Last Updated:** July 3, 2026
**Status:** Ready to use

## Summary

Questions load through the API-aware loader with fallback to bundled assets. Existing call sites can continue using `QuestionLoaderService` without special handling.

## Load Questions By Category

```dart
final questions = await questionLoader.loadDataset('Science');
```

The loader attempts:

1. Local cache.
2. API fetch.
3. Bundled asset fallback.

## API Endpoints

```text
GET /api/v1/questions?category=Science&count=20&difficulty=medium
GET /api/v1/questions/multiplayer?matchId=match-123&categories=Science,History&count=20
```

Supported response shapes include a raw array, `{ "data": [...] }`, and `{ "questions": [...] }`.

## Fallback Behavior

If the API is unavailable, times out, or returns an unsupported payload, the app falls back to cached data or bundled assets so gameplay can continue.

## Phase 2 Update

The original next-step list in this quick start included Phase 2 daily bonus, weekly rewards, and tier API work. That scope is now complete as of July 3, 2026.

Verified Phase 2 endpoints:

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

Passed:

```bash
flutter test test/core/services/phase2_backend_contract_clients_test.dart test/game/providers/phase2_reward_providers_test.dart --no-pub
```

Result: 22 tests passed.

## Related Files

| File | Purpose |
| --- | --- |
| `lib/core/services/question_api_client.dart` | Question backend client. |
| `lib/game/services/question_loader_service.dart` | Cache/API/asset loading path. |
| `lib/core/bootstrap/app_init.dart` | Non-blocking startup preload. |
| `docs/api/QUESTIONS_API_IMPLEMENTATION.md` | Detailed implementation notes. |
| `docs/phases/PHASE2_PROGRESS.md` | Current Phase 2 reward/progression status. |
