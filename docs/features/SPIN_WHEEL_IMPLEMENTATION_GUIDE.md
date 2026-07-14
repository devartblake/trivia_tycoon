# Spin Wheel Implementation Guide

**Status**: Ready for Phase 1 Implementation  
**Date**: 2026-06-27  
**Priority**: High (Performance + API Integration)

---

## Quick Start

### 1. New Files Created

#### Core Services
```
lib/core/services/spin_wheel_api_client.dart
├── SpinWheelApiClient - Main API client
├── ProbabilityConfig - Server-side configuration model
├── SpinAnalytics - Analytics aggregation model
└── ClaimRewardResponse - Reward claim result
```

#### Performance Optimization
```
lib/ui_components/spin_wheel/core/rendering_cache.dart
├── RenderingCacheManager - Shader & paint caching
├── ImageMemoryCache - LRU image cache
├── CachedSegmentGeometry - Pre-calculated geometry
├── WheelGeometryOptimizer - Geometry calculations
└── RenderingDiagnostics - Performance profiling
```

#### Riverpod Providers
```
lib/ui_components/spin_wheel/providers/spin_wheel_providers.dart
├── spinSegmentConfigProvider - Segment fetching + caching
├── spinProbabilityConfigProvider - Probability configuration
├── activeSpinSegmentsProvider - Filtered enabled segments
├── spinAnalyticsProvider - Analytics aggregation
└── SpinWheelStateNotifier - UI state management
```

---

## Implementation Phases

### Phase 1: Rendering Performance (Days 1-2)

#### Step 1: Update WheelPainter to use RenderingCacheManager

**File**: `lib/ui_components/spin_wheel/core/wheel_painter.dart`

```dart
// OLD: Recreates shader every frame
void _drawSegment(...) {
  final paint = Paint()..style = PaintingStyle.fill..color = segment.color;
  
  if (isActive) {
    paint.shader = RadialGradient(...).createShader(Rect...);  // ❌ EXPENSIVE
  }
}

// NEW: Uses cached shaders
void _drawSegment(...) {
  final paint = RenderingCacheManager().getSegmentFillPaint(segment.color);
  
  if (isActive) {
    paint.shader = RenderingCacheManager().getCachedRadialGradient(
      segment.color,
      bounds,
    );  // ✅ CACHED
  }
}
```

**Changes Needed**:
```diff
+ import '../core/rendering_cache.dart';
  
  class WheelPainter extends CustomPainter {
+   static final RenderingCacheManager _cacheManager = RenderingCacheManager();
    
    void _drawSegment(...) {
-     final paint = Paint()..style = PaintingStyle.fill..color = segment.color;
+     final paint = _cacheManager.getSegmentFillPaint(segment.color);
      
      if (isActive) {
-       paint.shader = RadialGradient(...).createShader(Rect...);
+       paint.shader = _cacheManager.getCachedRadialGradient(
+         segment.color,
+         bounds,
+       );
      }
    }
```

#### Step 2: Optimize Text Rendering

**File**: `lib/ui_components/spin_wheel/core/wheel_painter.dart`

```dart
// OLD: Creates TextPainter every frame
void _drawSegmentLabel(...) {
  final textStyle = TextStyle(...);
  final textSpan = TextSpan(text: label, style: textStyle);
  final textPainter = TextPainter(  // ❌ NEW OBJECT EVERY FRAME
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
}

// NEW: Uses cached text painters
void _drawSegmentLabel(...) {
  final textPainter = _cacheManager.getCachedTextLabel(
    label,
    style: textStyle,
  );  // ✅ CACHED
}
```

#### Step 3: Add RepaintBoundary Optimization

**File**: `lib/ui_components/spin_wheel/ui/widgets/wheel_widget.dart`

```dart
// OLD
@override
Widget build(BuildContext context) {
  return CustomPaint(
    size: Size(widget.size, widget.size),
    painter: _WheelImagePainter(...),
  );
}

// NEW
@override
Widget build(BuildContext context) {
  return RepaintBoundary(  // ✅ PREVENT UNNECESSARY REPAINTS
    child: CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _WheelImagePainter(...),
    ),
  );
}
```

**Expected Performance Improvement**: 60fps sustained, 3-5ms per frame reduction

---

### Phase 2: API Integration (Days 3-4)

#### Step 1: Create API Service

**File**: Already created: `lib/core/services/spin_wheel_api_client.dart`

