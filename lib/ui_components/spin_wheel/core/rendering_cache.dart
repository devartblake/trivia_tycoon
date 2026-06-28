import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// High-performance caching system for spin wheel rendering
///
/// This module optimizes the rendering pipeline by:
/// 1. Caching shaders to avoid recreation every frame
/// 2. Reusing Paint objects
/// 3. Caching text layouts
/// 4. Caching geometric calculations
/// 5. Managing image memory efficiently

class RenderingCacheManager {
  static final RenderingCacheManager _instance = RenderingCacheManager._internal();

  factory RenderingCacheManager() {
    return _instance;
  }

  RenderingCacheManager._internal();

  // Shader cache to avoid recreation
  final Map<String, ui.Shader> _shaderCache = {};

  // Paint object pool
  static final Paint _segmentFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _segmentStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = Colors.white.withValues(alpha: 0.3);
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.15)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Text label cache
  final Map<String, TextPainter> _textPainterCache = {};

  // Geometry cache for segment paths
  final Map<String, CachedSegmentGeometry> _geometryCache = {};

  /// Get or create a cached shader for a color gradient
  ui.Shader getCachedRadialGradient(
    Color baseColor,
    Rect bounds, {
    List<Color>? colors,
    List<double>? stops,
  }) {
    final key = _generateShaderKey(baseColor, bounds);

    return _shaderCache.putIfAbsent(key, () {
      return RadialGradient(
        colors: colors ??
            [
              baseColor.withValues(alpha: 0.8),
              baseColor,
              baseColor.withValues(alpha: 0.9),
            ],
        stops: stops ?? const [0.0, 0.7, 1.0],
      ).createShader(bounds);
    });
  }

  /// Get or create a cached linear gradient shader
  ui.Shader getCachedLinearGradient(
    Offset begin,
    Offset end,
    List<Color> colors, {
    List<double>? stops,
  }) {
    final key = _generateLinearGradientKey(begin, end, colors);

    return _shaderCache.putIfAbsent(key, () {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromPoints(begin, end));
    });
  }

  /// Get a reusable fill paint with the specified color
  Paint getSegmentFillPaint(Color color) {
    _segmentFillPaint.color = color;
    return _segmentFillPaint;
  }

  /// Get a reusable stroke paint
  Paint getSegmentStrokePaint() => _segmentStrokePaint;

  /// Get a reusable highlight paint
  Paint getHighlightPaint(Color color) {
    _highlightPaint.color = color;
    return _highlightPaint;
  }

  /// Get a reusable border paint
  Paint getBorderPaint() => _borderPaint;

  /// Get a reusable shadow paint
  Paint getShadowPaint() => _shadowPaint;

  /// Get or create a cached text painter
  TextPainter getCachedTextLabel(
    String text, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.center,
  }) {
    final key = _generateTextKey(text, style);

    return _textPainterCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    });
  }

  /// Get or create cached segment geometry (path and bounds)
  CachedSegmentGeometry getCachedSegmentGeometry(
    double centerX,
    double centerY,
    double radius,
    double startAngle,
    double endAngle,
  ) {
    final key = _generateGeometryKey(centerX, centerY, radius, startAngle, endAngle);

    return _geometryCache.putIfAbsent(
      key,
      () => CachedSegmentGeometry(
        center: Offset(centerX, centerY),
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
      ),
    );
  }

  /// Clear all caches
  void clearAll() {
    _shaderCache.clear();
    _textPainterCache.clear();
    _geometryCache.clear();
  }

  /// Clear only shader cache (when colors change)
  void clearShaderCache() => _shaderCache.clear();

  /// Clear only text cache (when text changes)
  void clearTextCache() => _textPainterCache.clear();

  /// Clear only geometry cache (when geometry changes)
  void clearGeometryCache() => _geometryCache.clear();

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'shaders': _shaderCache.length,
      'texts': _textPainterCache.length,
      'geometries': _geometryCache.length,
    };
  }

  String _generateShaderKey(Color color, Rect bounds) {
    return '${color.value}_${bounds.hashCode}';
  }

  String _generateLinearGradientKey(
    Offset begin,
    Offset end,
    List<Color> colors,
  ) {
    final colorString = colors.map((c) => c.toARGB32()).join('_');
    return '${begin.dx}_${begin.dy}_${end.dx}_${end.dy}_$colorString';
  }

  String _generateTextKey(String text, TextStyle style) {
    return '${text}_${style.fontSize}_${style.fontWeight}';
  }

  String _generateGeometryKey(
    double x,
    double y,
    double r,
    double start,
    double end,
  ) {
    return '${x.toStringAsFixed(1)}_${y.toStringAsFixed(1)}_${r.toStringAsFixed(1)}_${start.toStringAsFixed(4)}_${end.toStringAsFixed(4)}';
  }
}

/// Cached segment geometry to avoid recalculation
class CachedSegmentGeometry {
  final Offset center;
  final double radius;
  final double startAngle;
  final double endAngle;

