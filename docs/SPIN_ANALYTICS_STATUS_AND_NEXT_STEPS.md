# Spin Analytics + Identity Reliability: Status & Next Steps

## Overview
This document tracks progress on live Spin & Earn analytics, identity reliability, and supporting robustness fixes.

---

## Completed so far

### 2026-03 follow-up: user-id reliability hardening
- Added prioritized resolver sources for `user_id`:
  1) profile storage,
  2) secure storage,
  3) auth token Hive box,
  4) stable generated local fallback.
- Resolved IDs are backfilled into profile storage to keep app-wide consumers consistent.
- Added focused resolver tests (source priority + fallback behavior) in
  `test/core/services/user_identity_resolver_test.dart`.
- Added canonical ID promotion logic so non-local backend IDs from secure/token
  sources supersede previously generated local IDs and backfill profile storage.
- Added promotion telemetry hook (`identity_user_id_promoted`) when generated
  local IDs are upgraded to canonical backend IDs.

### A) Live Spin analytics pipeline
- Implemented live summary model (`SpinLiveSummary`), websocket adapter, and `spinLiveSummaryProvider` stream pipeline.
- Provider emits local fallback snapshot + websocket updates and dedupes repeated emissions.
- App launcher subscribes to live summary for debug prints + analytics tracking.
- Admin dashboard displays live metadata (name/id/timestamp) in daily metrics.

### B) Backend integration fixes
- Leaderboard requests now include required `limit` query parameter end-to-end.
- Eliminated backend 500 caused by missing `limit` on `/leaderboard`.

### C) Analytics service stability
- Added lazy/memoized box initialization in `AnalyticsService`.
- Reduced startup race warnings and guarded connectivity subscription disposal.

### D) Profile identity improvements
- Added username persistence in `PlayerProfileService`.
- Edit profile flow now normalizes username to lowercase and auto-generates one from display name if empty.
- Active profile updates now sync into legacy settings used by app-wide identity consumers.
- Login/bootstrap paths persist username/userId when available.

---

## Current status of the user ID problem

### What was happening
- Some runtime paths still resolved `user_id` as unknown due to source inconsistency/race (profile settings vs secure storage vs auth token store).

### What has now been implemented
- `UserIdentityResolver` now resolves user id using a prioritized chain:
  1. `PlayerProfileService.getUserId()`
  2. secure storage `user_id`
  3. core auth token Hive box (`auth_tokens.auth_user_id`)
  4. generated **stable local fallback id** persisted in secure storage (`generated_local_user_id`)
- Resolved IDs are backfilled to profile storage for consistency.
- UI auth login service now persists user id/username when available (and avoids saving the `guest` placeholder as canonical id).

### Why local fallback is used
- Yes, creating a local id fallback is a good safety mechanism when backend ID is temporarily unavailable.
- This keeps game analytics and live summaries consistent within the device/session.
- Backend ID remains preferred and automatically supersedes fallback whenever available.

---

## Remaining gaps / risks
1. **Backend profile persistence from edit flow**
   - Current enhanced profile edit still writes locally through `MultiProfileService`; no confirmed backend profile update endpoint is wired in this flow.
2. **Cross-device consistency**
   - Locally generated fallback IDs are device-local by design; true canonical identity still depends on backend user ID.
3. **Automated test coverage**
   - Need focused tests for resolver priority order and fallback promotion when backend id appears.

---

## Next implementation plan

### Phase 1 (now)
- ✅ Complete unified resolver + fallback persistence (done).
- ✅ Ensure edit flow-generated usernames propagate into global identity consumers (done).

### Phase 2 (next)
- ✅ Added backend profile sync hook for display name/username updates:
  - attempts backend profile update against supported endpoint variants,
  - persists backend-confirmed values locally when response includes them,
  - keeps local optimistic values and enqueues retry on sync failure,
  - retries queued profile sync updates during multi-profile initialization.
- Validate promotion telemetry in staging dashboards and define alert thresholds.

### Phase 3
- ✅ Added resolver tests for source priority/backfill, fallback generation/persistence,
  fallback-to-canonical promotion, and source callback coverage.
- ✅ Added profile sync tests for auth header usage, queue-on-failure, and
  queued retry success path.

### Phase 4
<<<<<<< codex/find-spin-analytics-implementation-0sbply
- ✅ Added identity source/fallback/promotion observability events:
  - `identity_user_id_resolved` with normalized `identity_source`
    (`profile|secure|token_store|generated_local`),
  - `identity_user_id_generated_local` to count fallback generations,
  - `identity_user_id_promoted` to count fallback-to-backend promotions.
=======
- Add observability counters/events:
  - `identity_source: profile|secure|token_store|generated_local`,
  - count unknown/fallback generations,
  - count fallback-to-backend promotions.
>>>>>>> main

---

## Definition of done (User ID reliability)
- No runtime path returns `unknown` once any resolvable source exists.
- Generated local IDs are stable (persistent) and only used as last resort.
- Backend user ID, when available, is persisted and preferred everywhere.
- Live spin summary and analytics events consistently include non-empty `user_id`.
