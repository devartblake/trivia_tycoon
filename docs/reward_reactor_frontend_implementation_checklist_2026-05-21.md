# Reward Reactor Frontend Implementation Checklist - 2026-05-21

This checklist is PR-ready guidance for starting the Flutter Reward Reactor implementation after frontend review of `docs/reward_reactor_frontend_handoff_2026-05-21.md`.

Status key:

- `[ ]` Not started
- `[~]` Started / partial
- `[x]` Done

---

## Current Findings

- `[x]` Existing Spin & Earn fetches wheel catalog data from `GET /arcade/spin/segments`.
- `[x]` Existing Spin & Earn claim uses encrypted `POST /arcade/spin/claim`.
- `[~]` Current `SpinWheelApiService.claimReward` still sends `segmentId` as client-provided reward authority.
- `[x]` Flutter now has `POST /arcade/spin/start` stub support via `SpinWheelApiService.startSpin` (mock fallback until backend route exists).
- `[x]` Flutter has Reward Reactor models, providers, service client, screen, and reusable machine widget — Alpha implementation complete 2026-05-22.

---

## Alpha Implementation Tasks

### Models

- `[x]` Add Reward Reactor response models for pending spin, animation hints, reward preview, reward lines, claim result, wallet snapshot, and recent rewards.
- `[x]` Add Arcade Spin start/claim compatibility models using `spinId`, `idempotencyKey`, and `claimToken`.
- `[x]` Add enum/string handling for reward mechanisms such as `reactor`, `arcade_spin`, `daily`, `mission`, and `event`.

### Service Client

- `[x]` Add a Reward Reactor service under `lib/features/reward_reactor/services/`.
- `[x]` Implement service methods for proposed `POST /arcade/reactor/spin`, `POST /arcade/reactor/claim`, and `GET /users/me/rewards`.
- `[x]` Return local mock/fallback payloads only when backend routes are unavailable or feature flag is in dev mode.
- `[x]` Extend `SpinWheelApiService` with proposed `startSpin` support without removing current segment/claim methods.

### State And Providers

- `[x]` Add Riverpod providers for reactor spin state, cooldown state, claim state, and reward history.
- `[x]` Ensure pending reward state survives animation completion until claim succeeds, fails, expires, or is dismissed.
- `[x]` Prevent duplicate claim taps while a claim request is in flight.

### UI And Animation

- `[x]` Add `ArcadeRewardMachineWidget` as the reusable reactor shell.
- `[x]` Add `RewardReactorScreen` using backend/mock animation payloads.
- `[x]` Add reel columns, symbol tiles, glow states, reward banner, action buttons, and basic particle layer.
- `[x]` Keep Alpha animation lightweight and mobile-safe before adding advanced shaders/audio/haptics.

### Navigation

- `[x]` Add a hidden/dev route in `lib/core/navigation/app_router.dart` — `/rewards/reactor` (named `reward-reactor`).
- `[ ]` Add optional navigation entry from the Arcade/Labs surface only after the feature flag is enabled.

### Arcade Spin Migration

- `[x]` Keep `GET /arcade/spin/segments` for catalog/display.
- `[x]` Add proposed `POST /arcade/spin/start` support when backend route exists (stub with mock fallback added).
- `[x]` Use returned `segmentId`/`wheelStopIndex` as animation instructions only.
- `[~]` Migrate claim payload away from trusted `segmentId` once backend supports `spinId`/`claimToken`.
- `[x]` Keep claim requests encrypted.

---

## Test Checklist

### Unit Tests

- `[x]` Reward Reactor DTO parsing handles full payloads, missing optional fields, and unknown reward line types.
- `[x]` Service client maps pending, applied, duplicate, expired, cooldown, and failure states.
- `[~]` Arcade Spin start response parsing maps server-selected animation target without trusting client-selected reward (`SpinStartResponse` model added; dedicated test file not yet written).

### Provider Tests

- `[ ]` Start spin transitions idle -> spinning -> pending claim.
- `[ ]` Claim transitions pending claim -> applied.
- `[ ]` Duplicate claim returns stable duplicate state and does not double-apply UI rewards.
- `[ ]` Expired/cooldown responses show retry/cooldown state.

### Widget Tests

- `[ ]` Reward Reactor screen renders loading, ready, spinning, pending claim, applied, cooldown, and error states.
- `[ ]` Long reward names and multi-line reward previews do not overflow.
- `[ ]` Claim button is disabled while claim is in flight.

### Live Smoke Tests

- `[ ]` Existing `GET /arcade/spin/segments` still loads.
- `[ ]` Existing `POST /arcade/spin/claim` continues to work until the backend migration lands.
- `[ ]` Future `POST /arcade/spin/start` returns a server-generated outcome before animation starts.
- `[ ]` Future Reward Reactor start/claim routes apply rewards idempotently.

---

## Non-Negotiables

- Frontend does not choose rewards.
- Frontend does not send reward amount as authority.
- Frontend does not trust locally selected `segmentId` as the final reward.
- Frontend only animates backend-provided outcome data.
- Reward Reactor copy must avoid real-money gambling framing.