Just import and use in your services:
```dart
import 'package:synaptix/core/services/spin_wheel_api_client.dart';

final apiClient = SpinWheelApiClient();
final segments = await apiClient.getSegments();
final config = await apiClient.getProbabilityConfig();
```

#### Step 2: Update SegmentLoader to use API

**File**: `lib/ui_components/spin_wheel/services/segment_loader.dart`

```dart
import 'package:synaptix/core/services/spin_wheel_api_client.dart';

class SegmentLoader {
  final SpinWheelApiClient _apiClient;

  SegmentLoader({required SpinWheelApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<WheelSegment>> loadSegments() async {
    try {
      // Use new API client
      final segments = await _apiClient.getSegments();
      return _filterUnlockedSegments(segments);
    } catch (e) {
      // Fallback to local
      return _loadFromLocal();
    }
  }
}
```

#### Step 3: Set up Riverpod Providers

**File**: Already created: `lib/ui_components/spin_wheel/providers/spin_wheel_providers.dart`

Use in your widgets:
```dart
class MySpinWheelWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch active segments (filtered by API)
    final segments = ref.watch(activeSpinSegmentsProvider);
    
    // Watch probability config
    final probConfig = ref.watch(spinProbabilityConfigProvider);
    
    return segments.when(
      data: (segments) => _buildWheel(segments),
      loading: () => _buildSkeleton(),
      error: (e, st) => _buildError(),
    );
  }
}
```

---

### Phase 3: Operator Dashboard Control (Days 5-6)

#### Step 1: Implement Operator API Endpoints

**Backend Implementation** (Node.js/Express):

```javascript
// PUT /api/v1/operator/arcade/spin/segments/:segmentId
router.put('/segments/:segmentId', async (req, res) => {
  const { segmentId } = req.params;
  const { isEnabled, probability, maxWinsPerDay, enabledUntil } = req.body;

  // Validate operator permission
  if (!req.user.isOperator) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // Update segment in database
  const segment = await Segment.findByIdAndUpdate(segmentId, {
    isEnabled,
    probability,
    maxWinsPerDay,
    enabledUntil: enabledUntil ? new Date(enabledUntil) : null,
  });

  // Log change for audit trail
  await AuditLog.create({
    operator: req.user.email,
    action: 'SEGMENT_UPDATE',
    segmentId,
    changes: {
      isEnabled,
      probability,
      maxWinsPerDay,
      enabledUntil,
    },
    timestamp: new Date(),
  });

  // Notify connected clients via WebSocket
  broadcastConfigUpdate({
    type: 'SEGMENT_CHANGED',
    segmentId,
    segment,
  });

  res.json({ status: 'success', segment });
});
```

#### Step 2: Add Claim Verification

**File**: `lib/ui_components/spin_wheel/services/claim_service.dart`

```dart
class SpinRewardClaimService {
  final SpinWheelApiClient _apiClient;

  Future<bool> claimReward({
    required String spinResultId,
    required String segmentId,
    required String userId,
  }) async {
    try {
      // Verify claim server-side
      final response = await _apiClient.claimReward(
        userId: userId,
        spinResultId: spinResultId,
        segmentId: segmentId,
      );

      if (response.success) {
        // Add coins/gems to user account
        // This is handled by the API, but update local state
        return true;
      }
      return false;
    } catch (e) {
      LogManager.error('Failed to claim reward: $e');
      return false;
    }
  }
}
```

---

### Phase 4: Analytics & Monitoring (Days 7-8)

#### Step 1: Log Spin Results

```dart
// In your spin controller
Future<void> _recordSpinResult(SpinResult result) async {
  try {
    // Log to backend for analytics
    await _apiClient.logSpinResult(result);
  } catch (e) {
    // Non-blocking error - analytics failure shouldn't break the spin
    LogManager.error('Failed to log spin result: $e');
  }
}
```

#### Step 2: Monitor Win Rate Variance

```dart
// Use spinAnalyticsProvider to check accuracy
final analytics = await ref.watch(spinAnalyticsProvider.future);

for (final segment in analytics.segmentStats.entries) {
  final variance = segment.value.variance;
  
  // Flag if variance exceeds threshold
  if (variance.abs() > 0.02) {  // ±2%
    LogManager.warning(
      'High variance for segment ${segment.key}: $variance',
    );
  }
}
```

---

## Testing Checklist

