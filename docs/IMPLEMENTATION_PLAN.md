# Implementation Plan: API Integration & Security

**Timeline:** June 26, 2026 - Immediate execution  
**Priority:** Critical - Security + Core Features

---

## 🎯 GOAL 1: Questions API Integration

### Objective
Replace hardcoded question loading from assets with dynamic API fetching on:
- App startup (cache questions)
- Category selection (fetch new category)
- Multiplayer matches (fetch on-demand)

### Current State
- `QuestionLoaderService` loads from asset JSON files
- Caching implemented with timestamps
- 25+ hardcoded dataset references

### Implementation Strategy

#### Phase 1: Create Questions API Service (Day 1)
**New File:** `lib/core/services/question_api_client.dart`

```dart
class QuestionApiClient {
  // Endpoints needed:
  Future<List<QuestionModel>> getQuestionsByCategory(
    String categoryId, {
    int? count = 20,
    String? difficulty,
    String? mode, // For multiplayer
  });

  Future<Map<String, List<QuestionModel>>> getAllCategoriesQuestions(
    List<String> categoryIds, {
    int? countPerCategory = 10,
  });

  Future<List<QuestionModel>> getMultiplayerQuestions(
    String matchId, {
    required int count,
    required List<String> categories,
  });
}
```

**API Endpoints to Define:**
```
GET /api/v1/questions?category={categoryId}&count={count}&difficulty={level}
GET /api/v1/questions/batch?categories={id1,id2}&count={count}
POST /api/v1/matches/{matchId}/questions (for multiplayer)
```

#### Phase 2: Modify QuestionLoaderService (Day 1)
**File:** `lib/game/services/question_loader_service.dart`

- Add `QuestionApiClient` instance
- Modify `loadDataset()` to try API first, fallback to assets
- Implement dual-mode loading (API + Assets)
- Update caching to work with both sources

```dart
// Pseudo-code structure
Future<List<QuestionModel>> loadDataset(String datasetName) async {
  // 1. Check cache
  if (cached) return cached;
  
  // 2. Try API
  try {
    final apiQuestions = await _apiClient.getQuestionsByCategory(datasetName);
    _cache(datasetName, apiQuestions);
    return apiQuestions;
  } catch (e) {
    LogManager.warn('API failed, falling back to assets');
  }
  
  // 3. Fallback to assets
  return _loadFromPath(assetPath, datasetName);
}
```

#### Phase 3: App Startup Loading (Day 1)
**File:** `lib/core/services/app_init_service.dart`

Add questions preloading:
```dart
Future<void> _preloadQuestions() async {
  final categories = QuizCategory.values.take(10); // Top 10 categories
  await questionLoader.loadQuestionsFromDatasets(
    categories.map((c) => c.datasetName).toList()
  );
}
```

#### Phase 4: On-Demand Category Loading (Day 2)
**File:** `lib/screens/category_selection_screen.dart`

When user selects category:
```dart
onCategoryTap: (category) async {
  showLoadingIndicator();
  final questions = await questionLoader.loadDataset(category.datasetName);
  // Animate to game screen
}
```

#### Phase 5: Multiplayer Questions (Day 2)
**File:** `lib/multiplayer/services/multiplayer_match_service.dart`

When match starts:
```dart
Future<void> startMatch(String matchId, List<String> categories) async {
  final questions = await _questionApi.getMultiplayerQuestions(
    matchId,
    count: 20,
    categories: categories,
  );
  _currentMatch.questions = questions;
}
```

### Testing Strategy
- [ ] Unit test: QuestionApiClient mocking backend
- [ ] Integration test: QuestionLoaderService with API mock
- [ ] E2E test: Full app startup with API calls
- [ ] Fallback test: Verify asset loading when API fails

### Success Metrics
- ✅ Questions load from API on startup
- ✅ Questions cache properly (not re-fetching on reload)
- ✅ Category selection fetches new questions on-demand
- ✅ Multiplayer gets dedicated questions
- ✅ Graceful fallback to assets if API fails
- ✅ No console errors or blank question screens

---

## 🔐 GOAL 2: Remove Hardcoded Credentials

### Security Risk
Hardcoded login credentials in source code:
- Anyone with code access can bypass authentication
- Production builds could leak these if not removed
- Violates security best practices

### Files to Fix
1. `lib/screens/login_screen.dart` (Lines 29-96)
2. `lib/screens/login_screen_mobile.dart` (Lines 64-100)

