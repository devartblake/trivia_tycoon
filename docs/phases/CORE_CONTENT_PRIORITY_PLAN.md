# Core Content Priority Plan - 6 Week Roadmap

**Created:** June 26, 2026  
**Duration:** 6 weeks (June 26 - August 6, 2026)  
**Objective:** Replace remaining 13 hardcoded demo data categories with API integration

---

## Executive Summary

After removing hardcoded credentials ✅, we have 13 remaining demo data categories to replace. This roadmap prioritizes them by impact, complexity, and dependencies.

**Key Principle:** Build core first (progression, missions, challenges), then polish (configs, items).

---

## 📊 Priority Matrix

```
Impact vs Effort vs Security
┌────────┬─────────┬──────────┐
│ TIER 1 │ IMPACT  │ EFFORT   │
├────────┼─────────┼──────────┤
│ Tiers  │ CRITICAL│ 2 days   │
│ Bonus  │ HIGH    │ 1 day    │
│ Rewards│ HIGH    │ 1 day    │
├────────┼─────────┼──────────┤
│ TIER 2 │         │          │
├────────┼─────────┼──────────┤
│Missions│ HIGH    │ 3 days   │
│Challen.│ HIGH    │ 3 days   │
│Categor.│ HIGH    │ 2 days   │
├────────┼─────────┼──────────┤
│ TIER 3 │         │          │
├────────┼─────────┼──────────┤
│Presets │ MEDIUM  │ 1 day    │
│ Configs│ MEDIUM  │ 1 day    │
│ Stores │ MEDIUM  │ 1 day    │
└────────┴─────────┴──────────┘
```

---

## 🎯 WEEK 1: Foundation (June 26-30)

### June 26 (TODAY)
**Status:** 🟢 In Progress

**Morning (2-3 hours):**
- [x] Identify all demo data (Completed)
- [x] Create implementation plan (Completed)
- [x] Rebuild Flutter web (Running)
- [x] Remove hardcoded credentials (Completed ✅)

**Afternoon (3-4 hours):**
- [ ] Create Questions API Client
- [ ] Update QuestionLoaderService
- [ ] Implement question caching strategy
- [ ] Add app startup preloading

**Evening (2 hours):**
- [ ] Create mock API for testing questions
- [ ] Document Questions API contract
- [ ] Commit changes

---

### June 27 (Thursday)
**Focus:** Questions API Completion + Tier API Start

**Morning (3 hours):**
- [ ] Implement on-demand category loading
- [ ] Add multiplayer question fetching
- [ ] Complete fallback logic (assets → API)
- [ ] Unit tests for QuestionApiClient

**Afternoon (3 hours):**
- [ ] Create TierApiClient
- [ ] Define Tier progression structure in backend
- [ ] Update TierManager to use API
- [ ] Cache tier data locally

**Evening (2 hours):**
- [ ] Test tier progression
- [ ] Document Tier API contract
- [ ] Commit changes

---

### June 28 (Friday)
**Focus:** Bonuses & Rewards APIs

**Morning (2 hours):**
- [ ] Create DailyBonusApiClient
- [ ] Implement bonus fetching on app startup
- [ ] Add bonus claim tracking

**Afternoon (2 hours):**
- [ ] Create WeeklyRewardsApiClient
- [ ] Implement week tracking
- [ ] Add reward claiming logic

**Evening (2 hours):**
- [ ] Create mock API responses
- [ ] Integration test all three systems
- [ ] Document Daily/Weekly APIs
- [ ] Commit changes

---

### June 29-30 (Weekend)
**Tasks:** Documentation + Buffer Time

- [ ] Write comprehensive API contract documentation
- [ ] Create architecture diagrams
- [ ] Plan Week 2 in detail
- [ ] Code review of Week 1 work
- [ ] Buffer for any overruns

---

## 🎯 WEEK 2: Mission & Challenge Systems (July 1-5)

### July 1-2 (Mon-Tue)
**Focus:** Mission System API

**Tasks (6 hours total):**
- [ ] Define mission data structure
  - Mission ID, title, description
  - Reward amounts (coins, gems, XP)
  - Completion criteria
  - Difficulty tiers
  
- [ ] Create MissionApiClient
  - GET /api/v1/missions/daily
  - GET /api/v1/missions/weekly
  - GET /api/v1/missions/season
  - POST /api/v1/missions/{id}/complete

- [ ] Update MissionCatalog
  - Replace hardcoded missions
  - Fetch from API on startup
  - Cache with TTL (24h for daily, 7d for weekly)

- [ ] Implement mission completion tracking
  - Update progress in backend
  - Reflect completion in UI
  - Handle edge cases (timezone, reset times)

