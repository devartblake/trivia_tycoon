# Hardcoded Demo Data Inventory

**Last Updated:** June 26, 2026  
**Status:** To be replaced with API connections

---

## 📋 PRIORITY 1: CRITICAL (Must Remove for Production)

### 1. **MOCK LOGIN CREDENTIALS** 🔐
**Priority:** CRITICAL - Security Risk  
**Files:**
- `lib/screens/login_screen.dart` (Lines 29-96)
- `lib/screens/login_screen_mobile.dart` (Lines 64-100)

**Demo Data:**
```dart
// Admin accounts
admin@gmail.com / admin123 (Premium)
hunter@gmail.com / hunter (Premium)

// Regular accounts
premium@gmail.com / premium
dribbble@gmail.com / 12345
near.huscarl@gmail.com / subscribe to pewdiepie
@.com / .
```

**Why Critical:** Hardcoded credentials are a security vulnerability. Anyone with access to code can bypass authentication.

**Replacement Plan:**
- [ ] Remove all mock credentials from login screens
- [ ] Implement proper backend authentication validation
- [ ] Use real API endpoint: `POST /api/v1/auth/login`
- [ ] Return error if credentials don't match backend records

---

### 2. **ADMIN USER FIXTURES** 👥
**Priority:** CRITICAL - Fallback System  
**File:** `lib/admin/user_management/admin_users_mock_data.dart` (Lines 4-93)

**Demo Data (6 Users):**
```dart
john_doe (john@example.com) - Premium, 12450 points
jane_smith (jane@example.com) - User, 5680 points
bob_wilson (bob@example.com) - Moderator, 28900 points
alice_brown (alice@example.com) - Admin, 56780 points
charlie_davis (charlie@example.com) - User, 1450 points
banned_user (banned@example.com) - Banned, 2340 points
```

**Why Critical:** Admin dashboard shows mock users instead of real database records.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/admin/users`
- [ ] Fetch user list from backend with pagination
- [ ] Remove fallback mock data usage
- [ ] Add loading states for real API calls

---

## 📋 PRIORITY 2: HIGH (Game Content - Direct User Impact)

### 3. **TRIVIA QUESTIONS** ❓
**Priority:** HIGH - Core Feature  
**File:** `lib/game/services/question_loader_service.dart` (Lines 38-150+)

**Demo Data:** 25+ hardcoded question dataset references:
```dart
// Core datasets
'assets/data/questions/arts.json'
'assets/data/questions/general_knowledge.json'
'assets/data/questions/science.json'
'assets/data/questions/history.json'
// ... and 20+ more categories
```

**Why High:** Questions are loaded from these asset files. Real production questions should come from backend API.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/questions`
- [ ] Query params: `?category={categoryId}&difficulty={level}&count={n}`
- [ ] Cache questions locally in Hive for offline support
- [ ] Periodically sync new questions from API

**Note:** Check if JSON files exist in assets/data/questions/ - if they do, the API may be pointing to local files.

---

### 4. **QUIZ CATEGORIES** 📚
**Priority:** HIGH - Navigation/UX  
**Files:**
- `lib/game/services/quiz_category.dart` (Lines 454-512)
- Used by question selection UI

**Demo Data (43 categories):**
```dart
Core (10): Arts, Science, Mathematics, History, Geography, 
           Literature, Technology, Health, Sports, Entertainment

Extended (9): Economics, Philosophy, Psychology, Politics, Law,
              Environment, Current Events, Media, Social Studies

Specialized (14): Architecture, Astronomy, Business, Civics & Law...
```

**Why High:** Quiz navigation depends on these categories.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/categories`
- [ ] Store categories in Zustand state (React) / Provider (Flutter)
- [ ] Dynamically build UI from API response instead of hardcoded list
- [ ] Support dynamic category creation/updates from backend

---

### 5. **DAILY BONUSES** 🎁
**Priority:** HIGH - Player Engagement  
**File:** `lib/arcade/services/arcade_daily_bonus_service.dart` (Lines 22-30)

**Demo Data (7-day streak):**
```dart
Day 1: 250 coins, 2 gems
Day 2: 300 coins, 2 gems
Day 3: 350 coins, 3 gems
Day 4: 450 coins, 3 gems
Day 5: 550 coins, 4 gems
Day 6: 700 coins, 4 gems
Day 7: 900 coins, 5 gems
```

**Why High:** Players expect consistent reward progression.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/rewards/daily-bonus`
- [ ] Return bonus schedule based on backend config
- [ ] Allow backend to change rewards without app update
- [ ] Track streak in backend (not just local)

