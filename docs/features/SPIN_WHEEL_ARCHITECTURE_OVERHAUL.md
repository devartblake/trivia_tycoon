# Spin Wheel System: Architecture Overhaul & Performance Optimization

**Date**: 2026-06-27  
**Status**: Design Document (Ready for Implementation)  
**Scope**: Performance optimization + API-driven operator control + Backend alignment

---

## 1. Current System Analysis

### 1.1 Performance Bottlenecks

#### High-Impact Issues:
1. **Shader Recreation on Every Paint Cycle** (Critical)
   - `WheelPainter.paint()` recreates RadialGradient shaders for every segment
   - Happens 60+ times per second during animation
   - **Cost**: ~2-5ms per frame on mobile

2. **TextPainter Allocation in Paint Loop** (Critical)
   - `_drawSegmentLabel()` creates new TextPainter for each label per frame
   - Text layout calculated repeatedly even when rotation is the only change
   - **Cost**: ~1-2ms per frame (24+ segments = 50ms+ per frame)

3. **Image Loading Without Caching** (High)
   - Images loaded every time segments change
   - No memory cache or lazy loading strategy
   - Codec instantiation per image per reload

4. **No Repaint Boundary Optimization** (Medium)
   - Multiple CustomPaint widgets trigger full redraw
   - Animations on other elements trigger wheel repaints
   - No dirty region tracking

5. **Recalculation of Constant Values** (Medium)
   - Math calculations (sin, cos, angles) repeated every frame
   - Segment geometry computed without caching
   - No memoization strategy

### 1.2 Current Architecture Limitations

#### API Integration:
- ✅ Segments loaded from API endpoint (`GET /arcade/spin/segments`)
- ❌ Probability calculation fixed and deterministic
- ❌ No operator control for probability adjustment
- ❌ No dynamic event configuration
- ❌ No A/B testing support
- ❌ Reward pool configuration hardcoded

#### Operator Dashboard:
- ❌ No ability to enable/disable rewards in real-time
- ❌ No probability adjustment without deployment
- ❌ No event scheduling support
- ❌ No analytics/telemetry for decision making
- ❌ No temporary promotional changes

#### Backend Alignment:
- Partial: Segments come from API but rewards/probabilities don't
- Limited metadata usage
- No audit trail for configuration changes
- No rate limiting or cooldown API

---

## 2. Proposed Architecture

### 2.1 Three-Layer System

```
┌─────────────────────────────────────────────────────┐
│         UI Layer (Widgets & Animations)             │
│  - RepaintBoundary optimization                     │
│  - Cached shader/paint objects                      │
│  - Lazy component rendering                         │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    Configuration Layer (State & Caching)            │
│  - SpinWheelConfigProvider (Riverpod)               │
│  - Multi-level caching (memory, disk)               │
│  - Change notification stream                       │
│  - Local fallback support                           │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│         API Layer (Backend Services)                │
│  - SpinWheelAPI (segments, config, analytics)       │
│  - OperatorAPI (for dashboard control)              │
│  - ProbabilityEngine (server-side calculation)      │
│  - RateLimitingService                              │
└─────────────────────────────────────────────────────┘
```

### 2.2 Data Flow Architecture

```
┌─────────────────────────────────────────────────────┐
│  Server (Operator Dashboard)                        │
│  - Configure rewards                                │
│  - Adjust probabilities                             │
│  - Schedule events                                  │
│  - View analytics                                   │
└──────────────┬──────────────────────────────────────┘
               │ PUT/POST /spin/config
               ▼
┌──────────────────────────────────────────────────────┐
│  Backend API (Node.js/Express)                      │
│  - /spin/config (GET, PUT)                          │
│  - /spin/events (GET, POST)                         │
│  - /spin/probability (GET, PUT)                     │
│  - /spin/analytics (GET)                            │
│  - /spin/segments (GET)                             │
└──────┬───────────────────────────────────┬──────────┘
       │ Fetch config                       │ Subscribe via
       │ Cache locally                      │ WebSocket
       ▼                                    ▼
┌─────────────────────────────────────────────────────┐
│  Client (Flutter App)                               │
│  - SpinWheelConfigProvider (caches config)          │
│  - EnhancedSpinningController (uses config)         │
│  - Real-time config updates via WebSocket           │
└─────────────────────────────────────────────────────┘
```

