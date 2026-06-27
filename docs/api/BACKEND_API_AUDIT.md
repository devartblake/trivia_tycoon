# Backend API Audit - Available Endpoints

**Date:** June 27, 2026  
**Status:** Complete API Inventory  
**Purpose:** Verify which endpoints exist and plan Phase 2 implementation

---

## 📊 Summary

| Feature | Status | Endpoints | Notes |
|---------|--------|-----------|-------|
| Questions ✅ | Ready | 6 | Can fetch questions |
| Rewards ✅ | Ready | 6 | Daily + Weekly + Spin rewards |
| Missions ✅ | Ready | 3 | Daily/Weekly/Season support |
| Account ✅ | Ready | 2 | Account-level rewards |
| Tiers ❌ | Missing | 0 | **Need to create** |
| Progression ❌ | Missing | 0 | **Need to create** |
| Categories ⚠️ | Partial | Via Questions | Included in questions/categories |

---

## ✅ VERIFIED: Questions Endpoints

**Location:** `Synaptix.Backend.Api/Features/Questions/QuestionsEndpoints.cs`

### Available Endpoints

```
GET  /questions/set
     ?category={category}
     &difficulty={difficulty}
     &count={count}
     &playerId={playerId}
     &mode={mode}
```

**Parameters:**
- `category` (optional) - Category name
- `difficulty` (optional) - Easy, Medium, Hard, Expert
- `count` (required) - Number of questions
- `playerId` (optional) - For adaptive difficulty
- `mode` (optional) - ranked, practice, etc
- `gradeBand`, `ageGroup`, `audience`, `subject`, `topic`, `dataset`, `tags`

**Response:**
- Array of QuestionModel (without correct answers - separate /check endpoint)
- Supports adaptive personalization based on player profile

---

```
POST /questions/mixed
```

**Purpose:** Mixed difficulty questions

---

```
GET  /questions/categories
```

**Returns:** List of available categories

---

```
GET  /questions/metadata
```

**Returns:** Question metadata and statistics

---

```
POST /questions/preview-set
POST /questions/check
POST /questions/check-batch
```

**Purpose:** Answer validation (server-side grading)

---

## ✅ VERIFIED: Rewards Endpoints

**Location:** `Synaptix.Backend.Api/Features/Rewards/RewardsEndpoints.cs`

### Daily Rewards

```
GET  /rewards/daily-config
```

**Returns:**
```json
{
  "rewardType": "coins",
  "coinsAmount": 100,
  "displayName": "Daily Mystery Box",
  "iconName": "daily_box"
}
```

---

```
POST /rewards/daily/claim
```

**Purpose:** Claim daily reward  
**Auth:** Required

---

### Weekly Rewards

```
GET  /rewards/weekly-schedule
```

**Returns:** 7-day reward schedule
```json
[
  { "day": 1, "type": "coins", "coinsAmount": 100, "gems": 0 },
  { "day": 2, "type": "gems", "coinsAmount": 0, "gems": 5 },
  ...
]
```

---

```
GET  /rewards/weekly-streak/{userId:guid}
```

**Purpose:** Get player's current week streak  
**Auth:** Required

---

```
POST /rewards/weekly/claim
```

**Purpose:** Claim weekly reward  
**Auth:** Required

---

### Spin Rewards

```
GET  /rewards/spin-reward-steps
```

**Returns:** Reward progression for spin wheel
```json
[
  { "type": "coins", "amount": 50, "displayName": "50 Credits" },
  { "type": "coins", "amount": 100, "displayName": "100 Credits" },
  ...
]
```

---

## ✅ VERIFIED: Account Rewards Endpoints

**Location:** `Synaptix.Backend.Api/Features/Account/AccountRewardsEndpoints.cs`

```
GET  /account/rewards/status
```

**Auth:** Required  
**Returns:**
- Daily claim status
- Weekly streak info
- Next claim time

---

```
POST /account/rewards/claim
```

**Auth:** Required  
**Purpose:** Claim daily reward for account

---

## ✅ VERIFIED: Missions Endpoints

**Location:** `Synaptix.Backend.Api/Features/Missions/MissionsEndpoints.cs`

```
GET  /missions/
     ?type={type}
```

**Parameters:**
- `type` (optional) - "daily", "weekly", "season"

**Returns:** List of active missions for player

---

```
POST /missions/progress/match-completed
```

**Body:** MatchCompletedProgressDto  
**Purpose:** Update mission progress after match

---

```
POST /missions/progress/round-completed
```

**Body:** RoundCompletedProgressDto  
**Purpose:** Update mission progress after round

---

```
POST /missions/{missionId:guid}/claim
     ?playerId={playerId}
     &type={type}
```

**Purpose:** Claim mission reward  
**Returns:** Updated mission list

---

## ❌ MISSING: Tier/Progression Endpoints

**Status:** NOT FOUND in backend

### What We Need to Create

```
GET  /progression/tiers
```

**Should Return:**
```json
[
  {
    "id": "bronze-rookie",
    "name": "Bronze Rookie",
    "level": 1,
    "minXp": 0,
    "maxXp": 500,
    "rewards": {
      "badge": "welcome_badge",
      "coins": 100
    }
  },
  {
    "id": "silver-scholar",
    "name": "Silver Scholar",
    "level": 5,
    "minXp": 500,
    "maxXp": 1200,
    "rewards": {
      "badge": "scholar_badge",
      "coins": 250,
      "gems": 5
    }
  },
  ...
]
```

