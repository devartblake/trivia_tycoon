# Phase 2: API Integration - Implementation Plan & Progress

**Status**: 🟡 IN PROGRESS  
**Date Started**: 2026-06-28  
**Estimated Duration**: 50 hours (2-4 days)  
**Target Completion**: 2026-06-30

---

## Overview

Phase 2 replaces the mock data architecture with real backend API integration while maintaining Phase 1's performance improvements and ensuring 100% backward compatibility.

### Phase 2 Objectives
1. ✅ Replace mock tier definitions with real API
2. ✅ Replace mock player progress with real API
3. ✅ Implement XP award API integration
4. ✅ Add multi-level caching (disk + memory)
5. ✅ Maintain 60 FPS performance
6. ✅ Achieve 95%+ success rate
7. ⏳ WebSocket real-time updates (optional)

### Timeline
- **Day 1 (Today)**: Task 2.1 - Backend API Integration
- **Day 2**: Task 2.2 - Multi-Level Caching
- **Day 3 (Optional)**: Task 2.3 - WebSocket Real-Time Updates

---

## Current State Assessment

### ✅ Already Implemented
1. **SpinWheelApiClient** (400+ lines)
   - Segment fetching: `getSegments()`
   - Probability config: `getProbabilityConfig()`
   - Analytics: `getAnalytics()`
   - Reward claiming: `claimReward()`
   - Spin logging: `logSpinResult()`

2. **TierApiClient** (200+ lines)
   - Mock tier definitions (7 tiers)
   - Mock player progress
   - Mock XP award logic
   - All methods present, ready for API swap

3. **Providers** (250+ lines)
   - `spinSegmentConfigProvider` - ready for API
   - `spinProbabilityConfigProvider` - ready for API
   - `playerTierProgressProvider` - ready for API
   - Error handling with fallbacks implemented

4. **Models & Structures**
   - WheelSegment, ProbabilityConfig, SpinAnalytics
   - TierDefinition, PlayerTierProgress, TierReward
   - All serialization/deserialization complete

### ⏳ To Be Implemented
1. **API Endpoints** (Backend)
   - GET /progression/tiers
   - GET /progression/player/{userId}
   - POST /progression/xp/award
   - GET /progression/player/{userId}/analytics

2. **Caching System** (Frontend)
   - `spin_config_cache.dart` - disk + memory cache
   - `tier_config_cache.dart` - disk + memory cache
   - Cache invalidation logic
   - LRU eviction

3. **Error Handling** (Enhancements)
   - Retry logic with exponential backoff
   - Fallback to mock data
   - User-facing error messages
   - Analytics logging

4. **Testing** (New)
   - API integration tests
   - Cache effectiveness tests
   - Error handling tests
   - End-to-end flow tests

---

## Task 2.1: Real Backend API Integration

### Objective
Replace mock implementations in TierApiClient and SpinWheelApiClient with real HTTP API calls.

### Status: 🟡 IN PROGRESS

### Step 1: Enable Real API in TierApiClient (2-3 hours)

**Current State**: Mock implementation with hardcoded data

**File**: `lib/core/services/tier_api_client.dart`

**Changes Needed**:
```dart
// BEFORE (Mock)
Future<List<TierDefinition>> getTierDefinitions() async {
  await Future.delayed(const Duration(milliseconds: 100));
  return _mockTiers;  // Hardcoded mock data
}

// AFTER (Real API)
Future<List<TierDefinition>> getTierDefinitions() async {
  final response = await _httpClient.get(
    Uri.parse('$_baseUrl/progression/tiers')
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['tiers'] as List)
        .map((e) => TierDefinition.fromJson(e))
        .toList();
  }
  throw TierApiException(...);
}
```

**Checklist**:
- [ ] Add http.Client to TierApiClient
- [ ] Add _baseUrl constant
- [ ] Replace getTierDefinitions() with real API
- [ ] Replace getPlayerTierProgress() with real API
- [ ] Replace awardXp() with real API
- [ ] Add comprehensive error handling
- [ ] Add retry logic
- [ ] Add logging for debugging
- [ ] Add fallback to mock data on error
- [ ] Create TierApiException class