---

### July 3-4 (Wed-Thu)
**Focus:** Challenge System API

**Tasks (6 hours total):**
- [ ] Define challenge data structure
  - Challenge ID, name, description
  - Challenge type (daily, weekly, seasonal, special)
  - Completion requirements
  - Reward tiers (100%, 75%, 50%)
  
- [ ] Create ChallengeApiClient
  - GET /api/v1/challenges/active
  - GET /api/v1/challenges/{type}
  - POST /api/v1/challenges/{id}/progress
  - POST /api/v1/challenges/{id}/complete

- [ ] Update ChallengeService
  - Replace hardcoded challenges
  - Fetch active challenges on startup
  - Update progress in real-time
  - Handle challenge expiration

- [ ] Leaderboard integration
  - Fetch challenge leaderboards
  - Display top performers
  - Track user rank

---

### July 5 (Friday)
**Focus:** Integration & Testing

**Tasks (4 hours):**
- [ ] Integration test missions + challenges
- [ ] Mock API for complete mission/challenge flow
- [ ] E2E testing with UI
- [ ] Document mission/challenge APIs
- [ ] Code review & commits

---

## 🎯 WEEK 3: Quiz Categories + Rewards Polish (July 6-12)

### July 6-7 (Mon-Tue)
**Focus:** Quiz Categories API

**Tasks (4 hours total):**
- [ ] Create CategoryApiClient
  - GET /api/v1/categories
  - GET /api/v1/categories/{id}
  - Support filtering/pagination
  
- [ ] Update QuizCategory handling
  - Replace hardcoded list
  - Fetch categories on app startup
  - Handle new categories without rebuild
  - Support category metadata (icon, color, description)

- [ ] Dynamic category UI
  - Update category selection screen
  - Display from API response
  - Handle loading states

- [ ] Test with varying category counts
  - 10 categories
  - 50 categories
  - 100+ categories

---

### July 8-9 (Wed-Thu)
**Focus:** Reward Presets & Polish

**Tasks (4 hours total):**
- [ ] Create RewardPresetApiClient
  - GET /api/v1/rewards/tiers
  - Define preset structure
  
- [ ] Update RewardPresets
  - Replace hardcoded progressions
  - Dynamic tier visualization
  - Support custom tier additions

- [ ] Integration testing
  - Test all three APIs together
  - Monitor performance
  - Test offline fallbacks

---

### July 10-12 (Fri-Weekend)
**Focus:** Stabilization & Planning

- [ ] Full system integration test
- [ ] Performance profiling
- [ ] Bug fixes from testing
- [ ] Plan Week 4-6 in detail
- [ ] Update documentation

---

## 🎯 WEEK 4: Game Config & Polish (July 13-19)

### July 13-14 (Mon-Tue)
**Focus:** Game Difficulty Configs API

**Tasks (3 hours):**
- [ ] Create GameConfigApiClient
  - GET /api/v1/games/{gameId}/difficulties
  - Support game balance updates without rebuild

- [ ] Update Memory Flip configs
  - Fetch from API on game start
  - Per-difficulty customization (cards, time, points)
  
- [ ] Apply to other arcade games
  - Extend config system to all games
  - Centralize difficulty management

---

### July 15-16 (Wed-Thu)
**Focus:** Store Items API

**Tasks (3 hours):**
- [ ] Create StoreApiClient
  - GET /api/v1/store/items
  - GET /api/v1/store/categories
  - Support filtering/sorting

- [ ] Update SampleStoreData
  - Replace hardcoded items
  - Dynamic item list from API
  - Support new items without rebuild

- [ ] Implement store flow
  - Item purchase
  - Inventory management
  - Receipt validation

---

### July 17-19 (Fri-Weekend)
**Focus:** Testing & Buffer

- [ ] Comprehensive testing all systems
- [ ] Performance optimization
- [ ] Security audit
- [ ] Plan final 2 weeks
- [ ] Update documentation

---

## 🎯 WEEK 5: Integration & Testing (July 20-26)

**Focus:** Full System Integration

### Daily Tasks
- [ ] Run full test suite
- [ ] Performance monitoring
- [ ] API contract validation
- [ ] Bug fixes
- [ ] Documentation updates

### Testing Areas
- [ ] Offline mode functionality
- [ ] Slow network conditions
- [ ] API timeout scenarios
- [ ] Cache invalidation
- [ ] Multi-user scenarios

### Deliverables
- [ ] Complete API contract documentation
- [ ] Performance baseline report
- [ ] Security audit findings + fixes
- [ ] Test coverage report (target: >90%)

