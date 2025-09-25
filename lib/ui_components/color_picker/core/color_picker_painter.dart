import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ColorPickerPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final bool isCircular;

  // Performance optimizations
  static final Map<String, ui.Image?> _imageCache = {};
  final String _cacheKey;

  ColorPickerPainter({
    required this.colors,
    this.strokeWidth = 20.0,
    this.isCircular = true,
  }) : _cacheKey = _generateCacheKey(colors, strokeWidth, isCircular);

  static String _generateCacheKey(List<Color> colors, double strokeWidth, bool isCircular) {
    final colorHash = colors.map((c) => c.value).join('-');
    return '$colorHash-$strokeWidth-$isCircular';
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Try to use cached image first
    final cachedImage = _imageCache[_cacheKey];
    if (cachedImage != null &&
        cachedImage.width == size.width.toInt() &&
        cachedImage.height == size.height.toInt()) {
      canvas.drawImage(cachedImage, Offset.zero, Paint());
      return;
    }

    // Create new image and cache it
    _createAndCacheImage(canvas, size);
  }

  Future<void> _createAndCacheImage(Canvas canvas, Size size) async {
    final recorder = ui.PictureRecorder();
    final recordingCanvas = Canvas(recorder);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isCircular) {
      _drawColorWheel(recordingCanvas, size, paint);
    } else {
      _drawColorGrid(recordingCanvas, size, paint);
    }

    final picture = recorder.endRecording();

    try {
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      _imageCache[_cacheKey] = image;

      // Draw the image immediately
      canvas.drawImage(image, Offset.zero, Paint());

      // Clean up old cache entries if cache gets too large
      if (_imageCache.length > 20) {
        final oldestKey = _imageCache.keys.first;
        _imageCache.remove(oldestKey);
      }
    } catch (e) {
      debugPrint('Error caching color picker image: $e');
      // Fallback to direct drawing
      if (isCircular) {
        _drawColorWheel(canvas, size, paint);
      } else {
        _drawColorGrid(canvas, size, paint);
      }
    } finally {
      picture.dispose();
    }
  }

  void _drawColorWheel(Canvas canvas, Size size, Paint paint) {
    if (colors.isEmpty) return;

    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final angleStep = (2 * pi) / colors.length;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Use path for better performance with many colors
    if (colors.length > 50) {
      for (int i = 0; i < colors.length; i++) {
        final startAngle = i * angleStep;
        paint.color = colors[i];

        final path = Path();
        path.addArc(rect, startAngle, angleStep);
        canvas.drawPath(path, paint);
      }
    } else {
      // Direct arc drawing for smaller color sets
      for (int i = 0; i < colors.length; i++) {
        final startAngle = i * angleStep;
        paint.color = colors[i];

        canvas.drawArc(rect, startAngle, angleStep, false, paint);
      }
    }
  }

  void _drawColorGrid(Canvas canvas, Size size, Paint paint) {
    if (colors.isEmpty) return;

    final rows = (sqrt(colors.length)).ceil();
    final cols = (colors.length / rows).ceil();
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    paint.style = PaintingStyle.fill;

    for (int i = 0; i < colors.length; i++) {
      final x = (i % cols) * cellWidth;
      final y = (i ~/ cols) * cellHeight;
      paint.color = colors[i];

      final rect = Rect.fromLTWH(x, y, cellWidth, cellHeight);
      canvas.drawRect(rect, paint);

      // Add subtle border for better visual separation
      paint.color = Colors.black.withOpacity(0.1);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.5;
      canvas.drawRect(rect, paint);

      // Reset for next color
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(ColorPickerPainter oldDelegate) {
    // More efficient comparison
    if (oldDelegate.colors.length != colors.length ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isCircular != isCircular) {
      return true;
    }

    // Only compare color values if lengths match
    for (int i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i].value != colors[i].value) {
        return true;
      }
    }

    return false;
  }

  @override
  bool shouldRebuildSemantics(ColorPickerPainter oldDelegate) {
    return shouldRepaint(oldDelegate);
  }

  /// Clear the image cache (useful for memory management)
  static void clearCache() {
    for (final image in _imageCache.values) {
      image?.dispose();
    }
    _imageCache.clear();
  }

  /// Get current cache size for debugging
  static int getCacheSize() => _imageCache.length;
}
