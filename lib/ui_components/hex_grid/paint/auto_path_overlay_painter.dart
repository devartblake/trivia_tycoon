import 'package:flutter/material.dart';

/// Lightweight overlay to highlight a recommended path on top of your branch grid.
/// Assumes [centers] = screen-space centers of each node id (already laid out).
class AutoPathOverlayPainter extends CustomPainter {
  final Map<String, Offset> centers; // nodeId -> center (screen-space)
  final List<String> pathIds; // recommended order
  final int currentIndex; // focus index in [pathIds]
  final bool showFullPath; // highlight entire path vs. only current→next

  /// Optional styling
  final Color fullPathColor;
  final double fullPathWidth;
  final Color stepPathColor;
  final double stepPathWidth;
  final Color dimMaskColor; // dim non-path area (if showFullPath==true)

  AutoPathOverlayPainter({
    required this.centers,
    required this.pathIds,
    required this.currentIndex,
    required this.showFullPath,
    this.fullPathColor = const Color(0x66FFFFFF),
    this.fullPathWidth = 2.0,
    this.stepPathColor = const Color(0xFF6EE7F9),
    this.stepPathWidth = 3.0,
    this.dimMaskColor = const Color(0x99000000), // 60% black
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathIds.isEmpty) return;

    // 1) Optionally draw a dim mask, then punch holes along the full path to guide the eye.
    if (showFullPath) {
      final maskPaint = Paint()..color = dimMaskColor;
      final pathStrokeWidth = fullPathWidth + 16; // fat hole around the path

      for (int i = 0; i < pathIds.length - 1; i++) {
        final a = centers[pathIds[i]];
        final b = centers[pathIds[i + 1]];
        if (a == null || b == null) continue;
        final segment = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
        final metrics = segment.computeMetrics().toList();
        if (metrics.isEmpty) continue;

        // Stroke-as-path "hole"
        final stroke = Path();
        for (final m in metrics) {
          stroke.addPath(m.extractPath(0, m.length), Offset.zero);
        }
        final stroked = stroke.shift(Offset.zero);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pathStrokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        // Approximate a "hole" by drawing mask then clearing with destinationOut
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawRect(Offset.zero & size, maskPaint);
        paint.blendMode = BlendMode.clear;
        canvas.drawPath(stroked, paint);
        canvas.restore();
      }
    }

    // 2) Draw full path polyline (subtle)
    if (pathIds.length > 1) {
      final p = Path();
      bool started = false;
      for (int i = 0; i < pathIds.length; i++) {
        final c = centers[pathIds[i]];
        if (c == null) continue;
        if (!started) {
          p.moveTo(c.dx, c.dy);
          started = true;
        } else {
          p.lineTo(c.dx, c.dy);
        }
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fullPathWidth
        ..color = fullPathColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(p, paint);
    }

    // 3) Draw current→next segment (accent)
    if (currentIndex >= 0 && currentIndex < pathIds.length - 1) {
      final a = centers[pathIds[currentIndex]];
      final b = centers[pathIds[currentIndex + 1]];
      if (a != null && b != null) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stepPathWidth
          ..color = stepPathColor
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AutoPathOverlayPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.pathIds != pathIds ||
      oldDelegate.currentIndex != currentIndex ||
      oldDelegate.showFullPath != showFullPath ||
      oldDelegate.fullPathColor != fullPathColor ||
      oldDelegate.fullPathWidth != fullPathWidth ||
      oldDelegate.stepPathColor != stepPathColor ||
      oldDelegate.stepPathWidth != stepPathWidth ||
      oldDelegate.dimMaskColor != dimMaskColor;
}