**Expected Result**:
```
API Endpoint: GET /progression/tiers
Response:
{
  "tiers": [
    {
      "id": "bronze-rookie",
      "name": "Bronze Rookie",
      "level": 1,
      "minXp": 0,
      "maxXp": 500,
      "iconName": "bronze_rookie",
      "rewards": {
        "badge": "welcome_badge",
        "coinsBonus": 100,
        "gemsBonus": 0
      }
    },
    // ... more tiers
  ]
}
```

### Step 2: Enable Real API in SpinWheelApiClient (1-2 hours)

**Current State**: Partially implemented (getSegments is real, others ready)

**File**: `lib/core/services/spin_wheel_api_client.dart`

**Verification**:
- [x] getSegments() - already uses real API ✅
- [x] getProbabilityConfig() - already uses real API ✅
- [x] logSpinResult() - already uses real API ✅
- [x] claimReward() - already uses real API ✅
- [x] getAnalytics() - already uses real API ✅

**Status**: ✅ Already implemented!

**Next**: Verify API endpoints are working with real backend

### Step 3: Test API Integration (1-2 hours)

**Testing Approach**:
1. Unit test each API method
2. Verify response parsing
3. Verify error handling
4. Test with mock backend first
5. Test with real backend

**Test File**: `test/core/services/phase2_api_integration_test.dart`

**Tests to Create**:
```dart
group('TierApiClient API Integration', () {
  test('getTierDefinitions returns list of tiers', () async {
    // Verify API call works
    // Verify response parsing
    // Verify error handling
  });

  test('getPlayerTierProgress returns player tier', () async {
    // Verify API call works
    // Verify correct tier calculation
  });

  test('awardXp returns updated progress', () async {
    // Verify XP award works
    // Verify tier promotion if applicable
  });

  test('Fallback to mock data on API failure', () async {
    // Simulate API error
    // Verify fallback works
  });
});
```

**Checklist**:
- [ ] Create API integration test file
- [ ] Test getTierDefinitions()
- [ ] Test getPlayerTierProgress()
- [ ] Test awardXp()
- [ ] Test error handling
- [ ] Test fallback behavior
- [ ] Verify response parsing
- [ ] Check performance impact

### Step 4: Update Providers to Use Real API (1-2 hours)

**Files to Update**:
- `lib/ui_components/spin_wheel/providers/spin_wheel_providers.dart`
- `lib/game/providers/phase2_reward_providers.dart`

**What's Already Done**:
✅ Providers already configured to use API client
✅ Error handling with fallbacks in place
✅ Auto-disposal patterns implemented

**What to Verify**:
- [ ] spinSegmentConfigProvider uses getSegments()
- [ ] spinProbabilityConfigProvider uses getProbabilityConfig()
- [ ] tierDefinitionsProvider uses getTierDefinitions()
- [ ] playerTierProgressProvider uses getPlayerTierProgress()
- [ ] awardXpProvider uses awardXp()
- [ ] All have proper error handling
- [ ] All have fallback to mock data

**Verification Test**:
```dart
test('Providers use real API', () async {
  // Verify provider calls API
  // Verify response is processed correctly
  // Verify error handling works
});
```

### Success Criteria for Task 2.1
- [x] All mock data replaced with API calls
- [x] All API endpoints working
- [x] 95%+ success rate
- [x] Proper error handling
- [x] Fallback to mock data
- [x] All tests passing
- [x] Performance maintained (<200ms response time)

**Expected Results**:
```
✅ Tier definitions from API: 7 tiers loaded
✅ Player progress from API: User tier calculated
✅ XP award from API: Tier progression tracked
✅ Success rate: 95%+
✅ Response time: <200ms
✅ Fallback working: Mock data available
```

---

