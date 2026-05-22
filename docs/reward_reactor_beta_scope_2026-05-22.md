# Reward Reactor — Beta Scope Reference

**Document date:** 2026-05-22
**Alpha status:** Complete (see `docs/reward_reactor_frontend_implementation_checklist_2026-05-21.md`)

This document lists each feature area that is intentionally deferred from Alpha to Beta or production. For each item it explains what it is, why it was deferred, and what concrete prerequisites must be satisfied before it can be built.

---

## 1. Advanced Particles and Shaders

### What it is
Replace the Alpha `CustomPainter` circle-based particle layer with GPU-accelerated effects: neon glow shaders via `dart:ui` fragment programs (`flutter_shaders` package), animated sprite sheets (WebP sequences), and per-reel stop burst particles that scale with reward rarity.

### Why deferred
- Fragment shaders require Impeller to be stable on all target platforms. At Alpha cut, Impeller was not yet the default on Android.
- Shader authoring requires a dedicated art/VFX pass that has not been scoped or scheduled.
- The Alpha particle layer already passes the non-negotiable mobile-safe performance bar. Adding shaders before profiling creates risk without player-visible payoff.

### What must happen to unblock
1. Confirm Impeller is stable and default-enabled on the minimum supported Android/iOS versions.
2. VFX designer produces rarity-tiered burst assets (common, uncommon, rare, legendary) as WebP sprite sheets or GLSL fragment programs.
3. Performance baseline established on low-end device (≤2 GB RAM, Snapdragon 450 class) — target: ≤5 ms per frame during peak particle activity.
4. `ReactorParticleLayer` refactored to accept a `ReactorRarity` parameter and swap in the appropriate asset.

---

## 2. Haptics and Audio Polish

### What it is
Tactile and audio feedback at key moments: reel column stopping (light haptic pulse per column with staggered timing), win reveal (medium haptic + ascending chime), claim confirmation (success haptic + coin-drop sound), and cooldown deflection (error haptic + low-frequency buzz).

### Why deferred
- Audio assets (sound effects, short music stings) do not exist yet and require UX/sound design sign-off.
- Haptic patterns need UX design to define per-event intensity and timing, separate from gameplay haptics already in the app.
- `HapticFeedback` (Flutter built-in) covers basic patterns; `flutter_vibration` is needed for custom waveforms on Android — adding a new dependency requires dependency-committee approval.
- Implementing audio before sound assets exist results in placeholder code that must be rewritten.

### What must happen to unblock
1. UX/sound design delivers haptic pattern spec (event → `HapticFeedback` level or custom waveform).
2. Audio assets delivered: at least `spin_start.mp3`, `reel_stop_0/1/2.mp3`, `win_reveal.mp3`, `claim_success.mp3`.
3. `flutter_vibration` (or `audioplayers`) approved and added to `pubspec.yaml`.
4. `ReactorReelColumn.onStopped` callback added to `arcade_reward_machine_widget.dart` so the audio/haptic layer can respond to individual reel stop events.

---

## 3. Reward Chains

### What it is
A follow-on reactor spin that is automatically triggered after a rare or legendary reward, presenting a "chain bonus" without an extra player tap. The backend returns a `chainedSpinId` in the claim response that pre-seeds the next spin's animation payload.

### Why deferred
- Requires a new backend field: `ReactorClaimResponse.chainedSpinId` (nullable) and a corresponding `POST /arcade/reactor/chain` endpoint or an updated `startSpin` that accepts a `chainId` parameter.
- Player testing has not validated that chains improve engagement vs. confusing players; this is gated on Alpha A/B data.
- `ReactorNotifier.claim()` state machine needs a new `chaining` phase and a `chainedSpin` field in `ReactorState`.

### What must happen to unblock
1. Backend implements `chainedSpinId` in claim response and the chain lifecycle endpoint.
2. Alpha A/B test ships with at least 2 weeks of data; product decides to proceed.
3. `ReactorClaimResponse` extended with `chainedSpinId?`.
4. `ReactorNotifier` extended with `chain()` method and `chaining` phase.
5. `ArcadeRewardMachineWidget` shows a "Chain Bonus!" banner and automatically calls `chain()`.

---

## 4. Mission Integration

### What it is
A reactor spin triggered automatically upon completing an Arcade Mission. Instead of (or in addition to) a coin reward, the mission completion payload includes a `rewardMechanismId: reactor` that launches a reactor overlay without requiring navigation to `/rewards/reactor`.

### Why deferred
- The `ArcadeMissionService` and `ArcadeMissionClaimService` do not yet emit a `rewardMechanismId` field; the backend mission completion endpoint must be updated first.
- The reactor overlay (shown over the mission screen without full-screen navigation) requires a reusable `ReactorOverlay` widget wrapping `ArcadeRewardMachineWidget` in a `BottomSheet` or `Dialog` — not yet designed.
- Mixing mission and reactor state in the same screen adds lifecycle complexity that should not be introduced until the reactor state machine is proven stable in isolation.