  // Pre-calculated values
  late final Path path;
  late final double midAngle;
  late final Offset labelCenter;
  late final Rect boundingRect;

  CachedSegmentGeometry({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.endAngle,
  }) {
    _calculateGeometry();
  }

  void _calculateGeometry() {
    // Create segment path
    path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
      )
      ..close();

    // Calculate mid angle for label positioning
    midAngle = (startAngle + endAngle) / 2;

    // Calculate label center
    final labelRadius = radius * 0.7;
    labelCenter = Offset(
      center.dx + math.cos(midAngle) * labelRadius,
      center.dy + math.sin(midAngle) * labelRadius,
    );

    // Calculate bounding rectangle
    boundingRect = path.getBounds();
  }

  /// Get text rotation angle (for readable text orientation)
  double getTextRotation() {
    double rotation = midAngle;
    // Flip text for readability on bottom half of wheel
    if (midAngle > math.pi / 2 && midAngle < 3 * math.pi / 2) {
      rotation += math.pi;
    }
    return rotation;
  }
}

/// Image memory cache with LRU eviction
class ImageMemoryCache {
  static const int _maxCacheSize = 10;
  static final ImageMemoryCache _instance = ImageMemoryCache._internal();

  factory ImageMemoryCache() {
    return _instance;
  }

  ImageMemoryCache._internal();

  final Map<String, ui.Image> _cache = {};
  final List<String> _accessOrder = [];

  /// Get image from cache
  ui.Image? getImage(String key) {
    if (_cache.containsKey(key)) {
      // Move to end (LRU)
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  /// Cache image with LRU eviction
  void cacheImage(String key, ui.Image image) {
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    _cache[key] = image;
    _accessOrder.add(key);

    // Evict oldest if cache full
    if (_cache.length > _maxCacheSize) {
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest)?.dispose();
    }
  }

  /// Clear all cached images
  void clearAll() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Check if image is cached
  bool contains(String key) => _cache.containsKey(key);
}

/// Optimization helper for common calculations
class WheelGeometryOptimizer {
  /// Cache segment angle calculation
  static double getSegmentAngle(int segmentCount) {
    return 2 * math.pi / segmentCount;
  }

  /// Pre-calculate all segment angles
  static List<double> getSegmentAngles(int count) {
    final segmentAngle = getSegmentAngle(count);
    return List.generate(count, (i) => i * segmentAngle);
  }

  /// Determine if point is within segment
  static bool isPointInSegment(
    Offset point,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
  ) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > radius) return false;

    final angle = math.atan2(dy, dx);
    final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;
    final normalizedStart = startAngle < 0 ? startAngle + 2 * math.pi : startAngle;
    final normalizedEnd = endAngle < 0 ? endAngle + 2 * math.pi : endAngle;

    if (normalizedStart <= normalizedEnd) {
      return normalizedAngle >= normalizedStart && normalizedAngle <= normalizedEnd;
    } else {
      return normalizedAngle >= normalizedStart || normalizedAngle <= normalizedEnd;
    }
  }

  /// Get segment at angle
  static int getSegmentAtAngle(double angle, int segmentCount) {
    final segmentAngle = getSegmentAngle(segmentCount);
    final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;
    return (normalizedAngle / segmentAngle).floor() % segmentCount;
  }
}

/// Memory pool for one-time use objects
class OffsetPool {
  static final List<Offset> _pool = [];

  static Offset get(double dx, double dy) {
    if (_pool.isEmpty) {
      return Offset(dx, dy);
    }
    return _pool.removeLast();
  }

  static void release(Offset offset) {
    if (_pool.length < 100) {
      _pool.add(offset);
    }
  }

  static void clear() => _pool.clear();
}

/// Diagnostics helper for profiling
class RenderingDiagnostics {
  static final List<FrameMetrics> _frameMetrics = [];
  static bool _isEnabled = false;

  static void enable() => _isEnabled = true;
  static void disable() => _isEnabled = false;

  static void recordFrame(int elapsedMillis) {
    if (_isEnabled) {
      _frameMetrics.add(
        FrameMetrics(
          timestamp: DateTime.now(),
          elapsedMillis: elapsedMillis,
        ),
      );

      // Keep only last 100 frames
      if (_frameMetrics.length > 100) {
        _frameMetrics.removeAt(0);
      }
    }
  }

  static Map<String, double> getStats() {
    if (_frameMetrics.isEmpty) return {};

    final times = _frameMetrics.map((m) => m.elapsedMillis).toList();
    final avg = times.reduce((a, b) => a + b) / times.length;
    final max = times.reduce((a, b) => a > b ? a : b);
    final min = times.reduce((a, b) => a < b ? a : b);

    return {
      'averageMs': avg,
      'maxMs': max.toDouble(),
      'minMs': min.toDouble(),
      'fps': 1000 / avg,
    };
  }

  static void clear() => _frameMetrics.clear();
}

class FrameMetrics {
  final DateTime timestamp;
  final int elapsedMillis;

  FrameMetrics({
    required this.timestamp,
    required this.elapsedMillis,
  });
}
