# Phase 2: REVISED Plan - Daily & Weekly Rewards API

**Date:** June 27, 2026  
**Status:** Revised based on Backend Audit  
**Timeline:** Week 2 (July 1-5, 2026)

---

## Verification Update - 2026-07-03

The tier/progression backend blocker described below is now resolved in `TycoonTycoon_Backend`.

Mapped backend endpoints:

```
GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

Frontend integration has started against those real endpoints. The Phase 2 clients now use the configured API base URL and authenticated HTTP client, and the frontend parses the current backend DTOs for daily, weekly, and tier progression responses.

The older "Tier System API waiting for backend endpoints" notes in this document should be treated as historical context.

---

## 🔄 What Changed

### Original Phase 2 Plan
- Week 1: Questions + Tiers + Bonuses
- Week 2: Missions + Challenges
- Week 3: Categories

### REVISED Phase 2 Plan
- Week 2: Daily Bonuses + Weekly Rewards (use existing backend endpoints!)
- Week 3: Missions + Categories
- Week 4+: Challenges + Tier System (when backend ready)

---

## 🚀 Why This Revised Plan?

### Discovery
✅ Backend already has working endpoints for:
- Daily Bonuses (`/account/rewards/status`, `/account/rewards/claim`)
- Weekly Rewards (`/rewards/weekly-schedule`, `/rewards/weekly/claim`)
- Missions (`/missions` endpoints)
- Questions (already implemented in Phase 1)

❌ Backend MISSING:
- Tier System endpoints (`/progression/tiers`, `/progression/player/{id}`)

### Decision
**Use existing backend endpoints immediately** rather than wait for tier system development.

---

## 📋 Phase 2 - Week 2 (Jul 1-5) Plan

### Daily (Jul 1-2): Daily Bonus API Integration

**Files to Create:**
1. `lib/core/services/daily_bonus_api_client.dart` (120 lines)
   - `getDailyConfig()` → GET /rewards/daily-config
   - `getAccountRewardStatus()` → GET /account/rewards/status
   - `claimDailyReward()` → POST /account/rewards/claim

2. `lib/core/services/reward_cache_service.dart` (80 lines)
   - Cache reward config (TTL: 24 hours)
   - Track claim status locally
   - Sync with backend on startup

**Files to Modify:**
1. `lib/game/providers/reward_providers.dart` (new providers)
   - `dailyBonusProvider` - reactive state
   - `bonusClaimStatusProvider` - claim tracking

2. `lib/screens/rewards/daily_reward_screen.dart` (UI)
   - Show daily reward config
   - Claim button with error handling
   - Next claim countdown timer

**Endpoints Used:**
```
GET  /account/rewards/status
POST /account/rewards/claim
GET  /rewards/daily-config
```

**Response Format:**
```json
{
  "claimedToday": false,
  "nextDailyClaimAt": "2026-06-28T00:00:00Z",
  "currentStreak": 5,
  "rewardType": "coins",
  "coinsAmount": 100
}
```

---

### Daily (Jul 2-3): Weekly Rewards API Integration

**Files to Create:**
1. `lib/core/services/weekly_rewards_api_client.dart` (100 lines)
   - `getWeeklySchedule()` → GET /rewards/weekly-schedule
   - `getWeeklyStreak()` → GET /rewards/weekly-streak/{userId}
   - `claimWeeklyReward()` → POST /rewards/weekly/claim

2. `lib/core/services/weekly_reward_tracker.dart` (60 lines)
   - Track current week day
   - Determine which reward is claimable
   - Handle week reset (Sunday midnight UTC)

**Files to Modify:**
1. `lib/game/providers/reward_providers.dart`
   - `weeklyScheduleProvider`
   - `weeklyStreakProvider`
   - `claimableWeeklyRewardProvider`

2. `lib/screens/rewards/weekly_reward_screen.dart` (new UI)
   - Show 7-day reward calendar
   - Highlight current day
   - Claim button
   - Streak counter

**Endpoints Used:**
```
GET  /rewards/weekly-schedule
GET  /rewards/weekly-streak/{userId:guid}
POST /rewards/weekly/claim
```

**Response Format:**
```json
{
  "day": 3,
  "type": "coins",
  "coinsAmount": 200,
  "gems": 0,
  "displayName": "Day 3 — 200 Credits",
  "claimed": false
}
```

---

### Afternoon (Jul 3): Questions API Integration Completion

**Files to Modify:**
1. `lib/game/services/question_loader_service.dart`
   - Implement `preloadTopCategories()` with real endpoint calls
   - Add actual category fetching from `/questions/categories`

2. `lib/screens/category_selection_screen.dart`
   - Trigger question preload on category tap
   - Show loading state during fetch
   - Cache validation

**No new files needed** - Phase 1 already has the infrastructure

---

### Morning (Jul 4): Testing & Integration

**Unit Tests:**
- DailyBonusApiClient
  - ✅ getDailyConfig()
  - ✅ getAccountRewardStatus()
  - ✅ claimDailyReward() success
  - ✅ claimDailyReward() already claimed
  - ✅ Error handling

- WeeklyRewardsApiClient
  - ✅ getWeeklySchedule()
  - ✅ getWeeklyStreak()
  - ✅ claimWeeklyReward() success
  - ✅ Week reset detection
  - ✅ Error handling

- RewardCacheService
  - ✅ Cache hit/miss
  - ✅ TTL validation
  - ✅ Cache invalidation

**Integration Tests:**
- Questions → Rewards flow
- Daily reward claim → UI update
- Weekly reward navigation
- Offline functionality

---

### Afternoon (Jul 4): Manual Testing

**Test Scenarios:**
1. **Daily Reward**
   - [ ] Load daily config (should show 100 coins)
   - [ ] Claim reward (should succeed, lock for 24h)
   - [ ] Attempt second claim (should fail, show message)
   - [ ] Wait 24h simulation (should allow claim)
   - [ ] Offline mode (should use cached config)

2. **Weekly Reward**
   - [ ] View weekly schedule (7 days visible)
   - [ ] Current day highlighted
   - [ ] Claim current day reward (should succeed)
   - [ ] Cannot claim future days
   - [ ] Week reset Sunday night

3. **Questions + Rewards**
   - [ ] Select category → loads questions via API
   - [ ] Category caches properly (2nd load instant)
   - [ ] Play quiz → earn coins/gems
   - [ ] Rewards show correctly

---

### Evening (Jul 4): Documentation & Cleanup

**Create:**
- `docs/DAILY_BONUS_IMPLEMENTATION.md` (how daily bonus works)
- `docs/WEEKLY_REWARDS_IMPLEMENTATION.md` (how weekly rewards work)
- `docs/PHASE_2_SUMMARY.md` (what was accomplished)

**Update:**
- `CORE_CONTENT_PRIORITY_PLAN.md` (phase 2 completion)
- `PROGRESS_SUMMARY.md` (current status)

---

## 🎯 Phase 2 Deliverables

### Code
- ✅ DailyBonusApiClient
- ✅ WeeklyRewardsApiClient
- ✅ RewardCacheService
- ✅ UI screens (daily + weekly)
- ✅ Providers + state management
- ✅ Complete error handling
- ✅ Unit & integration tests

### Documentation
- ✅ Implementation guides
- ✅ API contract documentation
- ✅ User flow diagrams
- ✅ Testing checklist

---

## 🔄 Remaining Phase 2 Items

**Moved to Phase 3:**
- ⏳ Missions API (still on schedule, just Week 3)
- ⏳ Categories API (still on schedule, just Week 3)

**Moved to Phase 4:**
- ⏳ Challenges API (now Week 4, was Week 2)

**Moved to Phase 5 (PENDING BACKEND):**
- ⏳ Tier System API (waiting for backend endpoints)

---

## 📊 Success Metrics

### Phase 2 Completion Criteria
- ✅ Daily bonus fetches from API
- ✅ Weekly rewards display correctly
- ✅ Claims work (cannot claim twice)
- ✅ UI updates after claim
- ✅ Offline fallback works
- ✅ Tests pass (>90% coverage)
- ✅ No console errors
- ✅ Performance good (<500ms)

---

## 🚨 Blocking Issue: Tier System

### Current State
- Backend: Tier endpoints **DO NOT EXIST**
- Frontend: Cannot implement without backend

### Options

**Option 1: Mock Tier System (RECOMMENDED)**
- Use Phase 1 hardcoded tier definitions
- Continue frontend development
- Integrate real backend when ready
- Estimated time: 1 hour frontend work
- **Advantage:** Unblocked, full feature development

**Option 2: Wait for Backend**
- Skip tier work until endpoints exist
- Focus on other features (missions, challenges)
- **Advantage:** Real data from day 1
- **Disadvantage:** Phase 2 reduced scope

**Option 3: Parallel Development**
- Frontend: Build tier system with mocks
- Backend: Create tier endpoints
- Risk: API contract mismatch
- **Advantage:** Can ship Phase 2 with mock, upgrade later

### Recommendation
**Use Option 1 (Mock Tier System)**
- Implement TierApiClient using Phase 1 tier definitions
- Mark as "mock" in code comments
- Can swap real API later with no UI changes
- Keeps Phase 2 scope full
- Unblocks downstream work (Challenges, etc)

---

## 📅 Timeline

```
MON (Jul 1)  ✅ Daily Bonus API
TUE (Jul 2)  ✅ Weekly Rewards API + Testing
WED (Jul 3)  ✅ Questions Integration
THU (Jul 4)  ✅ Full Testing & Documentation
FRI (Jul 5)  ✅ Buffer for bugs/refinements
```

---

## 🔗 Related Documents

- `BACKEND_API_AUDIT.md` - Backend endpoint verification
- `QUESTIONS_API_IMPLEMENTATION.md` - Phase 1 reference
- `CORE_CONTENT_PRIORITY_PLAN.md` - Original plan
- `PHASE_2_REVISED_PLAN.md` - This document

---

## ✅ Action Items

### TODAY (Jun 27)
- [ ] Review BACKEND_API_AUDIT.md
- [ ] Decide on tier system approach (mock vs wait)
- [ ] Create DailyBonusApiClient skeleton
- [ ] Create WeeklyRewardsApiClient skeleton

### TOMORROW (Jun 28)
- [ ] Implement DailyBonusApiClient
- [ ] Implement WeeklyRewardsApiClient
- [ ] Create providers
- [ ] Start UI implementation

---

**Status:** Plan Ready  
**Approval:** PENDING - Need tier system decision  
**Next Session:** Begin Phase 2 implementation

---

*Phase 2 Revised: June 27, 2026*  
*Based on: Backend API Audit findings*
