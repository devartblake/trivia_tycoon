# Match REST API Integration — End-to-End Test Plan

**Date**: 2026-07-05  
**Feature**: Turn-based Multiplayer Match REST API Integration  
**Status**: Ready for Testing

---

## Overview

This test plan covers the integration of the REST-based Match API with the Flutter client. The implementation enables:
- Creating new matches (singleplayer or vs opponent)
- Submitting match results and claiming rewards
- Displaying match history with auto-refresh
- Error handling and retry capability

---

## Test Environment Setup

### Prerequisites
- Flutter development environment running
- Backend API accessible at configured base URL
- Test user account with credentials
- Network connectivity to backend

### Backend Endpoints Required (All REST)
```
POST   /matches/start          — Create new match
POST   /matches/submit         — Submit results
GET    /matches/{matchId}      — Get match details
GET    /matches                — List matches (with pagination)
POST   /matches/{matchId}/abandon — End ongoing match
```

---

## Test Cases

### 1. Start Match (Basic Flow)

**Test**: `TC-MATCH-001: Start Singleplayer Match`

**Steps**:
1. Open Challenges → History tab
2. Tap "Refresh" button (if no matches exist)
3. Navigate to create a match (implementation varies)
4. Start a singleplayer match
5. Verify response: Match created with unique matchId

**Expected Result**:
- ✅ Match appears in active matches list
- ✅ Match status is 'ongoing'
- ✅ Player can proceed with match

**Verify**:
- Logs show: "Loading active matches from API"
- MatchStartResponse contains valid matchId and claimToken

---

**Test**: `TC-MATCH-002: Start Multiplayer Match (vs Opponent)`

**Steps**:
1. Start match with opponentId = "test-opponent-123"
2. Verify backend creates match with opponent reference
3. Check active matches list

**Expected Result**:
- ✅ Match created with both playerId and opponentId
- ✅ opponentName displays correctly in history
- ✅ Match status shows as 'ongoing'

**Verify**:
- Match appears in list with opponent name
- Match details include opponentId and opponentName

---

### 2. Submit Match Results

**Test**: `TC-MATCH-003: Submit Match Result (Victory)`

**Steps**:
1. After playing a match, submit result with:
   - matchId: from startMatch response
   - playerScore: 10 (example)
   - opponentScore: 3 (example)
   - answeredQuestionIds: ["q1", "q2", "q3", ...]
2. Verify server processes submission
3. Check match status changes to 'completed'
4. Verify wallet receives reward coins

**Expected Result**:
- ✅ MatchSubmitResponse returned with:
  - result: "won"
  - status: "completed"
  - rewardCoins: > 0
- ✅ Match moves from active → history
- ✅ Wallet balance increases by rewardCoins

**Verify**:
- Player score and opponent score recorded correctly
- Result correctly shows "won"
- Rewards applied to user balance

---

**Test**: `TC-MATCH-004: Submit Match Result (Loss)`

**Steps**:
1. Submit match with playerScore < opponentScore
2. Submit with answeredQuestionIds
3. Verify result shows "lost"

**Expected Result**:
- ✅ result: "lost"
- ✅ status: "completed"
- ✅ rewardCoins: 0 or penalty applied

**Verify**:
- Correct result displayed
- No reward coins awarded (or penalty applied)

---

**Test**: `TC-MATCH-005: Submit Match Result (Tie)**

**Steps**:
1. Submit with playerScore == opponentScore
2. Verify result shows "tied"

**Expected Result**:
- ✅ result: "tied"
- ✅ Appropriate reward handling for ties

---

### 3. Match History Display

**Test**: `TC-MATCH-006: Match History Renders Correctly`

**Steps**:
1. Navigate to Challenges → History tab
2. Verify matches load and display:
   - Opponent name
   - Player score vs opponent score
   - Result badge (Won/Lost/Tied)
   - Timestamp
   - Game mode

**Expected Result**:
- ✅ All matches render with correct data
- ✅ Result badges show correct colors:
   - Green for "Won"
   - Red for "Lost"
   - Orange for "Tied"
- ✅ Timestamps display in relative format ("2h ago")

**Verify**:
- No crashes or layout issues
- Text not truncated
- Card layout responsive

---

**Test**: `TC-MATCH-007: Pull-to-Refresh`

**Steps**:
1. On History tab, pull down to refresh
2. Observe loading indicator
3. Verify new matches appear if available

**Expected Result**:
- ✅ Refresh indicator shows during load
- ✅ Matches list updates with fresh data
- ✅ ActiveMatchesNotifier.refresh triggers

**Verify**:
- Logs show: "Loading active matches from API"
- New matches appear without navigation

---

**Test**: `TC-MATCH-008: Empty State**

**Steps**:
1. On fresh account with no matches
2. Navigate to History tab
3. Verify empty state UI

**Expected Result**:
- ✅ Shows icon + message: "No matches yet"
- ✅ Shows refresh button
- ✅ Tapping refresh works

**Verify**:
- Empty state message is clear
- Refresh button is functional

---

### 4. Periodic Auto-Refresh

**Test**: `TC-MATCH-009: Periodic Refresh (30s)`

**Steps**:
1. Open History tab
2. Leave app idle for 35+ seconds
3. Observe match list without user action

**Expected Result**:
- ✅ Matches refresh automatically every 30s
- ✅ New matches appear without manual refresh
- ✅ No UI freezing during refresh

**Verify**:
- Logs show periodic calls: "Loading active matches from API"
- Timestamp updates on matches (minute-level)
- No excessive API calls (only every 30s)

---

**Test**: `TC-MATCH-010: Relative Timestamp Updates`