---

```
GET  /progression/player/{playerId:guid}
```

**Returns:** Player's current tier/XP/level

---

```
POST /progression/xp/award
```

**Purpose:** Award XP to player (called after match completion)

---

## ⚠️ PARTIAL: Categories

**Location:** Via `/questions/categories`

### Issue

Categories are retrieved as part of questions endpoint, but no dedicated category management endpoint.

### Recommendation

- Can use existing `/questions/categories` for frontend dropdown
- If we need category metadata (icons, colors), need new endpoint:
  ```
  GET  /categories/all
  ```

---

## 🏗️ Missing Infrastructure

### NOT FOUND in Backend

1. **Tier Definition Table**
   - No `Tiers` or `Progression` entity found
   - Need: Entity to define tier progression
   - Need: Database migration to create tier data

2. **Tier Completion Tracking**
   - Need: Entity to track player tier progression
   - Need: Endpoint to return player's current tier

3. **Tier Rewards**
   - Need: Reward calculation when tier up occurs
   - Need: Endpoint to claim tier-up rewards

---

## 🔄 Phase 2 Implementation Plan - REVISED

### What EXISTS ✅
- Questions API → Can use directly
- Rewards API → Can use directly
- Missions API → Can use directly
- Account rewards → Can use directly

### What NEEDS CREATION ❌
1. **Tier/Progression Endpoints** (NEW WORK)
   - GET /progression/tiers (get tier definitions)
   - GET /progression/player/{id} (get player tier)
   - POST /progression/xp/award (award XP to player)

2. **Backend Entities & Database**
   - Tier definition table
   - Player progression tracking table
   - Migration script

3. **Tier Manager Service**
   - Calculate tier from XP
   - Award tier-up rewards
   - Handle tier-down scenarios

---

## 💡 Critical Discovery

### Good News ✅
- Questions API is **fully functional and flexible**
- Rewards system is **production-ready**
- Missions endpoint is **complete**
- No need to build those from scratch!

### Challenge ⚠️
- **Tier/Progression system doesn't exist**
- Cannot use existing backend endpoints
- **Must create from scratch:**
  1. Backend entities
  2. Database schema
  3. API endpoints
  4. Business logic

---

## 📋 What This Means for Phase 2

### Original Plan (6 hours for Tier System)
```
Create TierApiClient → NOT APPLICABLE
Update TierManager → Can do this part
Implement tier caching → Can do this part
Test tier progression → Need backend endpoints first
```

### REVISED Plan (Need Backend Work)

**BLOCKER:** Cannot implement frontend TierApiClient until backend has:
- ✅ Tier definitions (stored in DB)
- ✅ Player progression tracking
- ✅ API endpoints

**OPTIONS:**

**Option A: Wait for Backend Team**
- Backend: Create tier system (2-3 days)
- Frontend: Implement API client once ready

**Option B: Create Mock API for Frontend**
- Frontend: Build TierApiClient with hardcoded tier definitions
- Later: Connect to real backend when ready
- Timeline: ~2 hours frontend work

**Option C: Parallel Development**
- Frontend: Build TierApiClient using Phase 1 patterns
- Backend: Create tier endpoints simultaneously
- Risk: API contract mismatch

---

## ✅ Recommended Next Steps

### TODAY (June 27)
1. Check TycoonTycoon_Backend CLAUDE.md for tier roadmap
2. Determine if tier system is planned
3. Ask backend team: **"When will tier system API be ready?"**

### If Backend Not Ready
1. Continue with other Phase 2 items:
   - Daily Bonus API (use /rewards endpoints)
   - Weekly Rewards API (use /rewards endpoints)
   - Question Preload integration
   - Category selection integration

2. **Skip Tier System** until backend is ready
   - Reorder Phase 2: Do bonuses/rewards first
   - Tier system becomes Week 3 instead of Week 2

### If Backend Ready
1. Document tier API contract
2. Build TierApiClient
3. Implement in frontend

---

## 📚 Backend Files to Review

```
Synaptix.Backend.Api/Features/
├─ Questions/QuestionsEndpoints.cs ✅
├─ Rewards/RewardsEndpoints.cs ✅
├─ Account/AccountRewardsEndpoints.cs ✅
├─ Missions/MissionsEndpoints.cs ✅
└─ (Tiers/) ❌ MISSING
```

---

## 🎯 Decision Point

**Question for Backend Team:**
> Are tier/progression endpoints planned for Phase 2? If not, what's the timeline?

**Pending:** Clarification on tier system roadmap

---

## 📝 Summary for Frontend

**We can proceed with:**
- ✅ Daily Bonus API (use /account/rewards/status & /account/rewards/claim)
- ✅ Weekly Rewards API (use /rewards/weekly-schedule & /rewards/weekly/claim)
- ✅ Questions integration (already done in Phase 1)
- ✅ Missions API (use /missions endpoints)

**We're BLOCKED on:**
- ❌ Tier System (backend endpoints don't exist yet)

**Workaround:**
- Create mock tier definitions for Phase 2
- Connect to real backend in Phase 3 once endpoints exist

---

**Status:** Audit Complete  
**Action Required:** Clarify tier system timeline with backend team

---

*Document generated: June 27, 2026*  
*Backend reviewed: Synaptix.Backend.Api commit latest*