---

### 6. **MISSIONS (Daily/Weekly/Season)** 🎯
**Priority:** HIGH - Feature Integration  
**File:** `lib/arcade/missions/arcade_mission_catalog.dart` (Lines 11-108)

**Demo Data Examples:**
```dart
// Daily
daily_play_runs_3: Play 3 arcade runs → 250 coins, 1 gem
daily_quick_math_score_800: Score 800+ → 350 coins, 2 gems

// Weekly
weekly_any_run_score_5000: Score 5000+ → 750 coins, 4 gems
weekly_new_pb_2: Set 2 PBs → 600 coins, 4 gems

// Season
season_*_any_run_score_10000: Score 10000+ → 1500 coins, 10 gems
```

**Why High:** Missions drive daily/weekly engagement and player retention.

**Replacement Plan:**
- [ ] Implement API endpoints:
  - `GET /api/v1/missions/daily`
  - `GET /api/v1/missions/weekly`
  - `GET /api/v1/missions/season`
- [ ] Fetch missions on app startup
- [ ] Track completion status in backend
- [ ] Allow backend to create/modify missions without app update

---

### 7. **CHALLENGES** ⚔️
**Priority:** HIGH - PvP/Engagement  
**File:** `lib/game/services/challenge_service.dart` (Lines 67-140)

**Demo Data Examples:**
```dart
// Daily
d1: "Time Attack" - Answer 20 Q fast → 150 XP, Power-Up Box
d2: "Perfect Streak" - 10 correct row → "Flawless Mind" badge

// Weekly
w1: "Tier Gauntlet" - Win 3 duels → Promotion Token, 300 XP
w2: "Category Master: History" - 5000 points → Gold Box

// Special
s1: "Global Festival Quiz" → Seasonal Title
s2: "Guild Showdown" - 7-day team event → Guild Badge
```

**Why High:** Challenges are engagement drivers and progression mechanics.

**Replacement Plan:**
- [ ] Implement API endpoints:
  - `GET /api/v1/challenges/active`
  - `POST /api/v1/challenges/{id}/complete`
- [ ] Track challenge progress per user
- [ ] Support temporary/seasonal challenges from backend
- [ ] Notify users of new/expiring challenges

---

## 📋 PRIORITY 3: MEDIUM (Progression & Rewards)

### 8. **TIER PROGRESSION SYSTEM** 🏆
**Priority:** MEDIUM - Progression Backbone  
**File:** `lib/core/manager/tier_manager.dart` (Lines 17-100+)

**Demo Data (8+ tiers):**
```dart
Bronze Rookie (0 XP, Lv 1) → Welcome Badge, 100 Coins
Silver Scholar (500 XP, Lv 5) → Scholar Badge, 250 Coins, 5 Gems
Gold Master (1200 XP, Lv 10) → Master Badge, 500 Coins, 15 Gems
Platinum Elite (2500 XP, Lv 18) → Elite Badge, 1000 Coins, 30 Gems
Diamond Legend (5000 XP, Lv 25) → Legend Badge, 2000 Coins, 50 Gems
Master Sage (10000 XP, Lv 35) → Sage Badge, 5000 Coins, 100 Gems
Grandmaster (20000 XP, Lv 50) → Grandmaster Badge, 10000 Coins, 200 Gems
Champion (continues...)
```

**Why Medium:** Critical for progression, but less frequent than questions/missions.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/progression/tiers`
- [ ] Return tier definitions with XP thresholds and rewards
- [ ] Allow backend to balance progression without app update
- [ ] Cache tier data locally

---

### 9. **REWARD STEP PRESETS** 💰
**Priority:** MEDIUM - UI Preview  
**File:** `lib/screens/rewards/presets/reward_step_presets.dart` (Lines 6-117)

**Demo Data (3 preset types):**
```dart
// Daily Spin Rewards
5 pts: Mystery Box
20 pts: Gift Card
50 pts: 300 Coins
100 pts: 2x Premium Gift
200 pts: 500 Bonus Coins

