# Frontend Handoff — Backend Alpha Alignment (2026-04-04)

## Purpose
This handoff summarizes what backend contracts are now available for frontend integration and what is still pending to reach full production behavior.

## Frontend status update (2026-04-12)

The previously partial frontend work for this handoff is now closed in two
alpha-scoped areas:

- Store:
  - `POST /store/iap/validate` client support is now implemented
- Users / profile / social:
  - backend search is wired for add-by-username
  - backend career-summary fetch is wired into the enhanced profile screen
  - backend loadout `GET`/`PUT` wiring is in place for profile hydration/edit save
  - backend `DELETE /friends` wiring is in place for unfriend

Still not completed from this handoff:
- crypto economy player surfaces
- ML endpoint consumption in frontend UX/telemetry

Canonical remaining-work tracker:
- [`docs/REMAINING_TASKS.md`](REMAINING_TASKS.md)

---

## Backend capabilities confirmed for frontend use

## 1) Questions gameplay
- `GET /questions/set?category=&difficulty=&count=`
- `POST /questions/check`
- `POST /questions/check-batch`
- Only `Approved` questions are served.

**Frontend action:** wire gameplay question loops to these endpoints as authoritative sources.

**Status (2026-04-12):** repository-backed quiz flows now prefer
`GET /questions/set` for retrieval and use `POST /questions/check` plus
`POST /questions/check-batch` for authoritative answer validation/reconciliation,
with legacy/local fallback preserved for resilience.

## 2) Store / IAP / inventory / subscription
- `GET /store/catalog`
- `POST /store/purchase`
- `POST /store/iap/validate` (strict provider verification capable by config)
- `GET /store/inventory/{playerId}`
- `GET /store/subscription/status/{playerId}`
- `POST /store/subscription/activate`

**Frontend action:** use backend catalog/pricing as source of truth; consume purchase and IAP validation result payloads directly.

**Status (2026-04-12):** frontend wiring now includes purchase flows, external
payment/subscription return handling, reconciliation refresh, and
`POST /store/iap/validate`.

## 3) Crypto economy
- `POST /crypto/link-wallet`
- `GET /crypto/balance/{playerId}`
- `GET /crypto/history/{playerId}`
- `POST /crypto/withdraw`
- Prize pool:
  - `POST /crypto/prize-pool/fund`
  - `GET /crypto/prize-pool/{poolId}`
  - `POST /crypto/prize-pool/distribute` (admin/ops flow)
- Staking:
  - `POST /crypto/stake`
  - `POST /crypto/unstake`
  - `GET /crypto/staking/{playerId}`
- Withdrawal settlement admin controls exist for operator flow.

**Frontend action:** build player-facing wallet/history/staking UI now; keep settlement operations out of player client UX.

## 4) Users / profile / social
- `GET /users/search?handle=`
- `GET /users/{userId}/career-summary`
- `GET /users/me/preferences/loadout`
- `PUT /users/me/preferences/loadout`
- `DELETE /friends` (unfriend)

**Frontend action:** wire profile/search/loadout/friend removal directly against backend endpoints.

**Status (2026-04-12):** backend search, career-summary, loadout fetch/save, and
friend removal are now wired on the frontend. Friend request create/accept still
use local placeholder flows and can be backendized later if that contract enters
alpha scope.

## 5) ML scoring endpoints (new baseline)
- `POST /ml/churn-risk`
- `POST /ml/match-quality`
- both return `source` (`deployed-model` or `heuristic`) so UI/telemetry can track fallback behavior.

**Frontend action:** consume as optional enhancement signals (do not hard-block primary UX if source is heuristic).

---

## Items still pending (frontend impact)

1. **Runtime deployment evidence (6.1 closeout)**
   - build/migration/live-smoke proof still needs to be executed in .NET-capable runtime environment.
2. **ML model operations hardening**
   - production calibration + monitoring for deployed model health remains pending.
3. **Frontend implementation still open from this handoff**
   - crypto economy player surfaces
   - ML endpoint consumption in frontend UX/telemetry
4. **Frontend-only polish priorities (from remaining work)**
   - retention hooks
   - sound cue layer
   - copy/accessibility sweep
   - release QA pass

---

## Recommended frontend sequencing (next sprint)

