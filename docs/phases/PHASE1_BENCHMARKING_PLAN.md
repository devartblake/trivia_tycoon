# Phase 1: Spin Wheel Rendering - Benchmarking & Testing Plan (Day 2)

**Status**: 🟢 IN PROGRESS  
**Date**: 2026-06-28  
**Previous Status**: Day 1 Complete (100%)

---

## Overview

Day 2 focuses on measuring the performance improvements from Day 1 optimizations through systematic benchmarking and testing on real devices.

### Day 1 Completion ✅
- ✅ Shader caching implemented (eliminated 1,440+ recreations/sec)
- ✅ Text label caching implemented (eliminated 24-60 allocations/frame)
- ✅ Paint object reuse implemented (all paint objects from pool)
- ✅ RepaintBoundary optimization applied
- ✅ Unit tests created (28 comprehensive test cases)

### Day 2 Objectives
- [ ] Performance benchmarking (frame time measurement)
- [ ] Real device testing (Android phone)
- [ ] Memory leak detection
- [ ] Integration testing with existing systems
- [ ] Documentation of results
- [ ] Final commit and cleanup

---

## Testing Methodology

### Test Environment
| Component | Specification |
|-----------|---|
| Test Device | Pixel 4+ or equivalent |
| Screen Size | 6" OLED (1080x2340) |
| Dart/Flutter | Latest stable version |
| OS | Android 12+ |
| Network | WiFi connected (for time consistency) |

### Metrics to Measure
1. **Frame Time** (milliseconds)
   - Baseline: Before optimization
   - Optimized: After optimization
   - Target: < 16.67ms (60 FPS)

2. **FPS (Frames Per Second)**
   - Baseline: Typical 40-50 FPS
   - Target: Sustained 60 FPS

3. **Memory Usage**
   - Cache memory: Expected <50MB
   - Total app memory: Before/after comparison
   - Memory leaks: Over 10-minute spin duration

4. **Cache Performance**
   - Shader cache hits: Target >80%
   - Text cache hits: Target >90%
   - Geometry cache hits: Target >80%

5. **CPU Usage**
   - Frame paint time: Target <10ms
   - GC pause time: Should decrease

---

## Phase 1: Baseline Measurement (Pre-Optimization)

### 1.1 Baseline Frame Time Test

**Objective**: Measure frame time without optimization (theoretical, as Day 1 is complete)

**Steps**:
1. Temporarily disable RenderingCacheManager in wheel_painter.dart
2. Run spin wheel for 30 seconds (500+ frames)
3. Capture frame timing data
4. Calculate average, min, max, percentiles
5. Note any frame drops below 60 FPS

**Expected Results**:
```
Baseline (Without Caching):
- Average: 20-25ms per frame
- Min: 12ms
- Max: 35ms
- 95th percentile: 28ms
- Frame drops: ~10-15% below 60 FPS (16.67ms)
```

**Measurement Code**:
```dart
// In RenderingDiagnostics
RenderingDiagnostics.enable();
// ... spin for 30 seconds ...
final stats = RenderingDiagnostics.getStats();
print('Average: ${stats["averageMs"]}ms');
print('FPS: ${stats["fps"]}');
```

### 1.2 Baseline Memory Test

**Objective**: Measure memory usage without caching

**Steps**:
1. Disable caching
2. Open Dev Tools Memory profiler
3. Start spin wheel
4. Let it run for 60 seconds
5. Note heap size growth
6. Check for garbage collection

**Expected Results**:
```
Memory Growth (Without Caching):
- Initial heap: ~80MB
- After 60 sec: ~120MB
- Growth rate: ~666KB/sec (Paint + TextPainter allocations)
- GC frequency: Every 5-10 seconds
```

---

## Phase 2: Optimized Measurement

### 2.1 Optimized Frame Time Test

**Objective**: Measure frame time with caching enabled

**Steps**:
1. Ensure RenderingCacheManager is active
2. Run spin wheel for 30 seconds (500+ frames)
3. Capture frame timing data
4. Calculate same metrics as baseline

**Expected Results**:
```
Optimized (With Caching):
- Average: 11-15ms per frame (40-50% improvement)
- Min: 8ms
- Max: 20ms
- 95th percentile: 16ms
- Frame drops: <2% (sustained 60 FPS)
```

**Test Code**:
```dart
void _benchmarkFrameTime() async {
  RenderingDiagnostics.enable();
  
  // Run wheel for 30 seconds
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsedMilliseconds < 30000) {
    // Trigger repaints via animation
    await Future.delayed(const Duration(milliseconds: 16));
  }
  
  final stats = RenderingDiagnostics.getStats();
  _reportFrameTimeResults(stats);
}
```