// Level Up Rewards
10 pts: 100 Coins
25 pts: 10 Gems
50 pts: Power-Up
100 pts: Badge
250 pts: Premium Access

// Achievement Rewards
15 pts: XP Boost
30 pts: Avatar
60 pts: Theme
```

**Why Medium:** Used for UI visualization of reward progression.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/rewards/progression-tiers`
- [ ] Fetch actual reward structure from backend
- [ ] Update UI dynamically based on API response
- [ ] Support backend customization of reward tiers

---

### 10. **WEEKLY REWARDS** 🎲
**Priority:** MEDIUM - Login Incentive  
**File:** `lib/screens/rewards/widgets/weekly_rewards_widget.dart` (Lines 33-41)

**Demo Data (7-day schedule):**
```dart
Day 1: 100 coins
Day 2: Mystery reward
Day 3: Mystery reward
Day 4: 200 coins
Days 5-7: Mystery rewards
```

**Why Medium:** Player engagement feature, but not critical path.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/rewards/weekly`
- [ ] Track which days user has claimed
- [ ] Return mystery reward details only when claimed
- [ ] Allow backend to change weekly schedule

---

## 📋 PRIORITY 4: LOW (Configuration & Game Settings)

### 11. **GAME DIFFICULTY CONFIGS** 🎮
**Priority:** LOW - Game Settings  
**File:** `lib/arcade/games/memory_flip/memory_flip_models.dart` (Lines 16-47)

**Demo Data (4 difficulty levels):**
```dart
Easy: 12 cards, 60s, 90 pts/match, 12 pts penalty
Normal: 16 cards, 70s, 110 pts/match, 14 pts penalty
Hard: 20 cards, 75s, 130 pts/match, 16 pts penalty
Insane: 24 cards, 80s, 150 pts/match, 18 pts penalty
```

**Why Low:** Game-specific settings that rarely change.

**Replacement Plan:**
- [ ] Create generic difficulty configuration structure
- [ ] Implement API endpoint: `GET /api/v1/games/{gameId}/difficulties`
- [ ] Apply to all arcade games, not just Memory Flip
- [ ] Allow backend to tune game balance without code changes

---

### 12. **EMAIL NOTIFICATION SAMPLES** 📧
**Priority:** LOW - Demo Component  
**File:** `lib/ui_components/swipe_notifications/demo_data.dart` (Lines 33-236)

**Demo Data (20 emails):**
```dart
20 hardcoded email entries with sender names:
- Jeffrey Evans, Jordan Chow, Katherine Woodward, Maddie Toohey
- Tamia Clouthier, Daniel Song, Andrew Argue
Categories: Work, Personal, Updates, Promotions
Avatar paths: images/avatars/avatar-1.png through avatar-5.png
```

**Why Low:** This appears to be for UI component demo/testing only.

**Replacement Plan:**
- [ ] Move to test/fixtures directory if used by tests
- [ ] Remove from main app if not needed
- [ ] Use real notification API for actual notifications

---

### 13. **SAMPLE STORE ITEMS** 🛍️
**Priority:** LOW - Store Mock  
**File:** `lib/core/utils/sample_store_data.dart` (Lines 4-32)

**Demo Data (3 items):**
```dart
Fox Avatar (200 coins)
Dark Mode Theme (350 diamonds)
Hint Power-Up (100 coins)
```

**Why Low:** Simple store mockup for testing.

**Replacement Plan:**
- [ ] Implement API endpoint: `GET /api/v1/store/items`
- [ ] Fetch store catalog from backend
- [ ] Display real inventory from database

---

### 14. **ONBOARDING QUIZ QUESTIONS** 📝
**Priority:** LOW - Onboarding Flow  
**File:** `lib/screens/onboarding/steps/first_session_challenge_step.dart` (Lines 29-45)

**Demo Data (3 questions):**
```dart
1. "Which planet is known as the Red Planet?" → Mars
2. "How many sides does a hexagon have?" → 6
3. "Which element has the chemical symbol 'O'?" → Oxygen
```

**Why Low:** Used only in onboarding flow, can be hardcoded.

**Replacement Plan:**
- [ ] Can remain hardcoded for onboarding
- [ ] Or implement API endpoint: `GET /api/v1/questions/onboarding`
- [ ] Allows backend to customize onboarding experience

---

### 15. **COUNTRIES LIST** 🌍
**Priority:** LOW - Static Data  
**File:** `lib/screens/onboarding/steps/country_step.dart` (Lines 24-33 & 35+)

**Demo Data (100+ countries):**
```dart
Popular Countries (8):
United States, United Kingdom, Canada, Australia, 
Germany, France, India, Japan

