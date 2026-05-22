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
- `[ ]` Flutter does not yet have `POST /arcade/spin/start` support.
- `[ ]` Flutter does not yet have Reward Reactor models, providers, service client, screen, or reusable machine widget.

---

## Alpha Implementation Tasks

### Models

- `[ ]` Add Reward Reactor response models for pending spin, animation hints, reward preview, reward lines, claim result, wallet snapshot, and recent rewards.
- `[ ]` Add Arcade Spin start/claim compatibility models using `spinId`, `idempotencyKey`, and `claimToken`.
- `[ ]` Add enum/string handling for reward mechanisms such as `reactor`, `arcade_spin`, `daily`, `mission`, and `event`.

### Service Client

- `[ ]` Add a Reward Reactor service under `lib/features/reward_reactor/services/`.
- `[ ]` Implement service methods for proposed `POST /arcade/reactor/spin`, `POST /arcade/reactor/claim`, and `GET /users/me/rewards`.
- `[ ]` Return local mock/fallback payloads only when backend routes are unavailable or feature flag is in dev mode.
- `[ ]` Extend `SpinWheelApiService` with proposed `startSpin` support without removing current segment/claim methods.

### State And Providers

- `[ ]` Add Riverpod providers for reactor spin state, cooldown state, claim state, and reward history.
- `[ ]` Ensure pending reward state survives animation completion until claim succeeds, fails, expires, or is dismissed.
- `[ ]` Prevent duplicate claim taps while a claim request is in flight.

### UI And Animation

- `[ ]` Add `ArcadeRewardMachineWidget` as the reusable reactor shell.
- `[ ]` Add `RewardReactorScreen` using backend/mock animation payloads.
- `[ ]` Add reel columns, symbol tiles, glow states, reward banner, action buttons, and basic particle layer.
- `[ ]` Keep Alpha animation lightweight and mobile-safe before adding advanced shaders/audio/haptics.

### Navigation

- `[ ]` Add a hidden/dev route or feature-flagged route in `lib/core/navigation/app_router.dart`.
- `[ ]` Add optional navigation entry from the Arcade/Labs surface only after the feature flag is enabled.

### Arcade Spin Migration

- `[ ]` Keep `GET /arcade/spin/segments` for catalog/display.
- `[ ]` Add proposed `POST /arcade/spin/start` support when backend route exists.
- `[ ]` Use returned `segmentId`/`wheelStopIndex` as animation instructions only.
- `[ ]` Migrate claim payload away from trusted `segmentId` once backend supports `spinId`/`claimToken`.
- `[ ]` Keep claim requests encrypted.

---

## Test Checklist

### Unit Tests

- `[ ]` Reward Reactor DTO parsing handles full payloads, missing optional fields, and unknown reward line types.
- `[ ]` Service client maps pending, applied, duplicate, expired, cooldown, and failure states.
- `[ ]` Arcade Spin start response parsing maps server-selected animation target without trusting client-selected reward.

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