---

## 3. API Specification

### 3.1 Segment Configuration Endpoint

```http
GET /api/v1/arcade/spin/segments
Authorization: Bearer <token>

Response: 200 OK
{
  "segments": [
    {
      "id": "seg_001",
      "label": "100 Coins",
      "reward": 100,
      "rewardType": "coins",
      "color": "#FF6B6B",
      "probability": 0.25,
      "isEnabled": true,
      "enabledUntil": "2026-12-31T23:59:59Z",
      "isExclusive": false,
      "requiredStreak": 0,
      "requiredCurrency": 0,
      "maxWinsPerDay": null,
      "maxWinsPerWeek": null,
      "cooldownSeconds": 0,
      "imagePath": "assets/spin_wheel/coin_100.png",
      "description": "Win 100 coins",
      "rarity": "common",
      "metadata": {
        "campaign_id": "summer_2026",
        "event_code": "EVENT_001",
        "trackingTag": "organic"
      }
    },
    {
      "id": "seg_002",
      "label": "500 Gems",
      "reward": 500,
      "rewardType": "gems",
      "color": "#9B59B6",
      "probability": 0.02,
      "isEnabled": true,
      "enabledUntil": null,
      "isExclusive": true,
      "requiredStreak": 5,
      "requiredCurrency": 100,
      "maxWinsPerDay": 1,
      "maxWinsPerWeek": 3,
      "cooldownSeconds": 3600,
      "imagePath": "assets/spin_wheel/gem_500.png",
      "description": "Exclusive gem jackpot",
      "rarity": "legendary",
      "metadata": {
        "jackpot": true,
        "notificationLevel": "celebratory"
      }
    }
  ],
  "config": {
    "version": "1.2.0",
    "lastUpdated": "2026-06-27T10:00:00Z",
    "expiresAt": "2026-06-27T12:00:00Z",
    "cacheControl": {
      "maxAge": 3600,
      "mustRevalidate": false
    }
  }
}
```

### 3.2 Probability Configuration Endpoint

```http
GET /api/v1/arcade/spin/probability-config
Authorization: Bearer <token>

Response: 200 OK
{
  "baseDistribution": {
    "jackpot": 0.02,
    "rare": 0.08,
    "uncommon": 0.30,
    "common": 0.60
  },
  "modifiers": {
    "levelBonus": {
      "enabled": true,
      "multiplier": 0.01,
      "maxBonus": 0.05
    },
    "streakBonus": {
      "enabled": true,
      "multiplier": 0.02,
      "maxBonus": 0.10
    },
    "jackpotCooldown": {
      "enabled": true,
      "hours": 24,
      "reductionFactor": 0.5
    },
    "currencyBonus": {
      "enabled": true,
      "multiplier": 0.15,
      "maxBonus": 0.20
    },
    "pityTimer": {
      "enabled": true,
      "threshold": 50,
      "multiplier": 0.05
    }
  },
  "timeBasedAdjustments": [
    {
      "name": "weekend_boost",
      "days": ["Saturday", "Sunday"],
      "probabilityMultiplier": 1.2,
      "active": true
    },
    {
      "name": "event_promotion",
      "startDate": "2026-06-25T00:00:00Z",
      "endDate": "2026-06-27T23:59:59Z",
      "probabilityMultiplier": 1.5,
      "active": true
    }
  ],
  "version": "2.1.0",
  "lastUpdated": "2026-06-27T10:00:00Z"
}
```

### 3.3 Operator Control Endpoints (Dashboard)

```http
PUT /api/v1/operator/arcade/spin/segments/{segmentId}
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "isEnabled": false,  // Disable jackpot temporarily
  "probability": 0.01, // Adjust probability
  "enabledUntil": "2026-06-30T23:59:59Z",
  "maxWinsPerDay": 0 // Prevent wins during maintenance
}

Response: 200 OK
{
  "status": "success",
  "segmentId": "seg_002",
  "changes": {
    "isEnabled": { "before": true, "after": false },
    "probability": { "before": 0.02, "after": 0.01 },
    "maxWinsPerDay": { "before": 1, "after": 0 }
  },
  "changedAt": "2026-06-27T10:15:00Z",
  "changedBy": "operator@example.com"
}
```

### 3.4 Analytics Endpoint