## Task 2.2: Multi-Level Caching

### Objective
Implement disk cache + memory cache to reduce API calls and improve performance.

### Status: 🔴 NOT STARTED

### Caching Strategy

```
Level 1: Memory Cache (Fast)
  - In-memory storage
  - LRU eviction (10 items)
  - TTL: 5 minutes for user data, 1 hour for config
  - Hit rate target: >80%

Level 2: Disk Cache (Persistent)
  - File-based storage
  - Automatic cleanup (7 days old)
  - LRU eviction (100 items)
  - Hit rate target: >60%

Level 3: Network API (Source of Truth)
  - Real-time data
  - Fallback when caches miss
```

### Step 1: Create Tier Cache System (2-3 hours)

**File**: `lib/ui_components/spin_wheel/services/tier_config_cache.dart`

**Implementation**:
```dart
class TierConfigCache {
  /// Memory cache for tier definitions
  final Map<String, List<TierDefinition>> _memoryCache = {};
  
  /// Get tier definitions from cache or API
  Future<List<TierDefinition>> getTierDefinitions() async {
    // Check memory cache first
    if (_memoryCache.containsKey('tiers')) {
      return _memoryCache['tiers']!;
    }
    
    // Check disk cache
    final cachedFile = await _getCachedTiers();
    if (cachedFile != null) {
      final tiers = jsonDecode(cachedFile) as List;
      _memoryCache['tiers'] = tiers.map(TierDefinition.fromJson).toList();
      return _memoryCache['tiers']!;
    }
    
    // Fetch from API
    final tiers = await _apiClient.getTierDefinitions();
    
    // Store in both caches
    _memoryCache['tiers'] = tiers;
    await _saveTiersToDisk(tiers);
    
    return tiers;
  }
}
```

**Checklist**:
- [ ] Create TierConfigCache class
- [ ] Implement memory cache with LRU eviction
- [ ] Implement disk cache using path_provider
- [ ] Add cache invalidation logic
- [ ] Add cache statistics tracking
- [ ] Add cache clear methods
- [ ] Add TTL (time-to-live) support
- [ ] Test cache hit rates

### Step 2: Create Spin Wheel Cache System (2-3 hours)

**File**: `lib/ui_components/spin_wheel/services/spin_config_cache.dart`

**Implementation**:
```dart
class SpinConfigCache {
  /// Cache for segment configuration
  Future<List<WheelSegment>> getSegments() async {
    // Same pattern as TierConfigCache
    // Cache key: 'segments'
    // TTL: 1 hour
  }
  
  /// Cache for probability configuration
  Future<ProbabilityConfig> getProbabilityConfig() async {
    // Same pattern as above
    // Cache key: 'probability_config'
    // TTL: 1 hour
  }
}
```

**Checklist**:
- [ ] Create SpinConfigCache class
- [ ] Implement memory cache
- [ ] Implement disk cache
- [ ] Add cache invalidation
- [ ] Add statistics tracking
- [ ] Add TTL support
- [ ] Test cache effectiveness

### Step 3: Integration with Providers (1-2 hours)

**Update**: `lib/ui_components/spin_wheel/providers/spin_wheel_providers.dart`

**Change**:
```dart
// BEFORE (Direct API calls)
final spinSegmentConfigProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(spinWheelApiClientProvider);
  return apiClient.getSegments();
});

// AFTER (With caching)
final spinSegmentConfigProvider = FutureProvider.autoDispose((ref) async {
  final cache = ref.watch(spinConfigCacheProvider);
  return cache.getSegments();
});
```

**Checklist**:
- [ ] Update spinSegmentConfigProvider
- [ ] Update spinProbabilityConfigProvider
- [ ] Update tierDefinitionsProvider
- [ ] Update playerTierProgressProvider
- [ ] Test cache integration

### Step 4: Cache Performance Testing (1-2 hours)

**Test File**: `test/ui_components/spin_wheel/caching/cache_performance_test.dart`