**Steps**:
1. Submit a match and view in history
2. Timestamp shows "just now"
3. Wait 5 minutes
4. Return to app (triggers UI rebuild)
5. Verify timestamp updated to "5m ago"

**Expected Result**:
- ✅ Timestamps recalculate and update
- ✅ Format changes correctly (just now → Xm ago → Xh ago)

---

### 5. Error Handling

**Test**: `TC-MATCH-011: API Error — Connection Failure`

**Steps**:
1. Disable network
2. Navigate to History tab
3. Try to refresh
4. Re-enable network
5. Tap refresh

**Expected Result**:
- ✅ Empty state shown (no crash)
- ✅ Refresh button available
- ✅ After network returns, refresh succeeds
- ✅ Logs show warning: "Failed to load active matches"

**Verify**:
- Graceful error handling
- No unhandled exceptions
- Recovery works when network restored

---

**Test**: `TC-MATCH-012: API Error — 5xx Server Error`

**Steps**:
1. Backend returns 500 error for /matches endpoint
2. Navigate to History tab
3. Observe behavior

**Expected Result**:
- ✅ Empty state shown
- ✅ User can still refresh
- ✅ Logs show warning with error details
- ✅ No app crash

---

**Test**: `TC-MATCH-013: Invalid Match Data**

**Steps**:
1. Backend returns match with missing opponentName
2. Navigate to History tab
3. Verify card renders

**Expected Result**:
- ✅ opponentName defaults to "Unknown"
- ✅ Card renders without crashing
- ✅ All other data displays correctly

---

### 6. Match Details

**Test**: `TC-MATCH-014: View Match Details`

**Steps**:
1. Tap on a match in history
2. Verify getMatchDetails() called
3. Shows match info: scores, opponent, reward coins, completion time

**Expected Result**:
- ✅ Detailed match view loads
- ✅ All fields populated correctly
- ✅ Includes rewardCoins if applicable

**Note**: Requires UI for detail view (not yet implemented)

---

### 7. State Management

**Test**: `TC-MATCH-015: Provider State Consistency`

**Steps**:
1. Start multiple matches in quick succession
2. Submit results for some matches
3. Verify activeMatchesProvider state stays consistent

**Expected Result**:
- ✅ No duplicate matches in list
- ✅ Completed matches removed from "active"
- ✅ State updates correctly after submit

**Verify**:
- Riverpod DevTools shows correct state changes
- No race conditions

---

### 8. Integration Tests

**Test**: `TC-MATCH-016: End-to-End Flow`

**Steps**:
1. Create singleplayer match (TC-MATCH-001)
2. Submit result with high score (TC-MATCH-003)
3. View in history (TC-MATCH-006)
4. Verify match result correct
5. Verify wallet updated with coins

**Expected Result**:
- ✅ Complete flow works without errors
- ✅ All rewards applied correctly
- ✅ History reflects match correctly

---

**Test**: `TC-MATCH-017: Multiplayer End-to-End`

**Steps**:
1. Start match vs opponent (TC-MATCH-002)
2. Submit with mixed scores (TC-MATCH-004 or TC-MATCH-005)
3. View in history
4. Verify all opponent details present

**Expected Result**:
- ✅ Opponent name displays correctly
- ✅ Result and scores accurate
- ✅ Timestamp correct

---

## Performance Tests

**Test**: `TC-MATCH-018: Large Match List (100+ matches)`

**Steps**:
1. Seed backend with 100+ completed matches
2. Navigate to History tab
3. Observe rendering and scroll performance

**Expected Result**:
- ✅ ListView loads smoothly
- ✅ Scroll is 60fps
- ✅ No memory leaks

**Verify**:
- Profiler shows < 16ms frame time
- Memory usage stable during scroll

---

## Regression Tests

**Test**: `TC-MATCH-019: Backward Compatibility — Spin Wheel Still Works`

**Steps**:
1. Navigate to Spin Wheel screen
2. Spin wheel
3. Verify reward claimed with new `claimStartedSpin()` method
4. Check wallet updated

**Expected Result**:
- ✅ Spin wheel still functional
- ✅ No interference with match API changes

---

## Testing Checklist

### Before Deployment
- [ ] All TC-MATCH-001 through TC-MATCH-017 pass
- [ ] Error logs clean (no ERROR level entries)
- [ ] Performance acceptable on low-end device (TC-MATCH-018)
- [ ] Network resilience verified (TC-MATCH-011, TC-MATCH-012)
- [ ] Regression tests pass (TC-MATCH-019)

### Code Review
- [ ] MatchesApiClient all methods return correct types
- [ ] MatchesService properly maps API responses
- [ ] ActiveMatchesNotifier handles errors gracefully
- [ ] MatchHistoryWidget renders all states correctly
- [ ] Challenge screen integrates History tab properly
- [ ] No unused imports or dead code

### QA Signoff
- [ ] Feature tested on multiple devices
- [ ] Tested on WiFi and cellular networks
- [ ] Edge cases verified

---

## Known Issues / Blockers

### None currently identified

---

## Success Criteria

✅ All core functionality working end-to-end  
✅ Error states handled gracefully  
✅ Performance acceptable (60fps scrolling)  
✅ Auto-refresh working (30s interval)  
✅ Timestamps update correctly (minute-level)  
✅ Spin wheel still functional (backward compat)  

---

## Next Steps

1. Execute all test cases
2. File bugs for any failures
3. Fix high-priority issues
4. Retest
5. Mark ready for production deployment

---

**Test Lead**: [To be assigned]  
**Date Started**: 2026-07-05  
**Date Completed**: [TBD]  
**Status**: Ready for QA