```http
GET /api/v1/arcade/spin/analytics?period=24h&segmentId=seg_001
Authorization: Bearer <token>

Response: 200 OK
{
  "period": {
    "from": "2026-06-26T10:00:00Z",
    "to": "2026-06-27T10:00:00Z"
  },
  "totalSpins": 5234,
  "segmentStats": {
    "seg_001": {
      "winsCount": 1308,
      "winRate": 0.2498,
      "expectedRate": 0.25,
      "variance": -0.0002,
      "uniquePlayers": 892,
      "avgRewardClaimed": "98.5 coins"
    },
    "seg_002": {
      "winsCount": 105,
      "winRate": 0.0201,
      "expectedRate": 0.02,
      "variance": 0.0001,
      "uniquePlayers": 98,
      "avgRewardClaimed": "498.7 gems"
    }
  },
  "topPerformers": [
    {
      "userId": "user_123",
      "spins": 15,
      "totalReward": 4500
    }
  ],
  "anomalies": [
    {
      "type": "highVariance",
      "segmentId": "seg_003",
      "description": "Win rate 5% higher than expected"
    }
  ]
}
```

---

## 4. Performance Optimization Strategy

### 4.1 Rendering Optimizations

#### 1. Shader Caching
```dart
class _CachedShaderManager {
  static final Map<String, Shader> _shaderCache = {};
  
  static Shader getRadialGradient(Color baseColor, Rect bounds) {
    final key = '${baseColor.value}_${bounds.hashCode}';
    return _shaderCache.putIfAbsent(
      key,
      () => RadialGradient(...).createShader(bounds),
    );
  }
  
  static void clear() => _shaderCache.clear();
}
```

#### 2. Paint Object Reuse
```dart
class _PaintPool {
  static final Paint segmentFill = Paint()..style = PaintingStyle.fill;
  static final Paint segmentStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  
  // Reuse instead of creating new Paint objects
}
```

#### 3. Geometry Caching
```dart
class _SegmentGeometryCache {
  final Map<String, SegmentGeometry> _cache = {};
  
  SegmentGeometry getGeometry(WheelSegment segment, int index, int total) {
    return _cache.putIfAbsent(
      segment.id,
      () => SegmentGeometry.calculate(segment, index, total),
    );
  }
}
```

#### 4. Text Rendering Optimization
```dart
class _TextLabelCache {
  final Map<String, TextPainter> _cache = {};
  
  TextPainter getLabel(String text, TextStyle style) {
    final key = '${text}_${style.fontSize}';
    return _cache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    });
  }
}
```

### 4.2 Memory Optimization

#### Image Caching Strategy
```dart
class _ImageMemoryCache {
  static const int _maxCacheSize = 10; // Limit cached images
  final LinkedHashMap<String, ui.Image> _cache = LinkedHashMap();
  
  Future<ui.Image> getImage(String path) async {
    if (_cache.containsKey(path)) {
      // Move to end (LRU)
      _cache[path] = _cache.remove(path)!;
      return _cache[path]!;
    }
    
    final image = await _loadImage(path);
    _cache[path] = image;
    
    // Evict oldest if cache full
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
    
    return image;
  }
}
```

### 4.3 Riverpod Provider Architecture

```dart
// Segment configuration with caching and fallback
final spinSegmentConfigProvider = FutureProvider.autoDispose<List<WheelSegment>>((ref) async {
  final cache = ref.watch(_spinConfigCacheProvider);
  
  // Try memory cache first
  if (cache.segments != null && !cache.isExpired) {
    return cache.segments!;
  }
  
  // Try remote API
  try {
    final segments = await ref.watch(spinWheelApiProvider).getSegments();
    ref.watch(_spinConfigCacheProvider.notifier).updateSegments(segments);
    return segments;
  } catch (e) {
    // Fallback to local/disk cache
    return ref.watch(_spinConfigCacheProvider).fallbackSegments ?? [];
  }
});

// Probability configuration
final spinProbabilityConfigProvider = FutureProvider.autoDispose<ProbabilityConfig>((ref) async {
  try {
    return await ref.watch(spinWheelApiProvider).getProbabilityConfig();
  } catch (e) {
    return ProbabilityConfig.defaults();
  }
});

// Cached analytics for operator dashboard
final spinAnalyticsProvider = FutureProvider.autoDispose<SpinAnalytics>((ref) async {
  final apiService = ref.watch(spinWheelApiProvider);
  return apiService.getAnalytics(period: '24h');
});
```