### Current Data
```dart
admin@gmail.com / admin123
premium@gmail.com / premium
dribbble@gmail.com / 12345
hunter@gmail.com / hunter
near.huscarl@gmail.com / subscribe to pewdiepie
@.com / .
```

### Implementation Strategy (Day 1)

#### Option A: Complete Removal (RECOMMENDED)
Remove all demo credentials. Users must enter real ones.

**Changes:**
1. Delete entire demo credentials list from both files
2. Remove demo mode detection logic
3. Require real credentials to proceed

**File:** `lib/screens/login_screen.dart`
```dart
// BEFORE
final _demoCredentials = [
  {'email': 'admin@gmail.com', 'password': 'admin123'},
  ...
];

// AFTER
// (Remove entirely)
```

#### Option B: Development-Only Environment Variable
Keep for development but make it explicit.

**Changes:**
1. Wrap credentials in `if (kDebugMode)` check
2. Add warning dialog in debug mode
3. Skip check in release builds

```dart
if (kDebugMode) {
  // Add warning
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('DEBUG MODE'),
      content: Text('Demo credentials active. Not for production.'),
    ),
  );
  
  final _demoCredentials = [...]; // Only in debug
}
```

### Recommendation
**Go with Option A (Complete Removal)** because:
- Force real authentication testing
- No accidental production exposure
- Encourages proper backend integration
- Cleaner codebase

### Testing
- [ ] Login screen loads without credentials dropdown
- [ ] User must enter real email/password
- [ ] Backend rejects invalid credentials
- [ ] Successful login with real test account works

---

## 📋 GOAL 3: Core Content Priority Plan

### Overview
Plan which of the remaining 14 demo data categories to replace and in what order.

### Decision Matrix

#### TIER 1: Must Do (Weeks 1-2)
**Impact:** High | **Effort:** Medium | **Security:** Critical

1. **Tier Progression System** (2 days)
   - File: `lib/core/manager/tier_manager.dart`
   - Why: Affects all progression/rewards
   - Backend: GET /api/v1/progression/tiers
   - Impact: User progression unlocked

2. **Daily Bonuses** (1 day)
   - File: `lib/arcade/services/arcade_daily_bonus_service.dart`
   - Why: Core engagement mechanic
   - Backend: GET /api/v1/rewards/daily-bonus
   - Impact: Player retention

3. **Weekly Rewards** (1 day)
   - File: `lib/screens/rewards/widgets/weekly_rewards_widget.dart`
   - Why: Login incentive
   - Backend: GET /api/v1/rewards/weekly
   - Impact: Daily active users

#### TIER 2: Important (Weeks 2-3)
**Impact:** High | **Effort:** Medium | **Security:** Medium

4. **Missions System** (3 days)
   - Files: `lib/arcade/missions/arcade_mission_catalog.dart`
   - Why: Engagement + progression drivers
   - Backend: GET /api/v1/missions/{type}
   - Impact: Daily quests/activities

5. **Challenges** (3 days)
   - File: `lib/game/services/challenge_service.dart`
   - Why: Social competition mechanic
   - Backend: GET /api/v1/challenges/active
   - Impact: PvP engagement

6. **Quiz Categories** (2 days)
   - File: `lib/game/services/quiz_category.dart`
   - Why: Dynamic content library
   - Backend: GET /api/v1/categories
   - Impact: New category additions without rebuild

#### TIER 3: Nice-to-Have (Weeks 3-4)
**Impact:** Medium | **Effort:** Low | **Security:** Low

7. **Reward Presets** (1 day)
   - File: `lib/screens/rewards/presets/reward_step_presets.dart`
   - Why: UI visualization only
   - Backend: GET /api/v1/rewards/tiers
   - Impact: Visual polish

8. **Game Difficulty Configs** (1 day)
   - File: `lib/arcade/games/memory_flip/memory_flip_models.dart`
   - Why: Game balance
   - Backend: GET /api/v1/games/{id}/difficulties
   - Impact: Per-game tuning

9. **Store Items** (1 day)
   - File: `lib/core/utils/sample_store_data.dart`
   - Why: Shop catalog
   - Backend: GET /api/v1/store/items
   - Impact: Monetization

#### TIER 4: Keep or Optional (Future)
**Impact:** Low | **Effort:** Low | **Security:** Low