Complete List: 100+ countries (Afghanistan through Switzerland shown)
```

**Why Low:** Countries are static reference data.

**Replacement Plan:**
- [ ] Can remain hardcoded (rarely changes)
- [ ] Or implement API endpoint: `GET /api/v1/countries`
- [ ] Better for localization and maintaining single source of truth

---

### 16. **TEST DATA** ✅
**Priority:** SAFE - Test-Only  
**File:** `test/score_summary_test_data.dart` (Lines 5-194)

**Demo Data (6 test scenarios):**
```dart
Kindergarten: 8/10 questions
Grade 3: 12/15 mathematics
Grade 6: 14/20 science
Grade 8: 16/18 language arts
Grade 10: 22/25 mathematics
Grade 12: 28/30 science
```

**Why Safe:** Isolated in test directory, doesn't affect production.

**Replacement Plan:**
- [ ] No action needed - leave as test fixtures
- [ ] These are appropriate for unit/widget testing

---

## 📊 Removal Strategy

### Phase 1: Quick Wins (Week 1)
- ❌ Remove mock login credentials
- ❌ Remove admin user fixtures
- ✅ Keep: Categories (needed for initial load)

### Phase 2: Core Gameplay (Week 2-3)
- ❌ Replace trivia questions with API
- ❌ Replace missions with API
- ❌ Replace challenges with API

### Phase 3: Progression & Rewards (Week 3-4)
- ❌ Replace tiers with API
- ❌ Replace daily bonuses with API
- ❌ Replace weekly rewards with API

### Phase 4: Nice-to-Have (Week 4-5)
- ❌ Replace game configs with API
- ❌ Replace store items with API
- ⚪ Keep or replace: Countries, Onboarding questions, Email demos

---

## 📌 Summary Table

| Category | File | Lines | Difficulty | Status |
|----------|------|-------|-----------|--------|
| 🔐 Login Credentials | login_screen.dart | 29-96 | 🟢 Easy | ❌ Not Started |
| 👥 Admin Users | admin_users_mock_data.dart | 4-93 | 🟢 Easy | ❌ Not Started |
| ❓ Questions | question_loader_service.dart | 38-150 | 🟠 Medium | ❌ Not Started |
| 📚 Categories | quiz_category.dart | 454-512 | 🟢 Easy | ⚠️ Partially Used |
| 🎁 Daily Bonus | arcade_daily_bonus_service.dart | 22-30 | 🟢 Easy | ❌ Not Started |
| 🎯 Missions | arcade_mission_catalog.dart | 11-108 | 🟠 Medium | ❌ Not Started |
| ⚔️ Challenges | challenge_service.dart | 67-140 | 🟠 Medium | ❌ Not Started |
| 🏆 Tiers | tier_manager.dart | 17-100 | 🟠 Medium | ❌ Not Started |
| 💰 Reward Steps | reward_step_presets.dart | 6-117 | 🟢 Easy | ❌ Not Started |
| 🎲 Weekly Rewards | weekly_rewards_widget.dart | 33-41 | 🟢 Easy | ❌ Not Started |
| 🎮 Game Config | memory_flip_models.dart | 16-47 | 🟢 Easy | ❌ Not Started |
| 📧 Email Samples | demo_data.dart | 33-236 | 🟢 Easy | ✅ Demo Only |
| 🛍️ Store Items | sample_store_data.dart | 4-32 | 🟢 Easy | ❌ Not Started |
| 📝 Onboarding Q | first_session_challenge_step.dart | 29-45 | 🟢 Easy | ⚠️ Can Keep |
| 🌍 Countries | country_step.dart | 24-33 | 🟢 Easy | ⚠️ Can Keep |
| ✅ Tests | score_summary_test_data.dart | 5-194 | 🟢 Easy | ✅ Safe |

---

**Next Steps:**
1. Review this list with team
2. Prioritize which items to replace first
3. Define API contract for each replacement
4. Create tracking issues for each phase