---

## 5. Implementation Roadmap

### Phase 1: Performance (Week 1)
- ✅ Implement shader caching
- ✅ Implement paint object reuse
- ✅ Implement geometry caching
- ✅ Implement text label caching
- ✅ Add RepaintBoundary optimization
- **Expected Improvement**: 60fps sustained, 3-5ms per frame reduction

### Phase 2: API Integration (Week 2)
- ✅ Create SpinWheelAPI client
- ✅ Implement multi-level caching (memory + disk)
- ✅ Add WebSocket for real-time updates
- ✅ Implement local fallback strategy
- ✅ Create Riverpod providers for new APIs

### Phase 3: Operator Dashboard (Week 3)
- ✅ Create operator API endpoints
- ✅ Implement segment enable/disable
- ✅ Implement probability adjustment
- ✅ Add event scheduling support
- ✅ Add audit logging

### Phase 4: Analytics & Monitoring (Week 4)
- ✅ Implement analytics collection
- ✅ Add anomaly detection
- ✅ Create operator dashboard UI
- ✅ Add real-time metrics

---

## 6. Backward Compatibility

### Local Fallback Strategy
```dart
class _SpinConfigFallback {
  static Future<List<WheelSegment>> loadLocalSegments() async {
    try {
      // Try local JSON asset
      final raw = await rootBundle.loadString('assets/config/segments.json');
      return (json.decode(raw) as List)
        .map((e) => WheelSegment.fromJson(e))
        .toList();
    } catch (_) {
      return _defaultSegments();
    }
  }
  
  static List<WheelSegment> _defaultSegments() {
    // Built-in defaults
    return const [
      WheelSegment(
        id: 'seg_001',
        label: '100 Coins',
        reward: 100,
        rewardType: 'coins',
        color: Color(0xFFFF6B6B),
        probability: 0.25,
        isEnabled: true,
      ),
      // ... more defaults
    ];
  }
}
```

---

## 7. Testing Strategy

### Performance Testing
```dart
test('wheel painter renders within 5ms', () {
  final sw = Stopwatch()..start();
  // Render 60 frames
  for (int i = 0; i < 60; i++) {
    painter.paint(canvas, size);
  }
  sw.stop();
  
  expect(sw.elapsedMilliseconds, lessThan(300)); // ~5ms per frame
});
```

### API Integration Testing
```dart
test('spin config fetches and caches correctly', () async {
  final segments = await spinSegmentConfigProvider.getSegments();
  expect(segments, isNotEmpty);
  
  // Second call should be cached
  final segments2 = await spinSegmentConfigProvider.getSegments();
  expect(identical(segments, segments2), true);
});
```

---

## 8. Monitoring & Metrics

### Key Metrics to Track
- Frame time (target: <16.67ms for 60fps)
- Cache hit rate (target: >80%)
- API latency (target: <200ms for config)
- Memory usage (target: <50MB additional)
- Win rate variance (target: within ±2%)

### Operator Dashboard Telemetry
```json
{
  "timestamp": "2026-06-27T10:00:00Z",
  "metrics": {
    "frameTimeMs": 11.2,
    "cacheHitRate": 0.92,
    "apiLatencyMs": 145,
    "memoryMB": 42.5,
    "winRateVariance": -0.001
  }
}
```

---

## 9. Risk Assessment

### Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| API unavailability | High | Local fallback + offline mode |
| Configuration cache staleness | Medium | Automatic refresh + WebSocket |
| Memory leak from caching | High | LRU eviction + cleanup |
| Frame drops during config load | Medium | Async loading + skeleton UI |
| Probability distribution errors | Critical | Server-side validation + tests |

---

## 10. Success Criteria

- ✅ 60fps sustained on mobile devices
- ✅ Probability distribution matches expected values (±1%)
- ✅ Operator dashboard can change config in <2 seconds
- ✅ Real-time config updates propagate in <5 seconds
- ✅ 95% API success rate with graceful fallback
- ✅ Analytics accuracy within ±0.5%
- ✅ Zero breaking changes for existing implementations

---

**Next Steps**: Review this architecture, approve API spec, and proceed with Phase 1 implementation.