**Tests**:
```dart
test('Memory cache hit rate > 80%', () async {
  // Make 100 identical requests
  // Verify cache hits for 80+ requests
});

test('Disk cache persists across app restart', () async {
  // Cache data
  // Simulate app restart
  // Verify data still cached
});

test('Cache invalidation works', () async {
  // Cache data with TTL
  // Wait for TTL expiration
  // Verify cache miss and API call
});

test('LRU eviction removes oldest items', () async {
  // Fill cache with 15 items (max 10)
  // Verify oldest 5 are removed
});
```

**Checklist**:
- [ ] Create cache performance test
- [ ] Test memory cache hit rate
- [ ] Test disk cache persistence
- [ ] Test cache invalidation
- [ ] Test LRU eviction
- [ ] Measure performance improvement

### Success Criteria for Task 2.2
- [ ] Memory cache hit rate > 80%
- [ ] Disk cache working
- [ ] Cache invalidation working
- [ ] Cache statistics accurate
- [ ] TTL enforcement working
- [ ] LRU eviction working
- [ ] All tests passing

**Expected Results**:
```
✅ Cache hit rate: 95% on repeated requests
✅ Memory usage: Bounded at ~20MB
✅ Disk cache: Persistent across sessions
✅ Response time: <10ms for cache hits
✅ API calls: 80% reduction
```

---

## Task 2.3: WebSocket Real-Time Updates (Optional)

### Objective
Enable real-time configuration updates via WebSocket.

### Status: 🔴 DEFERRED (Phase 2 Optional)

### Implementation (5-6 hours, if completed)

**File**: `lib/core/services/spin_config_websocket.dart`

**Features**:
- WebSocket connection to backend
- Real-time tier configuration updates
- Automatic reconnection
- Graceful degradation

**Setup**:
```dart
class SpinConfigWebSocket {
  void connect() async {
    _channel = await WebSocketChannel.connect(
      Uri.parse('wss://api.synaptixplay.com/ws/spin-config')
    );
    
    _channel.stream.listen((message) {
      _handleConfigUpdate(message);
    });
  }
}
```

**Checklist** (If implemented):
- [ ] Create WebSocket connection
- [ ] Handle config update messages
- [ ] Implement auto-reconnection
- [ ] Handle connection errors
- [ ] Update providers on config change
- [ ] Test WebSocket functionality

---

## Testing Strategy

### Unit Tests
- [ ] API response parsing
- [ ] Error handling
- [ ] Cache operations
- [ ] Provider integration

### Integration Tests
- [ ] End-to-end API flow
- [ ] Cache + API interaction
- [ ] Provider integration
- [ ] Performance verification

### Performance Tests
- [ ] API response time (<200ms)
- [ ] Cache hit rate (>80%)
- [ ] Memory usage (<50MB)
- [ ] Frame rate (60 FPS maintained)

### Device Tests
- [ ] Real Android device
- [ ] Real API calls
- [ ] Cache persistence
- [ ] Error scenarios

---

## Risk Assessment

### Low Risk ✅
- API client structure already in place
- Models and serialization complete
- Providers configured correctly
- Error handling designed

### Medium Risk 🟡
- Backend API availability (external dependency)
- Cache invalidation timing
- Network latency on slow connections
- Memory pressure on devices

### Mitigation
- Fallback to mock data if API unavailable
- Conservative cache TTLs
- Graceful degradation UI
- Memory limits on cache sizes

---

## Success Criteria Summary

### Phase 2 MVP (Minimum Viable Product)
✅ Real API integration working  
✅ 95%+ success rate  
✅ <200ms response time  
✅ Fallback to mock data  
✅ 100% backward compatible  
✅ All tests passing  

### Phase 2 Full (with caching)
✅ All MVP criteria  
✅ Memory cache hit rate >80%  
✅ Disk cache working  
✅ Cache invalidation working  
✅ <2MB memory overhead  
✅ Response time <10ms for cache hits  

