# Reward Reactor Frontend Handoff - 2026-05-21

Backend source docs:

- `docs/backend/Synaptix_Reward_Reactor_Backend_System_Design.md`
- `docs/frontend/Synaptix_Arcade_Reward_Reactor_Flutter_Implementation_Blueprint.md`

This handoff prepares the Flutter implementation for the Synaptix Reward Reactor and the Arcade Spin migration to a shared backend-authoritative reward lifecycle.

The Reward Reactor is not a slot machine or gambling feature. It is a progression/reward feedback framework. The backend determines outcomes; Flutter renders animation and player feedback.

---

## Backend-Authoritative Reward Flow

Reward Reactor and Arcade Spin should converge on the same lifecycle:

```text
Start / Spin request
        |
        v
Backend validates eligibility, cooldown, feature gates, and limits
        |
        v
Backend selects reward using server-side RNG and reward policy
        |
        v
Backend persists a pending reward outcome
        |
        v
Flutter receives animation-safe result data
        |
        v
Flutter animates reels, wheel, particles, sounds, and reward preview
        |
        v
Claim request idempotently applies the pending reward
```

Frontend must never send a selected reward, segment, amount, inventory mutation, RNG value, or probability as authority.

---

## Proposed API Contracts

These routes are proposed/future unless marked current.

### Reward Reactor

| Route | Purpose | Frontend role |
|---|---|---|
| `POST /arcade/reactor/spin` | Create a pending server-generated reactor reward | Request spin, render returned animation payload |
| `POST /arcade/reactor/claim` | Apply the pending reward once | Claim by `spinId` and `claimToken`; handle duplicate/expired states |
| `GET /users/me/rewards` | Return pending and recent reward state | Hydrate pending/recent reward UI |

Expected frontend DTOs should cover:

- `spinId`
- `status`
- `expiresAtUtc`
- `cooldownUntilUtc`
- `animation.layout`
- `animation.symbols`
- `animation.winningSymbolIndexes`
- `animation.rarity`
- `animation.intensity`
- `rewardPreview.rewardId`
- `rewardPreview.displayName`
- `rewardPreview.lines`
- `claimToken`

### Arcade Spin Alignment

| Route | Status | Frontend role |
|---|---|---|
| `GET /arcade/spin/segments` | Current | Keep for wheel display/catalog compatibility |
| `POST /arcade/spin/start` | Proposed/future | Ask backend to generate the winning spin outcome |
| `POST /arcade/spin/claim` | Current, semantics should evolve | Claim pending reward by `spinId`/`claimToken`, not trusted `segmentId` |

Current Flutter behavior in `SpinWheelApiService.claimReward` still sends `playerId`, `segmentId`, and `spinId` to `POST /arcade/spin/claim`. Treat this as legacy/current behavior until the backend adds the start/pending-claim flow.

---

## Flutter Implementation Direction

### Feature Area

Use a new feature folder for the Reward Reactor:

```text
lib/features/reward_reactor/
  controllers/
  models/
  painters/
  providers/
  services/
  widgets/
  animations/
  effects/
  particles/
  screens/
```

Keep this separate from the existing Spin & Earn implementation until the backend-authoritative lifecycle is stable.

### Alpha Frontend Build

Alpha should prioritize:

- Typed API models for spin/start, claim, reward preview, reward lines, animation hints, and cooldown state.
- A service client for proposed Reward Reactor endpoints with local mock/fallback data while backend routes are pending.
- Riverpod providers for pending spin state, cooldown state, claim state, and recent reward state.
- A reusable `ArcadeRewardMachineWidget` shell with reels, symbol tiles, reward banner, and action controls.
- A `RewardReactorScreen` route behind a feature flag or hidden/dev navigation entry.
- Animation-safe parsing from backend payloads; no local reward selection.
- Basic particle/glow effects that remain performant on mobile.

Beta and production can add advanced particles, shaders, haptics/audio polish, reward chains, missions, live events, and seasonal reactors.

---

## Current Flutter Entry Points

Use these as the starting map for integration:

- `lib/core/services/arcade/spin_wheel_api_service.dart`
  - Current backend-backed Spin & Earn API client.
  - Needs future `startSpin` support when `POST /arcade/spin/start` exists.
- `lib/ui_components/spin_wheel/`
  - Existing wheel UI, animation, segment loading, and claim flow.
  - Should be migrated carefully, not removed abruptly.
- `lib/arcade/`
  - Current Labs/arcade feature area with missions, rewards, local game results, and local reward computation.
  - Reward Reactor can integrate later with missions and arcade completion rewards.
- `lib/core/navigation/app_router.dart`
  - Route registration target for `/arcade/reward-reactor` or equivalent hidden/dev entry.

---

## Arcade Spin Migration Notes

Do not break the current Spin & Earn screen while the backend start route is still proposed.

Recommended migration path:

1. Keep `GET /arcade/spin/segments` for wheel catalog/display.
2. Add frontend models and service methods for proposed `POST /arcade/spin/start`.
3. When backend supports start, use returned `segmentId`/`wheelStopIndex` only as animation instructions.
4. Change claim payload to use `spinId`, `idempotencyKey`, and `claimToken`.
5. Stop treating frontend-selected `segmentId` as reward authority.
6. Preserve encrypted `POST /arcade/spin/claim` behavior for sensitive claim requests.

---

## UX And Design Guardrails

- Use arcade/neon/sci-fi reward polish, but avoid gambling or casino terminology in player-facing copy.
- Do not use `GridView` for the reactor reels; use `Stack`, `Positioned`, or `CustomMultiChildLayout`.
- Isolate animations with repaint boundaries and keep rebuilds narrow.
- Prefer Flutter-native rendering, `CustomPainter`, sprite sheets/WebP, and animation controllers.
- Keep the first Alpha version usable before adding expensive shader/audio/haptic layers.

---

## Open Questions — Resolved (2026-05-22)

| Question | Decision |
|---|---|
| Which route should host the Alpha screen? | `/rewards/reactor` — registered in GoRouter, `onboardingGuard` applied. Internal testers reach it via `/admin/reward-reactor` (admin panel tile, no flag required). |
| Mock-only or wired service from the start? | Both — `BackendRewardReactorService` is wired to all three backend endpoints with graceful mock fallback when routes are not yet live. |
| Should claim use the encrypted client from the start? | Yes — `POST /arcade/reactor/claim` routes through `EncryptedApiClient`, matching Spin & Earn claim behavior. |
| Which first reward sources for Alpha mock? | Daily login (50 Coins), Mission Complete (100 XP), Arcade Challenge (1 Skin Token) — all three lines returned in a single `alpha-combined` mock spin response. |

