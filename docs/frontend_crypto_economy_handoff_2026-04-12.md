# Frontend Crypto Economy Handoff (2026-04-12)

_Source: Backend / Platform Team handoff for frontend Flutter integration_

## Purpose

This document captures the backend handoff for the Synaptix crypto economy and turns it into an actionable frontend reference.

Audience:
- Flutter/mobile frontend

Backend branch:
- `claude/synaptix-backend-plan-64TiO`

Date:
- `2026-04-12`

## Status update (2026-04-14)

The initial frontend crypto slice is no longer purely planned. The following are
implemented in the app codebase:

- shared crypto models and validation utilities
- `CryptoService` service-layer wrapper
- Riverpod provider wiring for wallet/profile consumption
- a base wallet screen
- transaction history section
- withdraw action flow
- pending-withdraw polling behavior
- history pagination / "view all" path
- profile-surface crypto summary/branding

Still remaining for the crypto track:

- final live backend/runtime verification in a Flutter-enabled environment
- broader widget/integration test coverage for the crypto UI flows
- any backend-confirmed gating for Phase 2 networks (`snx`, `shib`)
- portable avatar/object-storage work is separate from crypto and remains tracked
  in the main backlog

---

## 1. System Overview

The frontend talks only to the .NET Backend API. The Python Crypto Service is internal and should not be called directly by the app.

Architecture:

```text
FRONTEND (Flutter)
  wallet link · balance · history · stake · withdraw
              |
              | JWT bearer token on every /crypto call
              v
.NET Backend API :5000/crypto/*
  Authoritative ledger in PostgreSQL PlayerTransaction
  Off-chain accounting only
              |
              | ADMIN_OPS_KEY (internal only)
              v
Python Crypto Service :8300
  Polls pending withdrawals and submits on-chain transactions
  SOL · XRP · SNX (Phase 2) · SHIB (Phase 2)
```

Frontend rule:
- Never call port `8300` directly from Flutter.
- All player-facing traffic goes through the .NET API under `/crypto/*`.

---

## 2. Supported Networks

| Network key | Asset | Blockchain | Phase | Status |
|------|------|------|------|------|
| `solana` | SOL | Solana Mainnet | 1 | Active |
| `xrp` | XRP | XRP Ledger | 1 | Active |
| `snx` | SNX (Synaptix Coin) | Solana (SPL token) | 2 | Configured when `SNX_MINT_ADDRESS` is set |
| `shib` | SHIB | Ethereum | 2 | Requires `ETHEREUM_RPC_URL` |

Frontend guidance:
- Always send the `network` field explicitly.
- If omitted, the backend defaults to `solana`, but explicit is safer.
- For now, Phase 1 UI can safely hardcode `solana` and `xrp` unless backend confirms `snx` or `shib` are live.

### Address format requirements

| Network | Format | Example |
|------|------|------|
| `solana` / `snx` | Base58, 32 bytes decoded, usually 32-44 chars | `7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV` |
| `xrp` | Starts with `r`, 25-34 base58 chars | `rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh` |
| `shib` | `0x` + 40 hex chars, EIP-55 checksum preferred | `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045` |

### Client-side validation requirement

The backend recommends validating addresses client-side before link-wallet or withdrawal confirmation.

`POST /crypto/validate-address` exists on the Python service, but it is not currently frontend-accessible.

For now:
- Implement client-side validation only.
- Treat backend `VALIDATION_ERROR` as the server-side fallback.

Reference validation logic:

```dart
bool isValidAddress(String address, String network) {
  switch (network) {
    case 'solana':
    case 'snx':
      final decoded = base58Decode(address);
      return decoded.length == 32;
    case 'xrp':
      return address.startsWith('r') &&
          address.length >= 25 &&
          address.length <= 34;
    case 'shib':
      return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
    default:
      return false;
  }
}
```

---

## 3. Authentication

All `/crypto/*` endpoints on the .NET API require a valid JWT bearer token.

Headers:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Auth behavior:
- Login: `POST /auth/login`
- Refresh: `POST /auth/refresh`
- Same token lifetime rules as the rest of the authenticated API:
- 60-minute access token
- 30-day refresh token

