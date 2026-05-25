# Alpha Release — Disabled Features

**Release:** alpha-june-2026
**Last updated:** 2026-05-16

---

All systems below are disabled via backend feature flags.
They remain in the codebase but are inactive for the Alpha release.

- Backend: endpoints return HTTP 403 `FeatureDisabled`
- Flutter: routes are redirected to `/home` via `featureFlagGuard()`

---

## Disabled Feature Flags

| Feature | Flag | Reason for Alpha Exclusion |
|---|---|---|
| Realtime Multiplayer | `realtimeMultiplayerEnabled` | Matchmaking and SignalR session handling incomplete |
| Ranked Matchmaking | `matchmakingEnabled` | No ranked queue implementation |
| Tournaments | `tournamentsEnabled` | Tournament engine not stabilized |
| Advanced Seasons | `advancedSeasonsEnabled` | Season scoring and progression incomplete |
| Crypto Rewards | `cryptoEnabled` | Regulatory review pending |
| ToM Personalization | `tomPersonalizationEnabled` | FastAPI AI sidecar not deployed to compose |
| AI Sidecar Scoring | `aiSidecarEnabled` | AI service not in production compose |
| Friends / Social | `socialEnabled` | Friend graph and social graph not stable |
| Guilds / Clans | `guildsEnabled` | No guild endpoints implemented |
| Advanced Skill Tree | `skillTreeEnabled` | Skill tree balance and unlock logic incomplete |
| Push Notifications | `notificationsEnabled` | Push certificate not configured for alpha |
| A/B Experiments | `experimentsEnabled` | Experiment framework untested end-to-end |
| Territory Systems | `territoryEnabled` | No territory endpoints implemented |
| Guardian Systems | `guardiansEnabled` | Guardian assignment background job only; no user-facing endpoints |

---

## Enforcement

### Backend

Group-level `AddEndpointFilter` gates enforce all flags server-side.
SignalR hubs at `/ws/*` are gated via path-based middleware in `Program.cs`.

```json
{
  "error": "FeatureDisabled",
  "feature": "realtimeMultiplayerEnabled",
  "message": "This feature is not available in the current release."
}
```

HTTP status: `403 Forbidden`

### Flutter

`featureFlagGuard()` in `app_router.dart` redirects to `/home` for all gated routes.
Flags are fetched from `GET /api/v1/app/config` on startup.
Safe defaults (all non-core flags off) apply while config is loading.

---

## Re-enabling After Alpha

To enable a feature after Alpha validation:

```http
PATCH /api/v1/admin/config
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "realtimeMultiplayerEnabled": true
}
```

No app restart required. Flutter re-fetches config on next launch.
