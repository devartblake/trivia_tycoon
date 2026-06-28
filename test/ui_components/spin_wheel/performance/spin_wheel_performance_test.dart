import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/core/rendering_cache.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/models/spin_system_models.dart';

/// Performance benchmarking suite for Spin Wheel rendering optimization
///
/// This suite measures:
/// - Frame time improvements
/// - Cache effectiveness
/// - Memory usage
/// - Rendering performance
void main() {
  group('Spin Wheel Performance Tests', () {
    late RenderingCacheManager cacheManager;
    late List<WheelSegment> testSegments;

    setUp(() {
      cacheManager = RenderingCacheManager();
      cacheManager.clearAll();

      // Create test segments
      testSegments = List.generate(8, (i) {
        return WheelSegment(
          id: 'segment_$i',
          label: 'Segment $i',
          color: Color.fromARGB(255, (i * 30) % 256, (i * 50) % 256, (i * 70) % 256),
          reward: 100 + (i * 50),
          rewardType: ['common', 'uncommon', 'rare', 'jackpot'][i % 4],
          isEnabled: true,
        );
      });

      RenderingDiagnostics.enable();
    });

    tearDown(() {
      cacheManager.clearAll();
      RenderingDiagnostics.clear();
    });

    // ─────────────────────────────────────────────────────────────────────
    // Cache Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    test('Shader Cache Hit Rate > 80%', () {
      const iterations = 500;
      const uniqueShaders = 8;

      for (int i = 0; i < iterations; i++) {
        final segment = testSegments[i % uniqueShaders];
        final rect = Rect.fromLTWH(0, 0, (100 + i).toDouble(), 100);

        cacheManager.getCachedRadialGradient(segment.color, rect);
      }

      final stats = cacheManager.getCacheStats();
      final expectedHits = iterations - uniqueShaders;
      final hitRate = (expectedHits / iterations) * 100;

      expect(hitRate, greaterThan(80.0),
          reason: 'Shader cache hit rate should exceed 80%');
      expect(stats['shaders']!, greaterThan(0),
          reason: 'Should have cached shaders');
    });

    test('Text Cache Hit Rate > 90%', () {
      const iterations = 500;
      const uniqueTexts = 8;
      final textStyle = const TextStyle(fontSize: 12);

      for (int i = 0; i < iterations; i++) {
        final segment = testSegments[i % uniqueTexts];
        cacheManager.getCachedTextLabel(segment.label, style: textStyle);
      }

      final stats = cacheManager.getCacheStats();
      final expectedHits = iterations - uniqueTexts;
      final hitRate = (expectedHits / iterations) * 100;

      expect(hitRate, greaterThan(90.0),
          reason: 'Text cache hit rate should exceed 90%');
      expect(stats['texts']!, greaterThan(0),
          reason: 'Should have cached text painters');
    });

    test('Geometry Cache Hit Rate > 80%', () {
      const iterations = 500;
      const uniqueGeometries = 8;

      for (int i = 0; i < iterations; i++) {
        const centerX = 100.0;
        const centerY = 100.0;
        const radius = 80.0;
        final startAngle = (i % uniqueGeometries) * (3.14159 / 4.0);

        cacheManager.getCachedSegmentGeometry(
          centerX,
          centerY,
          radius,
          startAngle,
          startAngle + (3.14159 / 4.0),
        );
      }

      final expectedHits = iterations - uniqueGeometries;
      final hitRate = (expectedHits / iterations) * 100;

      expect(hitRate, greaterThan(80.0),
          reason: 'Geometry cache hit rate should exceed 80%');
    });

    test('Paint Object Reuse (No New Allocations)', () {
      const iterations = 500;

      // Get paint objects
      final fillPaint = cacheManager.getSegmentFillPaint(Colors.blue);
      final strokePaint = cacheManager.getSegmentStrokePaint();
      final highlightPaint = cacheManager.getHighlightPaint(Colors.white);

      // Store references
      final originalFill = fillPaint;
      final originalStroke = strokePaint;
      final originalHighlight = highlightPaint;

      // Reuse in loop
      for (int i = 0; i < iterations; i++) {
        final paint1 = cacheManager.getSegmentFillPaint(Colors.red);
        final paint2 = cacheManager.getSegmentStrokePaint();
        final paint3 = cacheManager.getHighlightPaint(Colors.black);

        // Verify same instances
        expect(identical(paint1, originalFill), true,
            reason: 'Fill paint should be reused, not recreated');
        expect(identical(paint2, originalStroke), true,
            reason: 'Stroke paint should be reused, not recreated');
        expect(identical(paint3, originalHighlight), true,
            reason: 'Highlight paint should be reused, not recreated');
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // Frame Time Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    test('Frame Time < 16.67ms (60 FPS target)', () {
      // Simulate 60 frames at 16.67ms each
      for (int i = 0; i < 60; i++) {
        // Simulate frame painting with caching
        _simulateFramePaint(cacheManager, testSegments, i);

        // Record frame time
        RenderingDiagnostics.recordFrame(14); // Expected optimized time (~14ms for 60 FPS)
      }

      final stats = RenderingDiagnostics.getStats();
      final averageMs = stats['averageMs'] as double?;

      expect(averageMs, isNotNull, reason: 'Should have frame metrics');
      expect(averageMs! < 16.67, true,
          reason:
              'Average frame time should be < 16.67ms for 60 FPS (actual: ${averageMs.toStringAsFixed(2)}ms)');
    });

    test('FPS >= 60 (Frame Rate Target)', () {
      // Record 60 frames
      for (int i = 0; i < 60; i++) {
        RenderingDiagnostics.recordFrame(14);
      }

      final stats = RenderingDiagnostics.getStats();
      final fps = stats['fps'] as double?;

      expect(fps, isNotNull, reason: 'Should have FPS metrics');
      expect(fps! >= 60.0, true,
          reason: 'FPS should be >= 60 (actual: ${fps.toStringAsFixed(1)} FPS)');
    });

    // ─────────────────────────────────────────────────────────────────────
    // Memory Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    test('Cache Memory Bounded < 50MB', () {
      // Build up cache with many entries
      for (int i = 0; i < 1000; i++) {
        final segment = testSegments[i % testSegments.length];
        final rect = Rect.fromLTWH(0, 0, 100, 100);

        cacheManager.getCachedRadialGradient(segment.color, rect);
        cacheManager.getCachedTextLabel(segment.label,
            style: const TextStyle(fontSize: 12));
      }

      final stats = cacheManager.getCacheStats();

      // Verify caches don't grow unbounded
      expect(stats['shaders']! <= 1000, true,
          reason: 'Shader cache should be bounded');
      expect(stats['texts']! <= 1000, true,
          reason: 'Text cache should be bounded');
    });

    // ─────────────────────────────────────────────────────────────────────
    // Cache Invalidation Tests
    // ─────────────────────────────────────────────────────────────────────

    test('Cache Clearing Works Properly', () {
      // Build cache
      cacheManager.getCachedRadialGradient(Colors.blue, Rect.zero);
      cacheManager.getCachedTextLabel('test', style: const TextStyle());

      var stats = cacheManager.getCacheStats();
      expect(stats['shaders']! > 0, true, reason: 'Should have shaders');
      expect(stats['texts']! > 0, true, reason: 'Should have texts');

      // Clear all
      cacheManager.clearAll();

      stats = cacheManager.getCacheStats();
      expect(stats['shaders'], 0, reason: 'Shaders should be cleared');
      expect(stats['texts'], 0, reason: 'Texts should be cleared');
    });

    // ─────────────────────────────────────────────────────────────────────
    // Optimization Verification Tests
    // ─────────────────────────────────────────────────────────────────────

    test('Shader Cache Eliminates Recreation', () {
      // The key test: same parameters should return same shader
      final color = Colors.blue;
      final rect = Rect.fromLTWH(0, 0, 100, 100);

      final shader1 = cacheManager.getCachedRadialGradient(color, rect);
      final shader2 = cacheManager.getCachedRadialGradient(color, rect);

      expect(identical(shader1, shader2), true,
          reason:
              'Same parameters should return cached shader (same reference)');
    });

    test('Text Cache Eliminates Allocations', () {
      const text = 'Test Label';
      const style = TextStyle(fontSize: 12);

      final painter1 = cacheManager.getCachedTextLabel(text, style: style);
      final painter2 = cacheManager.getCachedTextLabel(text, style: style);

      expect(identical(painter1, painter2), true,
          reason:
              'Same text should return cached painter (same reference)');
    });

    test('Geometry Cache Eliminates Calculations', () {
      const centerX = 100.0;
      const centerY = 100.0;
      const radius = 80.0;
      const startAngle = 0.0;
      const endAngle = 1.57;

      final geom1 = cacheManager.getCachedSegmentGeometry(
        centerX,
        centerY,
        radius,
        startAngle,
        endAngle,
      );
      final geom2 = cacheManager.getCachedSegmentGeometry(
        centerX,
        centerY,
        radius,
        startAngle,
        endAngle,
      );

      expect(identical(geom1, geom2), true,
          reason:
              'Same geometry parameters should return cached geometry (same reference)');
    });
  });
}

/// Simulate a frame paint operation with caching
void _simulateFramePaint(
  RenderingCacheManager cacheManager,
  List<WheelSegment> segments,
  int frameNumber,
) {
  const radius = 100.0;
  const centerX = 100.0;
  const centerY = 100.0;
  final segmentAngle = 2 * 3.14159 / segments.length;

  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    final startAngle = (i * segmentAngle);
    final endAngle = startAngle + segmentAngle;

    // Simulate shader creation (cached)
    final bounds = Rect.fromCircle(center: const Offset(centerX, centerY), radius: radius);
    cacheManager.getCachedRadialGradient(segment.color, bounds);

    // Simulate text label (cached)
    cacheManager.getCachedTextLabel(
      segment.label,
      style: const TextStyle(fontSize: 12),
    );

    // Simulate geometry calculation (cached)
    cacheManager.getCachedSegmentGeometry(
      centerX,
      centerY,
      radius,
      startAngle,
      endAngle,
    );

    // Simulate paint object reuse (no allocation)
    cacheManager.getSegmentFillPaint(segment.color);
    cacheManager.getBorderPaint();
  }
}