---

## 4. Internal Unit System

Crypto balances are tracked as integer units in the ledger.

Important frontend rule:
- Treat `units` as the canonical display value.
- Do not apply token decimals yourself.
- The number returned by the API is the number to show in the UI.

Example:

```json
{
  "units": 500,
  "unitType": "CRYPTO_UNITS"
}
```

Display example:
- `500 SNX`
- `500 SOL`
- `500 XRP`

The displayed symbol should come from the selected or linked network, but the numeric value should remain unchanged.

---

## 5. Player-Facing .NET API Endpoints

Base URL:
- `http://<host>:5000`
- or via Traefik: `/api`

### 5.1 Link Wallet

`POST /crypto/link-wallet`

Request:

```json
{
  "playerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "walletAddress": "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV",
  "network": "solana"
}
```

Notes:
- `playerId` must match the authenticated player.
- Re-calling this endpoint updates the linked wallet.
- Each link call creates a new applied transaction; the most recent wallet is active.

Success response:

```json
{
  "playerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "walletAddress": "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV",
  "network": "solana",
  "transactionId": "a1b2c3d4-...",
  "status": "Applied"
}
```

Errors:
- `400 VALIDATION_ERROR`
- `503 CRYPTO_DISABLED`

### 5.2 Get Balance

`GET /crypto/balance/{playerId}`

Success response:

```json
{
  "playerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "units": 1250,
  "unitType": "CRYPTO_UNITS"
}
```

Frontend guidance:
- This is the source of truth.
- Do not maintain a local balance cache as the authoritative value.

### 5.3 Transaction History

`GET /crypto/history/{playerId}?page=1&pageSize=20`

Query parameters:

| Param | Default | Max |
|------|------|------|
| `page` | 1 | - |
| `pageSize` | 20 | 100 |

Success response:

```json
{
  "page": 1,
  "pageSize": 20,
  "total": 47,
  "items": [
    {
      "transactionId": "a1b2c3d4-...",
      "kind": "crypto-withdraw-request",
      "unitsDelta": -100,
      "status": "Pending",
      "receiptRef": "7EcDhSYGx...",
      "createdAtUtc": "2026-04-12T14:00:00Z",
      "completedAtUtc": null
    }
  ]
}
```

Display labels:

| kind | Display label | Sign |
|------|------|------|
| `crypto-wallet-link` | Wallet linked | neutral |
| `crypto-withdraw-request` | Withdrawal request | negative |
| `crypto-stake-lock` | Staked | negative |
| `crypto-stake-unlock` | Unstaked | positive |
| `crypto-prize-pool-fund` | Contributed to prize pool | negative |
| `crypto-prize-pool-payout` | Prize pool winnings | positive |

Status meanings:

| Value | Meaning |
|------|------|
| `Pending` | Queued, not yet settled on-chain |
| `Applied` | Confirmed, balance affected |
| `Failed` | Rejected or on-chain failure |
| `Reversed` | Reversed by admin |

### 5.4 Request Withdrawal

`POST /crypto/withdraw`

Request:

```json
{
  "playerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "units": 100,
  "toWalletAddress": "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV",
  "network": "solana"
}
```

Success response:

```json
{
  "transactionId": "c3d4e5f6-...",
  "status": "Pending",
  "units": 100,
  "network": "solana"
}
```

Errors:

| HTTP | Code | Meaning | Recommended UI |
|------|------|------|------|
| 400 | `VALIDATION_ERROR` | Missing required fields | Show field error |
| 400 | `MIN_WITHDRAWAL` | Below minimum threshold | Show minimum amount |
| 409 | `WALLET_NOT_LINKED` | No linked wallet on file | Navigate to wallet-link |
| 409 | `INSUFFICIENT_CRYPTO_BALANCE` | Not enough units | Show balance vs required |
| 503 | `CRYPTO_DISABLED` | Feature disabled | Show maintenance / coming soon |

Withdrawal lifecycle:

