# Spin Analytics + Related Stability Work: Status & Next Steps

## Overview
This document summarizes what has been completed across the recent live Spin & Earn analytics iterations, what is currently stable, what remains at risk, and the concrete implementation plan for next steps.

---

## What has been completed so far

### 1) Live spin analytics data pipeline (first pass)
- Added a live summary domain model: `SpinLiveSummary`.
- Added a websocket adapter: `SpinAnalyticsWebSocketAdapter`.
- Added a unified live provider: `spinLiveSummaryProvider` (`StreamProvider.autoDispose`) that:
  - emits local snapshot fallback,
  - subscribes to websocket updates,
  - handles refresh cycles,
  - dedupes repeated summaries.

### 2) App + UI integration
- `AppLauncher` now listens to `spinLiveSummaryProvider`.
- Added formatted debug summary printing for spin metrics.
- Added analytics tracking for websocket-originated live summary updates.
- Admin dashboard (`SpinAnalyticsDashboard`) renders live metadata (name/id/timestamp) in the daily metrics card.

### 3) Leaderboard error fix
- Fixed `/leaderboard` requests by adding required `limit` query param and propagating it through service call sites.
- This addresses backend 500 caused by missing required query parameter.

### 4) User ID consistency improvements
- Persisted session `userId` into profile storage during login.
- Backfilled profile bootstrap by saving profile `id`/`user_id` during app init.
- Added fallback lookup paths where needed to reduce `user_id = unknown` output.

### 5) Analytics initialization robustness
- Improved analytics storage initialization for offline/session boxes.
- Added lazy/memoized initialization path to reduce race failures.
- Reduced repeated warning noise for uninitialized offline storage.
- Guarded connectivity subscription cancellation to avoid dispose hazards.

---

## Current known-good behavior
- Live spin summary is wired end-to-end (local + websocket).
- Dashboard receives optional live summary metadata.
- Leaderboard refresh no longer omits required `limit`.
- Analytics service is more stable during early startup windows.

---

## Remaining risks / follow-up opportunities

1. **Identity resolution duplication**
   - User ID resolution currently exists in multiple places.
   - Risk: divergence across launch/provider/analytics paths.

2. **Observability for unresolved identity**
   - We still need consistent, centralized diagnostics when user identity cannot be resolved.

3. **Test coverage for live/identity glue code**
   - Add focused tests for identity fallback behavior and summary metadata propagation.

4. **Backend contract hardening**
   - Confirm accepted websocket payload variants (`data` vs `data.summary`) and required ops.

---

## Next implementation plan

### Phase A (immediate)
- Introduce a centralized user identity resolver service in core layer.
- Use it in:
  - `AppLauncher` summary enrichment and lifecycle analytics,
  - `spinLiveSummaryProvider` local snapshot metadata.
- Add single warning path when identity falls back to `unknown`.

### Phase B
- Add targeted tests for:
  - identity fallback chain,
  - live summary metadata enrichment behavior,
  - dedupe semantics.

### Phase C
- Add structured telemetry counters for live summary source mix:
  - websocket updates,
  - local fallback updates,
  - unknown-user summaries.

---

## Definition of done for next step
- One shared user identity resolution implementation is used by both launcher and analytics provider.
- Unknown user ID warnings are throttled and actionable.
- No regression in current live spin summary behavior.
