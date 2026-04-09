# Question System Integration Audit (2026-04-09)

## Scope
This audit reviews question-related backend connectivity and frontend subsystem integration for:
- question retrieval / gameplay sessions
- power-ups
- XP progression
- lives / energy
- in-game currency (coins / gems)

## Files Reviewed
- `lib/game/services/question_hub_service.dart`
- `lib/game/repositories/question_repository_impl.dart`
- `lib/core/services/question/question_service.dart`
- `lib/core/services/question/question_api_service.dart`
- `lib/game/controllers/question_controller.dart`
- `lib/game/services/xp_service.dart`
- `lib/game/services/wallet_service.dart`
- `lib/game/state/lives_state.dart`
- `lib/game/state/energy_state.dart`
- `lib/core/services/api_service.dart`
- `lib/core/services/settings/profile_sync_service.dart`

## What is Working

### 1) Question data flow is backend-first with local fallback
- `QuestionRepositoryImpl` delegates to `QuestionHubService` for mode/category/daily/mixed access, centralizing question fetch behavior.
- `QuestionHubService` calls backend endpoints (`/quiz/*`, fallback `/questions/*`) and falls back to local loaders on API/contract errors.
- `QuestionService` still provides server+local fallback behavior for legacy paths.

**Impact:** the app can keep serving question content even when backend endpoints partially fail.

### 2) API service supports protected endpoint refresh
- `ApiService` includes protected path handling and session refresh logic used by authenticated requests.

**Impact:** question/profile flows can recover from expired access tokens where routed through `ApiService`.

## Gaps Identified

### A) Economy systems are mostly local-only today
- `XPService` persists XP locally (storage key `playerXP`) and does not sync to backend.
- `WalletService` persists coins/gems to Hive only and does not call backend balance/ledger endpoints.
- `LivesState` and `EnergyState` are state models only with no backend refill/consume sync.
- `QuestionController` applies score/money/diamonds and power-up effects in-memory/session logic, but no authoritative backend transaction write is performed during answer resolution.

**Risk:** cross-device drift, exploit risk, and mismatch between client reward state and backend truth.

### B) Legacy `QuestionApiService` had placeholder URL behavior
- This file was configured with a placeholder URL (`https://your-api-url.com/api/questions`) and therefore was not safe if referenced.

**Fix in this patch:** `QuestionApiService` now reads `API_BASE_URL` from environment configuration and supports both list and `{ items: [...] }` responses.

## Integration Readiness Matrix

| Capability | Backend-connected now | Frontend-ready now | Notes |
|---|---:|---:|---|
| Question catalog & play payloads | Yes | Yes | Backend-first + local fallback in `QuestionHubService`. |
| Daily/mixed/category quiz retrieval | Yes | Yes | Uses `QuestionRepositoryImpl` -> `QuestionHubService`. |
| Power-up effects | Partial | Yes | Applied locally in `QuestionController`; no authoritative backend consume/audit write. |
| XP progression | No (authoritative) | Yes | Local accumulation in `XPService`; needs server profile progression sync. |
| Coins/gems economy | No (authoritative) | Yes | Local Hive balance in `WalletService`; no backend ledger sync. |
| Lives/energy stamina | No (authoritative) | Partial | Models exist; no backend refill/consume contract integration. |

## Recommended Backend Contracts (next step)
To guarantee full-stack consistency, add/verify these endpoints and wire them into providers/controllers:

1. `POST /quiz/sessions/start`
2. `POST /quiz/sessions/{sessionId}/answer`
   - request includes answer, power-up usage, elapsed time
   - response returns authoritative score delta, XP delta, currency delta, lives/energy deltas
3. `POST /economy/wallet/transactions`
4. `GET /economy/wallet/balance`
5. `POST /progress/xp/apply`
6. `POST /stamina/lives/consume` + `GET /stamina/lives`
7. `POST /stamina/energy/consume` + `GET /stamina/energy`
8. `POST /powerups/consume` + `GET /powerups/inventory`

## Frontend Wiring Recommendations
1. Introduce a `GameOutcomeSyncService` called by `QuestionController._evaluateAnswer()` before local state commit finalization.
2. Treat backend response as source-of-truth for XP/currency/lives/energy deltas.
3. Keep current local calculations as optimistic UI only; reconcile with backend response.
4. Add retry/queue semantics for transient failures and hard-fail for authoritative mismatches.
5. Add integration tests covering answer submit -> backend delta -> provider state reconciliation.

## Definition of Done for "fully connected"
- Every rewarded/consumed resource in question gameplay (power-up, XP, coins/gems, lives, energy) has:
  1) explicit backend endpoint,
  2) frontend service call,
  3) provider/controller reconciliation path,
  4) test coverage for success + retry + conflict.