1. Player calls `POST /crypto/withdraw`
2. Transaction enters `Pending`
3. Settlement worker processes it on the next poll cycle
4. Outcome becomes `Applied` or `Failed`

UX guidance:
- Show pending withdrawals clearly.
- Do not visually reduce spendable balance until the withdrawal is `Applied`.
- Poll history while any item is pending.

### 5.5 Staking

Stake:
- `POST /crypto/stake`

Unstake:
- `POST /crypto/unstake`

Example request body:

```json
{
  "playerId": "3fa85f64-...",
  "units": 200,
  "stakeId": "season-3-stake"
}
```

Get staking position:
- `GET /crypto/staking/{playerId}`

Example response:

```json
{
  "playerId": "3fa85f64-...",
  "availableUnits": 1050,
  "stakedUnits": 350,
  "unitType": "CRYPTO_UNITS"
}
```

Errors:
- `409 INSUFFICIENT_CRYPTO_BALANCE`
- `409 INSUFFICIENT_STAKED_BALANCE`
- `503 CRYPTO_DISABLED`

Frontend guidance:
- `availableUnits` is spendable.
- `stakedUnits` is locked.

### 5.6 Prize Pools

Fund a pool:
- `POST /crypto/prize-pool/fund`

Get pool balance:
- `GET /crypto/prize-pool/{poolId}`

Notes:
- Frontend only funds and reads pools.
- Distribution is admin-only and not called by the player app.

Errors:
- `409 INSUFFICIENT_CRYPTO_BALANCE`
- `503 CRYPTO_DISABLED`

---

## 6. Error Envelope

All .NET API errors use this shape:

```json
{
  "error": {
    "code": "INSUFFICIENT_CRYPTO_BALANCE",
    "message": "Insufficient crypto balance."
  }
}
```

Frontend handling rule:
- Parse `error.code` for behavior.
- Use `error.message` only as fallback display copy.

### Complete error code reference

| Code | HTTP | Trigger | Recommended UI |
|------|------|------|------|
| `CRYPTO_DISABLED` | 503 | Server-side flag off | "Crypto features are temporarily unavailable." |
| `VALIDATION_ERROR` | 400 | Missing or empty required fields | Highlight the field |
| `MIN_WITHDRAWAL` | 400 | Below minimum withdrawal | Show minimum amount |
| `WALLET_NOT_LINKED` | 409 | No linked wallet | Navigate to wallet link |
| `INSUFFICIENT_CRYPTO_BALANCE` | 409 | Units lower than request | Show current balance vs required |
| `INSUFFICIENT_STAKED_BALANCE` | 409 | Unstake exceeds staked units | Show current staked amount |
| `INSUFFICIENT_PRIZE_POOL_BALANCE` | 409 | Admin-only pool shortage | Not shown to players |

---

## 7. Recommended Screen Flow

### Crypto Wallet Screen

- If wallet is not linked:
- Show `Link Wallet`
- Include network picker
- Include address input with inline client-side validation
- Submit `POST /crypto/link-wallet`

- If wallet is linked:
- Show balance card
- Refresh with `GET /crypto/balance/{playerId}`
- Show staked / available breakdown via `GET /crypto/staking/{playerId}`
- Show withdraw action
- Show stake / unstake actions
- Show transaction history tab from `GET /crypto/history/{playerId}`

- Optional prize pool section:
- Read from `GET /crypto/prize-pool/global`
- Fund via `POST /crypto/prize-pool/fund`

History item visuals:
- `Pending` -> spinner / clock
- `Applied` -> success/checkmark
- `Failed` -> error state / red X

---

## 8. Polling and Refresh Strategy

| State | How to refresh | When |
|------|------|------|
| Balance | `GET /crypto/balance/{id}` | On screen focus, after any mutating call |
| Pending withdrawals | `GET /crypto/history/{id}` | Poll every 15s while any item is `Pending` |
| Staking position | `GET /crypto/staking/{id}` | On screen focus |
| Prize pool | `GET /crypto/prize-pool/{poolId}` | On screen focus |

