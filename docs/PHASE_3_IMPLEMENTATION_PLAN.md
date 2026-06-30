# Phase 3 Implementation Plan - Execution Guide

**Status:** Implementation Starting  
**Total Estimated Effort:** 23-35 hours  
**Last Updated:** 2026-06-29

---

## Implementation Roadmap

### PHASE 1: Critical Fixes (9-14 hours)

#### FIX 1: XP Data Sync (2-3 hours)
**Problem:** Two separate XP systems not synchronized
- `QuestionResultService` → `XPService.addXP()` (in-memory)
- `PlayerProfileService` reads from Hive: `profile['currentXP']`

**Solution:** Ensure both are updated together

**Implementation:**
1. Create `XPProgressionService` that bridges both systems
2. Update `ProfileDataUpdater.updateAfterQuiz()` to call `saveLevelData()`
3. Add logging to verify sync

**Files to Modify:**
- `lib/game/logic/quiz_completion_handler.dart` - Add level save call
- `lib/game/services/profile_service.dart` - Add sync method
- `lib/core/services/settings/player_profile_service.dart` - Verify saveLevelData works

#### FIX 2: Level Tracking (1-2 hours)
**Problem:** Level not incremented alongside XP

**Solution:** Calculate and update level based on XP thresholds

**Implementation:**
1. Define XP→Level mapping
2. Calculate level from total XP
3. Update Hive when XP is awarded

**Files to Modify:**
- `lib/core/services/settings/player_profile_service.dart` - Add calculateLevelFromXP()
- `lib/game/logic/quiz_completion_handler.dart` - Calculate and save new level

#### FIX 3: Tier System Unification (4-6 hours)
**Problem:** Two incompatible tier systems

**Solution:** Create unified `TierProgressionService` that uses TierApiClient as source of truth

**Implementation:**
1. Create `TierProgressionService` (new file)
2. Use TierApiClient to fetch tier definitions
3. Integrate with TierManager for local caching
4. Update quiz flow to use unified service

**Files to Modify/Create:**
- `lib/game/services/tier_progression_service.dart` (NEW)
- `lib/game/providers/tier_progression_provider.dart` (NEW - Riverpod)
- `lib/core/manager/tier_manager.dart` - Refactor to use TierApiClient data
- `lib/game/logic/quiz_completion_handler.dart` - Use new unified service

#### FIX 4: End-to-End Testing (2-3 hours)
**Implementation:**
1. Manual integration test script
2. Widget tests for tier progression
3. Verification logging

**Files to Create:**
- `test/integration/tier_progression_integration_test.dart` (NEW)
- `test/game/services/tier_progression_service_test.dart` (NEW)

---

### PHASE 2: Optional But Recommended (14-21 hours)

#### ENHANCEMENT 1: Implement Tier Rewards Logic (3-4 hours)
**File:** `lib/core/manager/tier_manager.dart` (line 249)

**Implementation:**
1. Award coins/gems to player
2. Unlock badge in player's collection
3. Add notification

#### ENHANCEMENT 2: Skill Tree Integration (4-6 hours)
**Implementation:**
1. Connect tier progression to skill unlocks
2. Update skill availability based on tier
3. Add UI indication

**Files:**
- Create hook in `TierProgressionService`
- Update skill tree providers

#### ENHANCEMENT 3: Leaderboard Score Verification (2-3 hours)
**Implementation:**
1. Verify tier affects score correctly
2. Test multipliers apply properly
3. Audit calculation

#### ENHANCEMENT 4: Comprehensive Testing (5-8 hours)
**Implementation:**
1. Unit tests for all services
2. Integration tests
3. Widget tests
4. Edge case coverage

---

## Implementation Checklist

### Phase 1 Fixes
- [ ] FIX 1: XP Sync - Create unified XP update path
- [ ] FIX 2: Level Tracking - Add level calculation logic
- [ ] FIX 3: Tier System - Create unified tier service
- [ ] FIX 4: Testing - Verify end-to-end flow

### Phase 2 Enhancements
- [ ] ENHANCEMENT 1: Implement reward logic
- [ ] ENHANCEMENT 2: Skill tree hooks
- [ ] ENHANCEMENT 3: Leaderboard verification
- [ ] ENHANCEMENT 4: Comprehensive tests

---

## Starting Implementation Now

Proceeding with Phase 1 fixes in this order:
1. FIX 2: Level Tracking (simplest, unblocks others)
2. FIX 1: XP Sync (depends on FIX 2 foundation)
3. FIX 3: Tier System (uses FIX 1 & 2 results)
4. FIX 4: Testing (validates all fixes)

Then proceed to Phase 2 enhancements.