1. Finalize wallet sync + purchase reconciliation against backend economy/store transactions.
2. Stage crypto wallet/history/staking screens behind feature flag.
3. Keep ML-driven UX flags optional until churn/quality backend models are promoted.

## Sequenced implementation checklist with file targets

### Phase A - Crypto service and provider wiring

1. Add a dedicated crypto service/client wrapper for the player-facing endpoints.
   File targets:
   - `lib/core/services/crypto/crypto_service.dart` (new)
   - `lib/core/services/api_service.dart` (only if helper methods or auth-path handling are needed)
2. Add typed models for wallet balance, transaction history, staking state, and wallet-link / withdraw requests.
   File targets:
   - `lib/core/models/crypto/crypto_balance_model.dart` (new)
   - `lib/core/models/crypto/crypto_history_entry_model.dart` (new)
   - `lib/core/models/crypto/crypto_staking_model.dart` (new)
   - `lib/core/models/crypto/crypto_wallet_link_request.dart` (new)
3. Expose Riverpod providers for balance, history, staking, and mutations.
   File targets:
   - `lib/game/providers/crypto_providers.dart` (new)
   - `lib/game/providers/core_providers.dart` or existing barrel/provider exports as needed

### Phase B - Crypto UI integration

4. Identify the current store/profile surfaces that should host wallet entry points and add feature-gated navigation.
   File targets:
   - `lib/screens/store/`
   - `lib/screens/profile/`
   - `lib/core/config/env.dart`
5. Build the player wallet summary surface using backend balance data as the only source of truth.
   File targets:
   - `lib/screens/store/crypto_wallet_screen.dart` (new, recommended)
   - `lib/screens/store/widgets/` for wallet summary cards if needed
6. Add transaction history and staking views, including refresh and empty/error states.
   File targets:
   - `lib/screens/store/crypto_history_screen.dart` (new, recommended)
   - `lib/screens/store/crypto_staking_screen.dart` (new, recommended)
7. Add wallet-link and withdraw actions with backend-driven status messaging.
   File targets:
   - `lib/screens/store/widgets/crypto_wallet_link_sheet.dart` (new, recommended)
   - `lib/screens/store/widgets/crypto_withdraw_sheet.dart` (new, recommended)

### Phase C - ML enhancement signal consumption

8. Add a lightweight ML service wrapper that calls churn-risk and match-quality without becoming a hard dependency.
   File targets:
   - `lib/core/services/ml/ml_signal_service.dart` (new)
   - `lib/core/models/ml/ml_signal_result.dart` (new)
9. Add Riverpod providers for optional ML signal fetches and cached display state.
   File targets:
   - `lib/game/providers/ml_providers.dart` (new)
10. Integrate churn-risk signals only where they can improve retention UX without blocking flows.
    File targets:
    - `lib/screens/home/`
    - `lib/synaptix/widgets/`
    - `lib/game/providers/` retention-related providers
11. Integrate match-quality signals only where they can improve matchmaking or recommendation presentation.
    File targets:
    - `lib/screens/question/`
    - `lib/game/controllers/`
    - `lib/game/services/`
12. Record and surface the returned `source` (`deployed-model` vs `heuristic`) as telemetry/debug metadata only.
    File targets:
    - `lib/core/services/analytics/`
    - `lib/core/services/ml/ml_signal_service.dart`

### Phase D - Verification

13. Add service/provider tests for crypto and ML fallback behavior.
    File targets:
    - `test/core/services/crypto/` (new)
    - `test/core/services/ml/` (new)
    - `test/game/providers/crypto_providers_test.dart` (new)
    - `test/game/providers/ml_providers_test.dart` (new)
14. Add widget/integration tests for feature-gated crypto UI and optional ML-driven UI changes.
    File targets:
    - `test/screens/store/`
    - `test/screens/question/`
    - `test/synaptix/widgets/`

---

## Integration notes

- Use backend balances/transactions as authoritative state (do not trust local-only wallet cache).
- Treat store purchase responses as source of updated balances.
- For crypto withdrawals and settlement status, poll backend history rather than inferring from local actions.
- Keep strict IAP behavior environment-driven; surface user-friendly retry/error messaging for transient validation failures.