Rules:
- Stop polling history when all items are `Applied` or `Failed`.
- Do not poll globally.
- Poll only while the user is on the crypto screen and there is at least one pending item.

---

## 9. Feature Flag Behavior

When backend crypto is disabled, these write endpoints return `503 CRYPTO_DISABLED`:

- `POST /crypto/link-wallet`
- `POST /crypto/withdraw`
- `POST /crypto/stake`
- `POST /crypto/unstake`
- `POST /crypto/prize-pool/fund`

These read endpoints remain available:

- `GET /crypto/balance/{id}`
- `GET /crypto/history/{id}`
- `GET /crypto/staking/{id}`
- `GET /crypto/prize-pool/{id}`

Recommended frontend behavior:
- Call `GET /crypto/balance/{id}` to decide whether to show the crypto section.
- If writes return `503`, show a maintenance / coming soon banner instead of hiding read-only crypto surfaces.

---

## 10. Phase 2 Network Readiness

Backend-supported but not guaranteed active yet:
- `snx`
- `shib`

Activation conditions:
- `snx` requires `SNX_MINT_ADDRESS`
- `shib` requires `ETHEREUM_RPC_URL`

Frontend guidance:
- Prefer Phase 1 networks only (`solana`, `xrp`) unless operators confirm the others are live.

---

## 11. Environment URLs

| Environment | .NET API base |
|------|------|
| Local Docker | `http://localhost:5000` |
| Traefik | `http://localhost:80/api` |
| Staging | TBD |
| Production | TBD |

Frontend rule:
- Crypto uses the same API base URL as the rest of the app.
- Append `/crypto/...` to the existing backend base.

---

## 12. Quick Reference

| Endpoint | Purpose |
|------|------|
| `POST /crypto/link-wallet` | Link external wallet address |
| `GET /crypto/balance/{id}` | Get spendable units |
| `GET /crypto/history/{id}` | Get paginated transaction log |
| `POST /crypto/withdraw` | Request on-chain withdrawal |
| `POST /crypto/stake` | Lock units for staking |
| `POST /crypto/unstake` | Unlock staked units |
| `GET /crypto/staking/{id}` | Get available + staked breakdown |
| `POST /crypto/prize-pool/fund` | Contribute to named prize pool |
| `GET /crypto/prize-pool/{poolId}` | Get prize pool balance |

Global rules:
- All endpoints require `Authorization: Bearer <token>`.
- Always send `network`.
- Treat `units` as the display value.
- Withdrawals are async and remain `Pending` until settled.

---

## 13. Frontend Task List, Prioritized Easiest -> Hardest

### Tier 1 - Fastest and lowest risk

1. Add shared crypto enums/constants for active networks and transaction status/kind labels.
   Suggested file targets:
   - `lib/core/models/crypto/crypto_network.dart`
   - `lib/core/models/crypto/crypto_transaction_kind.dart`
2. Add client-side wallet address validation helpers for `solana`, `xrp`, and gated placeholders for `snx` / `shib`.
   Suggested file targets:
   - `lib/core/utils/crypto_address_validator.dart`
   - `test/core/utils/crypto_address_validator_test.dart`
3. Add typed response/request models for balance, history, staking, link-wallet, withdraw, and prize-pool funding.
   Suggested file targets:
   - `lib/core/models/crypto/crypto_balance_model.dart`
   - `lib/core/models/crypto/crypto_history_response.dart`
   - `lib/core/models/crypto/crypto_history_item.dart`
   - `lib/core/models/crypto/crypto_staking_model.dart`
   - `lib/core/models/crypto/crypto_link_wallet_request.dart`
   - `lib/core/models/crypto/crypto_withdraw_request.dart`
   - `lib/core/models/crypto/crypto_prize_pool_model.dart`

### Tier 2 - Straightforward service-layer integration

4. Add a `CryptoService` wrapper for all player-facing .NET endpoints.
   Suggested file targets:
   - `lib/core/services/crypto/crypto_service.dart`
   - `lib/core/services/api_service.dart` only if small shared API helpers are needed