10. **Countries List** - Keep hardcoded (static reference)
11. **Onboarding Questions** - Keep hardcoded (one-time flow)
12. **Email Samples** - Remove or move to tests
13. **Test Data** - Already isolated, safe

### Proposed 6-Week Roadmap

```
WEEK 1
├─ Remove hardcoded credentials (Security First)
└─ Implement Questions API (Fix Now)

WEEK 2
├─ Tier Progression → API
├─ Daily Bonuses → API
└─ Weekly Rewards → API

WEEK 3
├─ Missions System → API
├─ Challenges → API
└─ Quiz Categories → API

WEEK 4
├─ Reward Presets → API
├─ Game Configs → API
└─ Store Items → API

WEEK 5
├─ Testing & Integration
└─ Backend Bug Fixes

WEEK 6
└─ Production Ready Review
```

### Backend API Contracts Needed

```typescript
// CRITICAL (Week 1-2)
GET  /api/v1/questions
GET  /api/v1/questions/{categoryId}
POST /api/v1/matches/{matchId}/questions
GET  /api/v1/progression/tiers
GET  /api/v1/rewards/daily-bonus
GET  /api/v1/rewards/weekly

// IMPORTANT (Week 2-3)
GET  /api/v1/missions/daily
GET  /api/v1/missions/weekly
GET  /api/v1/missions/season
GET  /api/v1/challenges/active
GET  /api/v1/categories

// NICE-TO-HAVE (Week 3-4)
GET  /api/v1/rewards/tiers
GET  /api/v1/games/{gameId}/difficulties
GET  /api/v1/store/items
```

---

## 📅 Execution Timeline

### TODAY (June 26, 2026)

**Morning (2 hours):**
- [x] Identify all demo data (Completed)
- [x] Create implementation plan (This document)
- [ ] Rebuild Flutter web (fix console errors)

**Afternoon (4 hours):**
- [ ] Remove hardcoded login credentials
- [ ] Create QuestionApiClient service
- [ ] Update QuestionLoaderService to use API
- [ ] Add question preloading to app startup

**Evening (2 hours):**
- [ ] Create basic API mock for testing
- [ ] Test question loading flow
- [ ] Document API contract

### TOMORROW (June 27, 2026)

**Morning (3 hours):**
- [ ] Implement on-demand category loading
- [ ] Add multiplayer question fetching
- [ ] Complete fallback logic

**Afternoon (3 hours):**
- [ ] Create Tier API client
- [ ] Update TierManager to use API
- [ ] Test progression system

**Evening (2 hours):**
- [ ] Create Daily Bonus API service
- [ ] Create Weekly Rewards API service
- [ ] Document progress

---

## 🚀 Implementation Checklist

### Security First
- [ ] Remove credentials from login_screen.dart
- [ ] Remove credentials from login_screen_mobile.dart
- [ ] Audit for any other hardcoded secrets
- [ ] Update CLAUDE.md with security guidelines

### Fix Now (Questions API)
- [ ] Create QuestionApiClient
- [ ] Update QuestionLoaderService
- [ ] Add app startup preloading
- [ ] Implement on-demand loading
- [ ] Add multiplayer support
- [ ] Create mock API for testing
- [ ] Test fallback to assets

### Core Content Plan
- [ ] Define all API contracts
- [ ] Create 6-week implementation schedule
- [ ] Assign team members
- [ ] Create tracking issues

---

## Notes for Backend Team

**Questions API Specification:**
```json
Request:  GET /api/v1/questions?category=science&count=20&difficulty=medium
Response: {
  "data": [
    {
      "id": "q1",
      "question": "What is H2O?",
      "options": ["Water", "Hydrogen", "Oxygen", "Salt"],
      "correctAnswer": 0,
      "category": "science",
      "difficulty": "easy"
    }
  ],
  "meta": {
    "total": 150,
    "cached": false,
    "timestamp": "2026-06-26T15:00:00Z"
  }
}
```

**Success Criteria:**
- All 25+ categories available via API
- Questions properly formatted matching `QuestionModel`
- Response time < 1s for cached questions
- Proper error handling with fallback

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| API not ready | High | Keep asset fallback, mark API as optional |
| Slow API calls | Medium | Implement aggressive caching, pre-fetch |
| Category mismatch | Medium | Maintain category ID mapping |
| Network errors | Low | Offline mode with cached questions |

---

**Document Version:** 1.0  
**Status:** Ready for Implementation  
**Last Updated:** June 26, 2026