### Performance Testing
- [ ] Frame time < 16.67ms during spin (60fps)
- [ ] Memory usage increase < 50MB
- [ ] Shader cache hit rate > 80%
- [ ] Text cache hit rate > 90%

### API Integration Testing
- [ ] Segment loading from API succeeds
- [ ] Fallback to local assets on API failure
- [ ] Probability configuration loads correctly
- [ ] Analytics endpoint responds with valid data

### Operator Control Testing
- [ ] Operator can disable segment via API
- [ ] Probability adjustment takes effect immediately
- [ ] Max wins per day limit enforced
- [ ] Event scheduling works correctly

### Probability Testing
- [ ] Win rate matches expected within ±1%
- [ ] Modifiers calculate correctly
- [ ] Pity timer activates after threshold spins
- [ ] Jackpot cooldown prevents back-to-back wins

---

## Monitoring & Diagnostics

### Enable Performance Diagnostics

```dart
// In your main.dart or init
RenderingDiagnostics.enable();

// Later, check performance
final stats = RenderingDiagnostics.getStats();
print('Average frame time: ${stats['averageMs']}ms');
print('FPS: ${stats['fps']}');
print('Max frame time: ${stats['maxMs']}ms');
```

### Monitor Cache Statistics

```dart
final cacheManager = RenderingCacheManager();
final stats = cacheManager.getCacheStats();
print('Cached shaders: ${stats['shaders']}');
print('Cached text: ${stats['texts']}');
print('Cached geometries: ${stats['geometries']}');
```

### Check Analytics Anomalies

```dart
final analytics = await ref.watch(spinAnalyticsProvider.future);

for (final anomaly in analytics.anomalies) {
  print('Anomaly: ${anomaly.type} - ${anomaly.description}');
}
```

---

## Migration Path

### For Existing Implementations

1. **Keep existing segment loader** - New API client is compatible
2. **Gradually adopt new providers** - Use alongside existing code
3. **Enable caching incrementally** - Test performance improvements
4. **Migrate to operator control** - No breaking changes to client

### Backward Compatibility

All new features are opt-in:
- ✅ Works with existing local segments
- ✅ Works with existing reward system
- ✅ Fallback to local assets if API unavailable
- ✅ No changes required to controller logic

---

## Troubleshooting

### Issue: API segments not loading

**Solution**:
```dart
// Check API client initialization
final apiClient = ref.watch(spinWheelApiClientProvider);

// Verify endpoint URL
const String _baseUrl = 'https://api.synaptixplay.com/api/v1';

// Check network connectivity
try {
  final segments = await apiClient.getSegments();
} catch (e) {
  print('API Error: $e');  // Will show connection errors
}
```

### Issue: Low frame rates

**Solution**:
```dart
// Enable diagnostics
RenderingDiagnostics.enable();
final stats = RenderingDiagnostics.getStats();

// If average > 16.67ms:
// 1. Clear caches: RenderingCacheManager().clearAll()
// 2. Reduce segment count
// 3. Use RepaintBoundary
// 4. Profile with DevTools
```

### Issue: Probability not matching expected

**Solution**:
```dart
// Check current multipliers
final multiplier = await ref.watch(currentProbabilityMultiplierProvider.future);
print('Current multiplier: $multiplier');

// Check analytics
final analytics = await ref.watch(spinAnalyticsProvider.future);
for (final stat in analytics.segmentStats.entries) {
  print('${stat.key}: win rate=${stat.value.winRate}, expected=${stat.value.expectedRate}');
}
```

---

## Next Steps

1. **Review** this implementation guide with your team
2. **Execute** Phase 1 (rendering optimizations)
3. **Test** performance improvements
4. **Proceed** to Phase 2 (API integration)
5. **Deploy** incrementally with monitoring

---

## Performance Target Summary

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Frame Time | < 16.67ms | ~20-25ms | 🔴 Phase 1 |
| Shader Cache Hit Rate | > 80% | 0% | 🔴 Phase 1 |
| Text Cache Hit Rate | > 90% | 0% | 🔴 Phase 1 |
| API Response Time | < 200ms | N/A | 🟡 Phase 2 |
| Probability Accuracy | ± 1% | TBD | 🟡 Phase 2 |
| Memory Overhead | < 50MB | TBD | 🟡 Phase 2 |

---

**Questions?** See `SPIN_WHEEL_ARCHITECTURE_OVERHAUL.md` for detailed architecture.
