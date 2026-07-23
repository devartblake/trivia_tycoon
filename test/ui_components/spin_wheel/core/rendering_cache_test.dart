import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/ui_components/spin_wheel/core/rendering_cache.dart';

void main() {
  group('RenderingCacheManager', () {
    late RenderingCacheManager cacheManager;

    setUp(() {
      cacheManager = RenderingCacheManager();
      cacheManager.clearAll();
    });

    // Shader Caching Tests
    group('Shader Caching', () {
      test('getCachedRadialGradient returns cached shader on second call', () {
        final color = Colors.blue;
        final rect = Rect.fromLTWH(0, 0, 100, 100);

        final shader1 = cacheManager.getCachedRadialGradient(color, rect);
        final shader2 = cacheManager.getCachedRadialGradient(color, rect);

        // Same parameters should return same cached shader (reference equality)
        expect(identical(shader1, shader2), true);
      });

      test('getCachedRadialGradient creates new shader for different colors',
          () {
        final rect = Rect.fromLTWH(0, 0, 100, 100);

        final shader1 = cacheManager.getCachedRadialGradient(Colors.blue, rect);
        final shader2 = cacheManager.getCachedRadialGradient(Colors.red, rect);

        expect(identical(shader1, shader2), false);
      });

      test('getCachedLinearGradient caches gradients correctly', () {
        final begin = Offset.zero;
        final end = const Offset(100, 100);
        final colors = [Colors.blue, Colors.red];

        final shader1 = cacheManager.getCachedLinearGradient(
          begin,
          end,
          colors,
        );
        final shader2 = cacheManager.getCachedLinearGradient(
          begin,
          end,
          colors,
        );

        expect(identical(shader1, shader2), true);
      });

      test('shader cache can be cleared', () {
        final color = Colors.blue;
        final rect = Rect.fromLTWH(0, 0, 100, 100);

        cacheManager.getCachedRadialGradient(color, rect);
        cacheManager.clearShaderCache();

        final stats = cacheManager.getCacheStats();
        expect(stats['shaders'], 0);
      });
    });

    // Paint Caching Tests
    group('Paint Object Reuse', () {
      test('getSegmentFillPaint returns paint object', () {
        final paint1 = cacheManager.getSegmentFillPaint(Colors.blue);
        final paint2 = cacheManager.getSegmentFillPaint(Colors.red);

        // Paint objects should be the same instance (reused from pool)
        expect(identical(paint1, paint2), true);
        // But color should be updated. Paint.color normalises to a plain
        // Color, which no longer == a MaterialColor, so compare by value.
        expect(paint1.color, isSameColorAs(Colors.red));
      });

      test('getSegmentStrokePaint returns cached stroke paint', () {
        final paint1 = cacheManager.getSegmentStrokePaint();
        final paint2 = cacheManager.getSegmentStrokePaint();

        expect(identical(paint1, paint2), true);
      });

      test('getHighlightPaint returns reusable paint', () {
        final paint1 = cacheManager.getHighlightPaint(Colors.white);
        final paint2 = cacheManager.getHighlightPaint(Colors.black);

        expect(identical(paint1, paint2), true);
      });

      test('getBorderPaint returns consistent paint', () {
        final paint1 = cacheManager.getBorderPaint();
        final paint2 = cacheManager.getBorderPaint();

        expect(identical(paint1, paint2), true);
      });

      test('getShadowPaint returns consistent shadow paint', () {
        final paint1 = cacheManager.getShadowPaint();
        final paint2 = cacheManager.getShadowPaint();

        expect(identical(paint1, paint2), true);
      });
    });

    // Text Cache Tests
    group('Text Caching', () {
      test('getCachedTextLabel caches text painters', () {
        const text = 'Test Label';
        const style = TextStyle(fontSize: 12);

        final painter1 = cacheManager.getCachedTextLabel(
          text,
          style: style,
        );
        final painter2 = cacheManager.getCachedTextLabel(
          text,
          style: style,
        );

        expect(identical(painter1, painter2), true);
      });

      test('getCachedTextLabel creates new cache for different text', () {
        const style = TextStyle(fontSize: 12);

        final painter1 = cacheManager.getCachedTextLabel(
          'Text 1',
          style: style,
        );
        final painter2 = cacheManager.getCachedTextLabel(
          'Text 2',
          style: style,
        );

        expect(identical(painter1, painter2), false);
      });

      test('text cache can be cleared', () {
        cacheManager.getCachedTextLabel(
          'Test',
          style: const TextStyle(fontSize: 12),
        );
        cacheManager.clearTextCache();

        final stats = cacheManager.getCacheStats();
        expect(stats['texts'], 0);
      });
    });

    // Geometry Cache Tests
    group('Geometry Caching', () {
      test('getCachedSegmentGeometry caches geometry correctly', () {
        final geom1 = cacheManager.getCachedSegmentGeometry(
          0,
          0,
          100,
          0,
          0.5,
        );
        final geom2 = cacheManager.getCachedSegmentGeometry(
          0,
          0,
          100,
          0,
          0.5,
        );

        expect(identical(geom1, geom2), true);
      });

      test('geometry cache returns correct calculated values', () {
        final geom = cacheManager.getCachedSegmentGeometry(
          50, 50, 100, 0, 1.57, // pi/2
        );

        expect(geom.center, const Offset(50, 50));
        expect(geom.radius, 100);
        expect(geom.startAngle, 0);
        expect(geom.endAngle, 1.57);
      });

      test('geometry cache can be cleared', () {
        cacheManager.getCachedSegmentGeometry(0, 0, 100, 0, 0.5);
        cacheManager.clearGeometryCache();

        final stats = cacheManager.getCacheStats();
        expect(stats['geometries'], 0);
      });
    });

    // Cache Statistics Tests
    group('Cache Statistics', () {
      test('getCacheStats returns accurate counts', () {
        cacheManager.getCachedRadialGradient(Colors.blue, Rect.zero);
        cacheManager.getCachedTextLabel('test', style: const TextStyle());

        final stats = cacheManager.getCacheStats();

        expect(stats['shaders'], greaterThan(0));
        expect(stats['texts'], greaterThan(0));
        expect(stats['geometries'], equals(0));
      });

      test('clearAll resets all cache statistics', () {
        cacheManager.getCachedRadialGradient(Colors.blue, Rect.zero);
        cacheManager.getCachedTextLabel('test', style: const TextStyle());
        cacheManager.getCachedSegmentGeometry(0, 0, 100, 0, 0.5);

        cacheManager.clearAll();

        final stats = cacheManager.getCacheStats();
        expect(stats['shaders'], 0);
        expect(stats['texts'], 0);
        expect(stats['geometries'], 0);
      });
    });
  });

  group('ImageMemoryCache', () {
    late ImageMemoryCache cache;

    setUp(() {
      cache = ImageMemoryCache();
      cache.clearAll();
    });

    test('getImage returns null for uncached images', () {
      final image = cache.getImage('nonexistent');
      expect(image, isNull);
    });

    test('contains returns false for uncached images', () {
      expect(cache.contains('nonexistent'), false);
    });

    test('size returns 0 for empty cache', () {
      expect(cache.size, 0);
    });

    test('clearAll clears the cache', () {
      cache.clearAll();
      expect(cache.size, 0);
    });
  });

  group('WheelGeometryOptimizer', () {
    test('getSegmentAngle calculates correctly', () {
      final angle = WheelGeometryOptimizer.getSegmentAngle(8);
      expect(angle, closeTo(0.785398, 0.001)); // pi/4
    });

    test('getSegmentAngles generates correct count', () {
      final angles = WheelGeometryOptimizer.getSegmentAngles(8);
      expect(angles.length, 8);
    });

    test('getSegmentAtAngle returns correct segment index', () {
      final segmentIndex = WheelGeometryOptimizer.getSegmentAtAngle(0.3, 4);
      expect(segmentIndex, isA<int>());
      expect(segmentIndex, lessThan(4));
    });
  });

  group('CachedSegmentGeometry', () {
    test('getTextRotation returns correct angle', () {
      final geom = CachedSegmentGeometry(
        center: Offset.zero,
        radius: 100,
        startAngle: 0,
        endAngle: 1.57, // pi/2
      );

      final rotation = geom.getTextRotation();
      expect(rotation, isA<double>());
    });

    test('geometry caches all calculated values', () {
      final geom = CachedSegmentGeometry(
        center: const Offset(50, 50),
        radius: 100,
        startAngle: 0,
        endAngle: 1.57,
      );

      expect(geom.path, isNotNull);
      expect(geom.midAngle, isNotNull);
      expect(geom.labelCenter, isNotNull);
      expect(geom.boundingRect, isNotNull);
    });
  });

  group('RenderingDiagnostics', () {
    test('recordFrame stores frame metrics when enabled', () {
      RenderingDiagnostics.enable();
      RenderingDiagnostics.recordFrame(12);
      RenderingDiagnostics.recordFrame(11);

      final stats = RenderingDiagnostics.getStats();
      expect(stats.containsKey('averageMs'), true);
      expect(stats.containsKey('fps'), true);

      RenderingDiagnostics.clear();
    });

    test('recordFrame ignores frames when disabled', () {
      RenderingDiagnostics.disable();
      RenderingDiagnostics.recordFrame(12);

      final stats = RenderingDiagnostics.getStats();
      expect(stats.isEmpty, true);

      RenderingDiagnostics.clear();
    });

    test('getStats returns empty map with no frames recorded', () {
      RenderingDiagnostics.enable();
      RenderingDiagnostics.clear();

      final stats = RenderingDiagnostics.getStats();
      expect(stats.isEmpty, true);
    });
  });
}
