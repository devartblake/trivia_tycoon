import 'package:flutter/material.dart';

/// Lightweight overlay to highlight a recommended path on top of your branch grid.
/// Assumes [centers] = screen-space centers of each node id (already laid out).
class AutoPathOverlayPainter extends CustomPainter {
  final Map<String, Offset> centers; // nodeId -> center (screen-space)
  final List<String> pathIds; // recommended order
  final int currentIndex; // focus index in [pathIds]
  final bool showFullPath; // highlight entire path vs. only current→next
  final bool showDimMask; // dim non-path area when showing the full path

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
    this.showDimMask = true,
    this.fullPathColor = const Color(0x66FFFFFF),
    this.fullPathWidth = 2.0,
    this.stepPathColor = const Color(0xFF6EE7F9),
    this.stepPathWidth = 3.0,
    this.dimMaskColor = const Color(0x99000000), // 60% black
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathIds.isEmpty) return;

    final visiblePoints = <Offset>[
      for (final id in pathIds)
        if (centers[id] != null) centers[id]!,
    ];
    if (visiblePoints.isEmpty) return;

    final fullPath = _buildPath(visiblePoints);

    // 1) Optionally draw a dim mask, then punch one combined hole along the path.
    if (showFullPath &&
        showDimMask &&
        dimMaskColor.alpha > 0 &&
        fullPath != null) {
      final layerBounds = Offset.zero & size;
      final maskPaint = Paint()..color = dimMaskColor;
      final clearPaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = fullPathWidth + 16 // fat hole around the path
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.saveLayer(layerBounds, Paint());
      canvas.drawRect(layerBounds, maskPaint);
      canvas.drawPath(fullPath!, clearPaint);
      canvas.restore();
    }

    // 2) Draw full path polyline (subtle)
    if (fullPath != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fullPathWidth
        ..color = fullPathColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(fullPath, paint);
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

  Path? _buildPath(List<Offset> points) {
    if (points.length < 2) return null;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant AutoPathOverlayPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.pathIds != pathIds ||
      oldDelegate.currentIndex != currentIndex ||
      oldDelegate.showFullPath != showFullPath ||
      oldDelegate.showDimMask != showDimMask ||
      oldDelegate.fullPathColor != fullPathColor ||
      oldDelegate.fullPathWidth != fullPathWidth ||
      oldDelegate.stepPathColor != stepPathColor ||
      oldDelegate.stepPathWidth != stepPathWidth ||
      oldDelegate.dimMaskColor != dimMaskColor;
}