5. Add structured crypto error parsing so the UI can branch on `error.code`.
   Suggested file targets:
   - `lib/core/models/crypto/crypto_api_error.dart`
   - `lib/core/services/crypto/crypto_service.dart`
6. Add service tests covering happy paths and key backend error codes.
   Suggested file targets:
   - `test/core/services/crypto/crypto_service_test.dart`

### Tier 3 - Provider/state wiring

7. Add Riverpod providers for:
   - balance
   - history pagination
   - staking position
   - link wallet mutation
   - withdraw mutation
   - stake / unstake mutations
   - prize pool read/fund
   Suggested file targets:
   - `lib/game/providers/crypto_providers.dart`
   - `test/game/providers/crypto_providers_test.dart`
8. Add screen-focus refresh and pending-history polling behavior.
   Suggested file targets:
   - `lib/game/providers/crypto_providers.dart`
   - whichever screen/controller owns the crypto surface

### Tier 4 - Core user-facing UI

9. Build the base crypto wallet screen with:
   - linked / unlinked states
   - balance card
   - staking summary
   - maintenance banner for `CRYPTO_DISABLED`
   Suggested file targets:
   - `lib/screens/store/crypto_wallet_screen.dart`
   - `lib/screens/store/widgets/crypto_balance_card.dart`
   - `lib/screens/store/widgets/crypto_feature_banner.dart`
10. Build the link-wallet flow with network picker, inline validation, and backend submission.
    Suggested file targets:
    - `lib/screens/store/widgets/crypto_link_wallet_sheet.dart`
    - `lib/screens/store/widgets/crypto_network_picker.dart`
11. Build the transaction history list with status icons and pagination.
    Suggested file targets:
    - `lib/screens/store/widgets/crypto_history_list.dart`
    - `lib/screens/store/widgets/crypto_history_item_tile.dart`
12. Build stake / unstake interactions.
    Suggested file targets:
    - `lib/screens/store/widgets/crypto_stake_sheet.dart`
    - `lib/screens/store/widgets/crypto_unstake_sheet.dart`
13. Build the withdrawal flow with:
    - amount validation
    - destination address prefill
    - pending confirmation state
    Suggested file targets:
    - `lib/screens/store/widgets/crypto_withdraw_sheet.dart`

### Tier 5 - Extended UX and optional surfaces

14. Add optional prize-pool read/fund UI if it belongs in Alpha scope.
    Suggested file targets:
    - `lib/screens/store/widgets/crypto_prize_pool_card.dart`
    - `lib/screens/store/widgets/crypto_fund_pool_sheet.dart`
15. Add feature gating for Phase 2 networks (`snx`, `shib`) so they can be enabled without redesigning the UI.
    Suggested file targets:
    - `lib/core/config/env.dart`
    - `lib/core/models/crypto/crypto_network.dart`
    - `lib/screens/store/widgets/crypto_network_picker.dart`

### Tier 6 - Highest effort / cross-cutting work

16. Integrate the crypto wallet entry point cleanly into existing store/profile navigation.
    Suggested file targets:
    - `lib/screens/store/`
    - `lib/screens/profile/`
    - `lib/core/router/` or GoRouter route configuration
17. Add widget and integration tests for linked/unlinked, pending withdrawal, and disabled-feature states.
    Suggested file targets:
    - `test/screens/store/crypto_wallet_screen_test.dart`
    - `test/screens/store/crypto_link_wallet_flow_test.dart`
    - `test/screens/store/crypto_withdraw_flow_test.dart`
18. Add final runtime verification in a Flutter-enabled environment with live auth and backend responses.
    Suggested verification:
    - link wallet
    - refresh balance
    - create withdrawal
    - observe pending -> applied or failed
    - stake / unstake
    - disabled-feature 503 behavior

---

## 14. Recommended First Implementation Slice

If the goal is the smallest useful vertical slice, start here:

1. Add models and `CryptoService`
2. Add address validation helper
3. Add providers for balance, staking, and link-wallet
4. Build the base wallet screen with linked / unlinked states
5. Add withdrawal after balance + history are stable

This gives the app a usable crypto surface quickly without committing to the full extended feature set on day one.
