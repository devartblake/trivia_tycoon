import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Draws a highlighted path over the branch graph:
/// - Connects nodes in `path` order
/// - Glowing stroke for the full path
/// - Halo around the currentStep node
/// - (optional) step numbers
class BranchPathOverlayPainter extends CustomPainter {
  final Map<String, Offset> positionsWorld; // nodeId -> world/layout coords
  final vmath.Matrix4 worldToScreen;
  final List<String> path;                  // ordered node ids
  final int currentStep;                    // index inside `path` (0-based)
  final double nodeRadius;
  final bool showStepNumbers;

  final Color pathColor;
  final Color pathGlowColor;
  final Color haloColor;
  final double strokeWidth;

  BranchPathOverlayPainter({
    required this.positionsWorld,
    required this.worldToScreen,
    required this.path,
    required this.currentStep,
    this.nodeRadius = 40,
    this.showStepNumbers = false,
    this.pathColor = const Color(0xFF6EE7F9),
    this.pathGlowColor = const Color(0x806EE7F9), // translucent glow
    this.haloColor = const Color(0xFFFFC857),
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    // Convert ordered world points to screen points
    final pts = <Offset>[];
    for (final id in path) {
      final world = positionsWorld[id];
      if (world == null) continue;
      pts.add(_w2s(worldToScreen, world));
    }
    if (pts.length < 2) {
      // Even with a 1-node path, show halo
      _paintHalo(canvas);
      _paintStepNumbers(canvas);
      return;
    }

    // Build a polyline path
    final poly = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      poly.lineTo(pts[i].dx, pts[i].dy);
    }

    // Glow stroke underneath
    final glow = Paint()
      ..color = pathGlowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Solid stroke on top
    final main = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(poly, glow);
    canvas.drawPath(poly, main);

    _paintHalo(canvas);
    _paintStepNumbers(canvas);
  }

  void _paintHalo(Canvas canvas) {
    if (currentStep < 0 || currentStep >= path.length) return;
    final id = path[currentStep];
    final world = positionsWorld[id];
    if (world == null) return;
    final p = _w2s(worldToScreen, world);

    // Outer soft halo
    final halo = Paint()
      ..color = haloColor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(p, nodeRadius * 1.6, halo);

    // Inner rim
    final rim = Paint()
      ..color = haloColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(p, nodeRadius * 1.4, rim);
  }

  void _paintStepNumbers(Canvas canvas) {
    if (!showStepNumbers) return;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < path.length; i++) {
      final world = positionsWorld[path[i]];
      if (world == null) continue;
      final p = _w2s(worldToScreen, world);
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: 40);
      final off = Offset(p.dx - tp.width / 2, p.dy - nodeRadius - 10 - tp.height);
      tp.paint(canvas, off);
    }
  }

  Offset _w2s(vmath.Matrix4 m, Offset world) {
    final v = m.transform3(vmath.Vector3(world.dx, world.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  @override
  bool shouldRepaint(covariant BranchPathOverlayPainter old) =>
      old.positionsWorld != positionsWorld ||
          old.worldToScreen != worldToScreen ||
          old.path != path ||
          old.currentStep != currentStep ||
          old.nodeRadius != nodeRadius ||
          old.pathColor != pathColor ||
          old.pathGlowColor != pathGlowColor ||
          old.haloColor != haloColor ||
          old.strokeWidth != strokeWidth ||
          old.showStepNumbers != showStepNumbers;
}
