# Decision Record: Tier System Backend Status

**Original Date:** June 27, 2026
**Updated:** July 3, 2026
**Status:** Superseded by verified backend progression endpoints
**Current Decision:** Use real backend progression endpoints with frontend fallback support

---

## Current Status

The original blocker was that tier/progression endpoints were believed to be missing from `TycoonTycoon_Backend`. That is no longer true.

Verified backend endpoints:

```text
GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

Backend source:

```text
Synaptix.Backend.Api/Features/Progression/ProgressionEndpoints.cs
Synaptix.Backend.Api/Program.cs
```

Frontend source:

```text
lib/core/services/tier_api_client.dart
lib/game/providers/phase2_reward_providers.dart
lib/game/providers/tier_progression_provider.dart
lib/game/providers/arcade_providers.dart
```

---

## Original Decision

The June 27 decision was:

- build the frontend tier system with mock/fallback data,
- keep Phase 2 unblocked,
- swap to real backend endpoints when available.

That was the correct decision at the time because the audit could not verify progression endpoints.

---

## Superseding Decision

Use the real backend progression API as the primary source for Phase 2 tier/progression data.

Keep fallback data for:

- offline development,
- transient backend failures,
- invalid/empty API responses,
- unauthenticated states where no user ID is available.

---

## Backend Contract

### Tier Definitions

```text
GET /api/v1/progression/tiers
```

Returns a raw array of tier definitions.

### Player Progress

```text
GET /api/v1/progression/player/{userId:guid}
```

Requires authorization and returns a flat progress DTO.

### XP Award

```text
POST /api/v1/progression/xp/award
```

Requires authorization and expects:

```json
{
  "userId": "00000000-0000-0000-0000-000000000000",
  "xpAmount": 100,
  "reason": "quiz_completed"
}
```

---

## Frontend Integration Notes

- Phase 2 providers should use `authHttpClientProvider`.
- Clients should use `EnvConfig.apiV1BaseUrl`.
- Do not send the old XP request field `amount`; backend expects `xpAmount`.
- Player progress parsing must support the backend's flat DTO.
- Tier definitions parsing must support the backend's raw array response.
- Keep mock fallback behavior in `TierApiClient`.

---

## Remaining Decisions

The tier backend is no longer blocking Phase 2. Remaining architectural decisions are separate:

- whether realtime tier/config updates are needed now or later,
- whether operator dashboard tier controls should be a Phase 3 backend/dashboard project,
- whether tier analytics need dedicated endpoints or can start as client/server event logging.

---

## Outcome

Phase 2 can proceed with real daily, weekly, and tier/progression APIs. The earlier "mock tiers until backend ready" plan is now historical context only.