---

## 🎯 WEEK 6: Production Readiness (July 27-Aug 2)

**Focus:** Preparation for Production

### Pre-Release Checklist
- [ ] All APIs fully implemented
- [ ] All tests passing (>90% coverage)
- [ ] Performance meets targets
- [ ] Security audit complete
- [ ] Documentation complete
- [ ] Backend ready for production
- [ ] Analytics instrumented
- [ ] Error handling tested

### Deliverables
- [ ] Release notes (what changed)
- [ ] Migration guide (how to enable API)
- [ ] Rollback plan (if needed)
- [ ] Monitoring & alerting setup
- [ ] Customer communication

### Final Buffer
- [ ] Days 3-5: Reserve for final issues
- [ ] Ops preparation
- [ ] Smoke testing in staging
- [ ] Final QA approval

---

## 📋 Remaining Demo Data to Replace

| Item | Week | Files | Effort | Dependencies |
|------|------|-------|--------|--------------|
| **Questions** | 1 | question_loader_service.dart | 2 days | None |
| **Tier System** | 1 | tier_manager.dart | 2 days | Questions ✓ |
| **Daily Bonus** | 1 | arcade_daily_bonus_service.dart | 1 day | Tiers |
| **Weekly Rewards** | 1 | weekly_rewards_widget.dart | 1 day | Tiers |
| **Missions** | 2 | arcade_mission_catalog.dart | 3 days | Tiers |
| **Challenges** | 2 | challenge_service.dart | 3 days | Tiers, Missions |
| **Categories** | 3 | quiz_category.dart | 2 days | Questions ✓ |
| **Reward Presets** | 3 | reward_step_presets.dart | 1 day | Tiers, Missions |
| **Game Configs** | 4 | memory_flip_models.dart | 1 day | None |
| **Store Items** | 4 | sample_store_data.dart | 1 day | None |
| **Countries** | - | country_step.dart | 0 days | Keep hardcoded |
| **Onboarding Q** | - | first_session_challenge_step.dart | 0 days | Keep hardcoded |
| **Test Data** | - | score_summary_test_data.dart | 0 days | Already safe |

---

## 🚀 Success Metrics

### Week 1
- ✅ Questions API working (startup + on-demand)
- ✅ Tier progression updated
- ✅ Daily/Weekly bonuses fetched from API
- ✅ No console errors
- ✅ Offline fallback working

### Week 2
- ✅ All 6 mission types available
- ✅ Challenges loading & tracking
- ✅ Leaderboards working
- ✅ Real-time progress updates

### Week 3
- ✅ 50+ categories supported
- ✅ Dynamic category loading
- ✅ Reward tiers customizable
- ✅ Zero hardcoded progression values

### Week 4
- ✅ Game difficulty balance
- ✅ Store inventory live
- ✅ Per-game customization
- ✅ Item purchasing working

### Week 5-6
- ✅ All systems integrated
- ✅ >90% test coverage
- ✅ Performance baseline met
- ✅ Production ready

---

## 🔗 API Endpoints Summary

**CRITICAL (Week 1):**
```
GET  /api/v1/questions
GET  /api/v1/progression/tiers
GET  /api/v1/rewards/daily-bonus
GET  /api/v1/rewards/weekly
```

**IMPORTANT (Week 2-3):**
```
GET  /api/v1/missions/{type}
GET  /api/v1/challenges/active
POST /api/v1/missions/{id}/complete
POST /api/v1/challenges/{id}/progress
GET  /api/v1/categories
```

**NICE-TO-HAVE (Week 4):**
```
GET  /api/v1/games/{gameId}/difficulties
GET  /api/v1/store/items
GET  /api/v1/rewards/tiers
```

---

## 📝 Notes

### Dependency Management
- Start with questions (no dependencies)
- Build tier system (depends on questions data)
- Layer missions/challenges (depend on tiers)
- Polish with categories/configs (flexible)

### Caching Strategy
```
Questions:    24-hour TTL (user may get new Qs daily)
Tiers:        App lifetime (rarely changes)
Missions:     24-hour TTL (daily reset)
Challenges:   App lifetime or event-driven
Categories:   24-hour TTL
Configs:      6-hour TTL (balance changes)
Store:        6-hour TTL (inventory updates)
```

### Performance Targets
- API response < 500ms (cached)
- First load < 2 seconds
- Category switch < 500ms
- No jank during gameplay

### Monitoring
- API latency tracking
- Cache hit rate monitoring
- Error rate tracking
- User engagement metrics

---

**Document Version:** 1.0  
**Last Updated:** June 26, 2026  
**Status:** Ready for Execution