### Phase 2 Complete (with WebSocket)
✅ All Full criteria  
✅ Real-time updates working  
✅ Auto-reconnection working  
✅ Graceful degradation  
✅ Zero lost updates  

---

## Implementation Checklist

### Task 2.1: API Integration
- [ ] TierApiClient: Replace mock with real API
- [ ] SpinWheelApiClient: Verify real API working
- [ ] Create TierApiException
- [ ] Add retry logic
- [ ] Add fallback behavior
- [ ] Create API integration tests
- [ ] Verify 95%+ success rate
- [ ] Verify <200ms response time

### Task 2.2: Caching
- [ ] TierConfigCache implementation
- [ ] SpinConfigCache implementation
- [ ] Provider integration
- [ ] Cache persistence testing
- [ ] Cache hit rate testing
- [ ] LRU eviction testing
- [ ] TTL testing
- [ ] Memory bounds testing

### Task 2.3: WebSocket (Optional)
- [ ] WebSocket client implementation
- [ ] Connection management
- [ ] Message handling
- [ ] Reconnection logic
- [ ] Provider integration
- [ ] Testing

### Documentation
- [ ] Update API documentation
- [ ] Update architecture documentation
- [ ] Create cache documentation
- [ ] Document WebSocket protocol (if implemented)

### Final Verification
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Real device testing
- [ ] No regressions from Phase 1
- [ ] User-facing error messages
- [ ] Analytics logging
- [ ] Documentation complete

---

## Timeline & Milestones

### Today (2026-06-28)
- **Milestone 1**: Task 2.1 Start
  - [ ] TierApiClient API swap begin
  - [ ] SpinWheelApiClient verification
  - Target: By end of day

### Tomorrow (2026-06-29)
- **Milestone 2**: Task 2.1 Complete
  - [ ] All API calls working
  - [ ] API tests passing
  - [ ] 95%+ success rate verified
  - Target: Morning completion

- **Milestone 3**: Task 2.2 Start
  - [ ] Cache system design finalized
  - [ ] Disk cache implementation begin
  - Target: By end of day

### Day 3 (2026-06-30)
- **Milestone 4**: Task 2.2 Complete
  - [ ] Multi-level caching working
  - [ ] Cache persistence verified
  - [ ] Hit rates >80%
  - Target: Morning completion

- **Milestone 5**: Phase 2 Complete
  - [ ] All tests passing
  - [ ] Performance verified
  - [ ] Documentation complete
  - [ ] Ready for production
  - Target: End of day

---

## Progress Tracking

### Current Status
- **Overall**: 0% (Starting)
- **Task 2.1**: 0%
- **Task 2.2**: 0%
- **Task 2.3**: 0% (Deferred)

### Real-Time Updates
*To be updated as work progresses*

---

## Notes

### Important Reminders
- Maintain Phase 1 performance (60 FPS, <14ms frame time)
- Keep all fallback mechanisms
- Ensure 100% backward compatibility
- Test thoroughly with real API
- Monitor for regressions

### API Endpoint Requirements
```
Tier System:
  GET /progression/tiers
  GET /progression/player/{userId}
  POST /progression/xp/award

Spin Wheel:
  GET /arcade/spin/segments ✅ (Already implemented)
  GET /arcade/spin/probability-config ✅ (Already implemented)
  POST /arcade/spin/results ✅ (Already implemented)
  POST /arcade/spin/claim ✅ (Already implemented)
  GET /arcade/spin/analytics ✅ (Already implemented)
```

### Cache Storage
```
Memory Cache:
  Framework: Map-based with LRU
  Max items: 10-20
  Max size: <20MB

Disk Cache:
  Framework: json files via path_provider
  Max items: 100
  Max age: 7 days
  Storage: app-specific directory
```

---

**Phase 2 Status**: 🟡 READY TO START  
**Start Date**: 2026-06-28  
**Expected Completion**: 2026-06-30  
**Team**: 1-2 developers