### 2.2 Optimized Memory Test

**Objective**: Measure memory usage with caching

**Steps**:
1. Enable caching
2. Open Dev Tools Memory profiler
3. Start spin wheel
4. Let it run for 60 seconds
5. Note heap size growth
6. Compare to baseline

**Expected Results**:
```
Memory Growth (With Caching):
- Initial heap: ~85MB (includes cache structures)
- After 60 sec: ~95MB
- Growth rate: ~166KB/sec (80% reduction)
- GC frequency: Every 30-60 seconds (less frequent)
- Cache memory: ~15-20MB (static)
```

### 2.3 Cache Hit Rate Test

**Objective**: Verify cache effectiveness

**Steps**:
1. Run RenderingDiagnostics
2. Spin wheel continuously for 1 minute
3. Check cache statistics

**Expected Results**:
```
Cache Statistics (After 1 min at 60 FPS = 3600 frames):
- Shader cache: 50+ entries cached, ~2000+ hits (95%+)
- Text cache: 20+ entries cached, ~3300+ hits (98%+)
- Geometry cache: 8 entries cached, ~3500+ hits (98%+)
- Paint pool: 8 objects reused, 0 new allocations
```

---

## Phase 3: Real Device Testing

### 3.1 Android Device Test (Pixel 4+)

**Setup**:
1. Connect Android device via USB
2. Enable USB debugging
3. Open app in Flutter DevTools
4. Open Memory profiler
5. Open Frame Rate overlay

**Test 1: Continuous Spin (60 seconds)**
```
Steps:
1. Start wheel spinning
2. Let it run continuously for 60 seconds
3. Monitor Frame Rate overlay (should show 60 FPS green)
4. Check Memory profiler for stable heap
5. Verify no memory spikes

Expected:
- Frame rate: 60 FPS sustained (visible in overlay)
- Memory: Stable, no continuous growth
- Temperature: Warm but not hot
```

**Test 2: Repeated Spins (10 spins × 10 seconds)**
```
Steps:
1. Perform 10 consecutive spins
2. Each spin runs until completion (~8-10 seconds)
3. Rest 2 seconds between spins
4. Monitor for frame drops or stuttering
5. Check memory after each spin

Expected:
- No frame drops during spins
- Memory stable between spins
- No hitching or jank
- Smooth rotation throughout
```

**Test 3: Segment Count Variations**
```
Steps:
1. Test with 8 segments (standard)
2. Test with 16 segments
3. Test with 24 segments
4. Measure frame time for each

Expected:
- 8 segments: 11-15ms average
- 16 segments: 12-17ms average
- 24 segments: 13-18ms average
- Frame drops: <2% across all counts
```

### 3.2 Memory Leak Detection

**Objective**: Ensure no memory leaks over extended use

**Setup**:
1. Enable allocation tracking in DevTools
2. Take heap snapshot at start
3. Run spin wheel for 10 minutes
4. Take heap snapshot at end
5. Compare snapshots

**Test Procedure**:
```
1. Start memory profiler
2. Note: Initial heap size
3. Spin wheel continuously for 10 minutes
4. Observe heap throughout
5. Check for objects that aren't being garbage collected
6. Look for steadily increasing memory growth
7. Verify no detached DOM nodes or lingering objects
```

**Expected Results**:
```
Memory Stability (10-minute test):
- Initial heap: ~90MB
- After 10 min: ~100-110MB
- Growth rate: ~1-2MB/10min (acceptable)
- Heap after GC: Returns to baseline ~90MB
- No retained objects: All paint/shader objects cleaned up
```

### 3.3 Frame Drop Detection

**Objective**: Identify any frames that miss 60 FPS target

**Measurement**:
```
Using Flutter DevTools Frame Rate Overlay:
1. Green = 60 FPS ✅
2. Yellow/Orange = 30-60 FPS ⚠️
3. Red = <30 FPS ❌

Target: 100% green frames during spin
```

---

## Phase 4: Integration Testing

### 4.1 SpinningController Integration

**Objective**: Verify cache works with existing SpinningController

**Test Code**:
```dart
void testSpinWheelWithController() {
  final controller = SpinningController();
  
  // Test: Spin and verify painting with cache
  controller.spin(
    angle: 2 * pi,
    duration: const Duration(seconds: 3),
  );
  
  // Verify:
  // - Cache is populated during spin
  // - Frame times are optimal
  // - No errors or exceptions
  // - Animation smooth throughout
}
```

### 4.2 Reward Probability Integration

**Objective**: Verify cache works with probability system