### What must happen to unblock
1. Backend adds `rewardMechanismId` and `reactorSpinPayload` to the mission claim response schema.
2. `ArcadeMissionClaimService` parses `rewardMechanismId` and emits it via a new stream or callback.
3. `ReactorOverlay` widget designed and built (wraps `ArcadeRewardMachineWidget` as a sheet, shares the existing `reactorProvider`).
4. Mission claim flow checks `rewardMechanismId == 'reactor'` and shows the overlay instead of (or after) the existing coin toast.

---

## 5. Live Events

### What it is
Time-limited reactor configurations that override the default daily-login reward with event-specific rewards: double-coins weekend, seasonal bonus week, anniversary jackpot. The backend returns an `eventId` and `eventMultiplier` in the spin response; the UI shows an event banner above the reels and adapts the particle rarity display.

### Why deferred
- Requires the backend live-events system (`/events/active`) to exist and return event context that is merged into the spin response.
- Event UI (banner, themed symbol overlays) requires art assets per event that are not scheduled.
- No live events have been defined for the Alpha period; building infrastructure for zero active events wastes scope.

### What must happen to unblock
1. Backend live-events API (`GET /events/active` and event-context injection into `POST /arcade/reactor/spin`) is designed and documented.
2. `ReactorSpinResponse` extended with `eventId?` and `eventMultiplier?`.
3. `ReactorRewardBanner` updated to show event badge when `eventId` is present.
4. At least one event is defined in the backend event catalog before UI work begins.

---

## 6. Seasonal Reactors

### What it is
Per-season visual themes applied to the reactor: Halloween uses pumpkin/bat/skull symbols; Winter uses snowflake/gift/star; Spring uses flower/sun/leaf. Symbol sets, particle colors, and reel border styles all change based on the active season key returned in the spin response.

### Why deferred
- Requires a seasonal asset pipeline: symbol icon sets (SVG or WebP per season), particle color palettes, and border theme tokens — none of which exist.
- `ReactorAnimationHints` currently has a fixed `symbols` list (string keys mapped to emoji in `ReactorSymbolTile`). Seasonal support requires either a CDN-backed asset URL per symbol key or a bundled asset map, both of which require infrastructure decisions not yet made.
- Seasonal cadence (when seasons rotate) must be agreed with product and matched to backend `seasonKey` in the config API.

### What must happen to unblock
1. Product defines seasonal calendar and symbol set per season.
2. Art delivers symbol assets (SVG or 64 × 64 WebP) per season, plus particle color palettes.
3. `AppConfig` or spin response includes `seasonKey` (e.g., `'halloween_2026'`).
4. `ReactorSymbolTile` extended to load assets from a season-keyed asset map instead of the hardcoded emoji map.
5. Asset delivery strategy decided: bundled in app (increases binary size) vs. remote CDN (requires asset-download service wiring).

---

## 7. Arcade Spin `segmentId` → `spinId` / `claimToken` Migration

### What it is
The existing `POST /arcade/spin/claim` still sends `playerId`, `segmentId`, and `spinId`, meaning the frontend is still a trusted authority over which reward segment was won. The migration replaces this with a server-generated `spinId` and `claimToken` that the backend issued — the frontend can no longer influence the reward outcome.

### Why deferred
- Blocked entirely by backend: `POST /arcade/spin/start` does not exist yet. Until it does, there is no server-generated `spinId` / `claimToken` for the Spin & Earn wheel.
- Removing `segmentId` from the claim payload before the backend is ready would break all existing Spin & Earn claims.
- The stub (`SpinWheelApiService.startSpin`) and the `SpinStartResponse` model are already in place; the frontend is ready to switch as soon as the backend route exists.

### What must happen to unblock
1. Backend implements and documents `POST /arcade/spin/start` returning `spinId`, `wheelStopIndex`, `claimToken`, and `expiresAtUtc`.
2. Backend `POST /arcade/spin/claim` updated to accept `spinId` + `claimToken` instead of (or in addition to) `segmentId`.
3. `SpinWheelApiService.startSpin` mock fallback removed; real API call activated.
4. `SpinWheelApiService.claimReward` signature updated: drop `segmentId` parameter, add `claimToken`; update `spinWheelApiServiceProvider` callers.
5. `WheelScreen` updated to call `startSpin()` before animating, and to pass the returned `wheelStopIndex` as the animation target rather than the locally-selected segment index.

---

## Summary Table

| Feature | Blocked by | Estimated complexity |
|---|---|---|
| Advanced particles / shaders | Art assets + Impeller stability | Medium |
| Haptics / audio | Sound assets + UX spec | Small |
| Reward chains | Backend chain endpoint + A/B data | Medium |
| Mission integration | Backend mission claim update + overlay UI | Medium |
| Live events | Backend events API + art per event | Large |
| Seasonal reactors | Asset pipeline + season calendar | Large |
| Arcade Spin migration | `POST /arcade/spin/start` backend route | Small (frontend ready) |
