# CRITICAL DECISION: Tier System Backend Status

**Date:** June 27, 2026  
**Priority:** HIGH - Blocks Phase 2 Planning  
**Action Required:** TODAY

---

## Verification Update - 2026-07-03

This decision record is now historical. The backend tier/progression blocker has been resolved in `TycoonTycoon_Backend`.

Current mapped endpoints:

```
GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

Frontend Phase 2 integration has started against the real endpoints. The mock fallback remains useful for offline/error handling, but the backend is no longer missing the progression API.

---

## 🔍 What We Discovered

### Audit Results
After reviewing TycoonTycoon_Backend API:

**Questions Endpoint** ✅
- Location: `/Features/Questions/QuestionsEndpoints.cs`
- Status: FULLY IMPLEMENTED
- Ready to use: YES

**Rewards Endpoints** ✅
- Location: `/Features/Rewards/RewardsEndpoints.cs` + `/Account/AccountRewardsEndpoints.cs`
- Status: FULLY IMPLEMENTED
- Ready to use: YES

**Missions Endpoints** ✅
- Location: `/Features/Missions/MissionsEndpoints.cs`
- Status: FULLY IMPLEMENTED
- Ready to use: YES

**Tier System** ❌
- Location: `/Features/[MISSING]/TiersEndpoints.cs`
- Status: **DOES NOT EXIST**
- Ready to use: NO
- Impact: Phase 2 Cannot Proceed As Planned

---

## ⚠️ The Problem

### What We Need
For Phase 2, we planned to implement:
```
TierApiClient (to fetch tier definitions from backend)
└─ GET /progression/tiers
└─ GET /progression/player/{userId}
└─ POST /progression/xp/award
```

### What Backend Has
```
(nothing - tier system doesn't exist)
```

### The Gap
Cannot build frontend API client without backend endpoints.

---

## 🤔 Three Options

### OPTION A: Mock Tier System (RECOMMENDED)

**What:** Build tier system using Phase 1 hardcoded definitions

**Frontend Work:**
1. Create `TierApiClient` (100 lines)
   - Returns hardcoded tier definitions
   - Marked as "MOCK" in comments
2. Wire into TierManager
3. Display tiers in UI
4. Total time: ~2 hours

**Backend Work:**
- None needed immediately
- Can build endpoints in parallel
- Frontend ready to swap real API later

**Advantages:**
- ✅ Phase 2 has full scope
- ✅ Unblocks other features
- ✅ Easy to swap real API later
- ✅ Can ship with mock, upgrade anytime

**Disadvantages:**
- ⚠️ Not real data
- ⚠️ Duplicate work if backend changes format

**Recommendation:** YES - DO THIS

---

### OPTION B: Wait for Backend

**What:** Skip tier system until backend ready

**Frontend Work:**
- None - wait for backend endpoints

**Backend Work:**
- Create tier system (2-3 days estimated)
- Deploy endpoints
- Then frontend can build API client

**Advantages:**
- ✅ Real data from day 1
- ✅ No duplicate work

**Disadvantages:**
- ❌ Phase 2 scope reduced
- ❌ Blocks downstream work (challenges, etc)
- ❌ Timeline slips
- ❌ Cannot ship tier feature on schedule

**Recommendation:** NO - Not recommended

---

### OPTION C: Parallel Development

**What:** Frontend builds with mocks, backend builds real endpoints simultaneously

**Frontend Work:**
- Build TierApiClient with mocks (2 hours)
- Full implementation
- Swap real API endpoint later

**Backend Work:**
- Create tier endpoints simultaneously
- No blocking/waiting

**Advantages:**
- ✅ Full scope in Phase 2
- ✅ Real endpoints faster
- ✅ Parallel work

**Disadvantages:**
- ⚠️ Risk of API contract mismatch
- ⚠️ Rework if backend format differs
- ⚠️ Requires coordination

**Recommendation:** MAYBE - Good if backend is working on this

---

## 🎯 RECOMMENDATION: Option A (Mock Tier System)

### Why Mock?

1. **Unblocks Development**
   - Phase 2 stays on schedule
   - No waiting for backend
   - Other features can proceed

2. **Low Risk**
   - Mock client is 2 hours work
   - Easy to replace with real API later
   - Same interface either way

3. **Validates Architecture**
   - Proves tier system design works
   - Tests UI/state management
   - Backend can use as reference

4. **Flexible Timeline**
   - Backend can work independently
   - When ready, swap API endpoint
   - No coordination needed

### Implementation Plan

```
TODAY (Jun 27)
├─ Decision: Approve mock tier system
└─ Start: Create TierApiClient with mocks

WEEK 2 (Jul 1-5): Phase 2 Daily Bonuses + Weekly Rewards + Mock Tiers
├─ Daily Bonus API (real, from /account/rewards)
├─ Weekly Rewards API (real, from /rewards)
├─ Mock Tier System (frontend only, from Phase 1 definitions)
└─ Questions API (already done, from /questions)

WEEK 4+: Tier System Backend Ready
├─ Backend: Completes tier endpoints
├─ Frontend: Swap mock API → real API (1 hour change)
└─ Release: Real tier system goes live
```

---

## 🚀 Quick Win: What We CAN Do Now

While deciding on tiers, we can build these with **actual working backend endpoints**:

**Week 2 (Jul 1-5):**
- ✅ Daily Bonus API (use `/account/rewards/status`, `/account/rewards/claim`)
- ✅ Weekly Rewards API (use `/rewards/weekly-schedule`, `/rewards/weekly/claim`)
- ✅ Questions Integration (already have Phase 1)
- ✅ Mock Tier System (2 hour frontend work)

**All real, all working, all on schedule.**

---

## 🔗 What Depends on This Decision

### If We Mock Tiers (Option A):
- ✅ Phase 2 fully complete (Jul 1-5)
- ✅ Phase 3 Missions ready (Jul 6-12)
- ✅ Phase 4 Challenges ready (Jul 13-19)
- ✅ Phase 5 Tier swap (whenever backend ready)

### If We Wait for Tiers (Option B):
- ⚠️ Phase 2 scope: Only bonuses + questions
- ⚠️ Phase 3 scope: Missions + Tiers
- ⚠️ Timeline slips 1 week
- ⚠️ Challenges pushed to Phase 5

---

## 📋 Decision Questions

**For Backend Team:**
1. When will tier system endpoints be ready?
   - [ ] Week 2 (Jul 1-5)
   - [ ] Week 3 (Jul 6-12)
   - [ ] Week 4+ (Jul 13+)
   - [ ] Unknown

2. Are you building tier system now?
   - [ ] Yes, on schedule
   - [ ] Planned but not started
   - [ ] Not planned yet
   - [ ] Unsure

3. Can frontend use mock tiers while you build real ones?
   - [ ] Yes, perfect - go ahead
   - [ ] Maybe - show us the design first
   - [ ] No - wait for real endpoints

---

## ⏰ Decision Deadline

**Need Answer By:** June 27, 2026 (TODAY)

**If No Response:** Proceeding with Option A (Mock Tier System)
- Frontend cannot wait indefinitely
- Will build with mocks
- Can swap real API later

---

## 📝 Next Steps

### If Approving Mock Tiers:

1. **TODAY**
   - Create `lib/core/services/tier_api_client.dart` (mock)
   - Use Phase 1 tier definitions
   - Mark as "MOCK - replace with real API"

2. **TOMORROW (Jul 1)**
   - Start Phase 2 implementation
   - Daily Bonuses (real API)
   - Weekly Rewards (real API)
   - Mock Tiers (frontend only)

3. **When Backend Ready**
   - Replace mock endpoint with real one
   - No other changes needed
   - Swap: 1 hour max

### If Choosing Wait-for-Backend:

1. **TODAY**
   - Confirm timeline with backend
   - Update Phase 2 plan
   - Adjust schedule

2. **WEEK 2**
   - Build Daily Bonuses + Weekly Rewards only
   - Skip tier system

3. **WHEN READY**
   - Implement tier system with real backend

---

## 🔐 Commitment

By implementing mock tier system:
- We're NOT committing to permanent mock data
- We CAN swap real API anytime
- No rework needed for real endpoints
- Flexible and professional approach

---

## ✅ Approval Checklist

- [ ] Backend team confirmed tier system status
- [ ] Team agrees with mock approach (Option A)
- [ ] Timeline confirmed for real endpoints
- [ ] Phase 2 scope approved (bonuses + rewards + mock tiers)

---

**Status:** AWAITING DECISION  
**Impact:** Blocks Phase 2 Detailed Planning  
**Risk Level:** HIGH if unaddressed  

**Recommendation:** Proceed with Option A (Mock Tiers)  
**Authorization Needed:** Backend team + Project lead

---

*Created: June 27, 2026*  
*Decisions Made: Backend API Audit findings*  
*Action: Review with team TODAY*