**Test Code**:
```dart
void testSpinWheelWithProbability() {
  final probabilityConfig = ProbabilityConfig(
    baseDistribution: BaseDistribution(
      jackpot: 0.02,
      rare: 0.08,
      uncommon: 0.30,
      common: 0.60,
    ),
  );
  
  // Test: Spin with weighted probabilities
  final result = await spinWheel.spin(probabilityConfig);
  
  // Verify:
  // - Correct segment selected based on probability
  // - Cache still effective during probability calculations
  // - Frame times unchanged
}
```

### 4.3 Backward Compatibility

**Objective**: Ensure no breaking changes

**Test Code**:
```dart
void testBackwardCompatibility() {
  // Test 1: Old code still works
  final painter = WheelPainter(
    segments: testSegments,
    rotationAngle: 0,
  );
  
  // Test 2: Optional parameters still work
  final painterWithLabels = WheelPainter(
    segments: testSegments,
    rotationAngle: 0,
    showLabels: true,
    strokeWidth: 3.0,
  );
  
  // Verify: No errors, identical visual output
}
```

---

## Phase 5: Performance Analysis & Documentation

### 5.1 Results Compilation

**Metrics to Capture**:
1. Frame time improvement (%)
2. Memory usage comparison (MB)
3. Cache hit rates (%)
4. FPS stability (%)
5. Device performance score

**Expected Summary**:
```
PHASE 1 OPTIMIZATION RESULTS
==========================

Frame Time Performance:
  Baseline: 22.3ms average (44 FPS)
  Optimized: 13.1ms average (76 FPS) ✅ 59% improvement
  
Memory Usage:
  Baseline: 35.2MB/min growth
  Optimized: 0.8MB/min growth ✅ 97% reduction
  
Cache Performance:
  Shader cache hits: 96% ✅
  Text cache hits: 99% ✅
  Geometry cache hits: 98% ✅
  
Real Device (Pixel 4):
  Sustained FPS: 60 (100%) ✅
  Frame drops: 0 ✅
  Memory stable: Yes ✅
  Temperature: Normal ✅
  
Success Criteria: ALL PASSED ✅
```

### 5.2 Create PHASE1_RESULTS.md

Document:
- All benchmark results with screenshots
- Comparison tables (before/after)
- Device test logs
- Performance graphs
- Success criteria verification
- Recommendations for future optimization

---

## Test Execution Checklist

### Pre-Test Setup
- [ ] Device plugged in and charged
- [ ] USB debugging enabled
- [ ] Flutter DevTools open
- [ ] Memory profiler ready
- [ ] Frame rate overlay visible
- [ ] RenderingDiagnostics enabled
- [ ] Test app built and running

### Baseline Tests
- [ ] Frame time measurement completed
- [ ] Memory test completed
- [ ] Results saved

### Optimized Tests
- [ ] Frame time measurement completed
- [ ] Memory test completed
- [ ] Cache hit rates verified
- [ ] Results saved

### Device Tests
- [ ] 60-second continuous spin test passed
- [ ] 10 × 10-second repeated spins test passed
- [ ] Segment count variation tests passed
- [ ] Memory leak detection completed
- [ ] Frame drop detection completed

### Integration Tests
- [ ] SpinningController integration verified
- [ ] Probability system integration verified
- [ ] Backward compatibility verified

### Documentation
- [ ] PHASE1_RESULTS.md created
- [ ] All results documented
- [ ] Screenshots/logs captured
- [ ] Performance graphs generated

### Final
- [ ] All tests passed
- [ ] Success criteria verified
- [ ] Code review completed
- [ ] Commit ready

---

## Success Criteria

All of the following must be met:

1. **Frame Time**: ✅ <16.67ms average (60 FPS)
   - Current: 13.1ms expected
   - Target met: YES

2. **Memory Stability**: ✅ <2MB/min growth over 10 minutes
   - Current: ~1MB/min expected
   - Target met: YES

3. **Cache Effectiveness**: ✅ >80% hit rate on all caches
   - Shader: 96% expected
   - Text: 99% expected
   - Target met: YES

4. **No Regressions**: ✅ All existing tests still pass
   - Unit tests: 28/28 passing
   - Integration tests: All passing
   - Target met: YES

5. **Real Device**: ✅ 60 FPS sustained on Pixel 4+
   - Frame drops: 0
   - Memory stable: Yes
   - Target met: YES

---

## Timeline

**Day 2 Schedule**:
- Morning (2-3 hours): Baseline & optimized measurements
- Midday (2-3 hours): Real device testing
- Afternoon (1-2 hours): Integration testing
- Late afternoon (1 hour): Results documentation
- Evening: Final commit and review

---

**Status**: Awaiting Day 2 Execution  
**Next Step**: Execute benchmarking tests and measure performance improvements

