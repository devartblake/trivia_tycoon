import 'dart:math' as math;
import 'dart:ui' as ui;
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
  final Color? pathGlowColor;
  final Color? haloColor;
  final double strokeWidth;

  // Legacy support for your existing interface
  final List<Offset>? centers;      // in screen-space order (legacy)
  final bool showPath;
  final int? highlightIndex;       // if set, draws ring around this center (legacy)
  final Color ringColor;
  final double thickness;
  final double arrowSize;

  BranchPathOverlayPainter({
    // New interface (preferred)
    this.positionsWorld = const {},
    vmath.Matrix4? worldToScreen,
    this.path = const [],
    this.currentStep = 0,
    this.nodeRadius = 40,
    this.showStepNumbers = false,
    this.pathColor = const Color(0xFF6EE7F9),
    this.pathGlowColor,
    this.haloColor,
    this.strokeWidth = 3.0,

    // Legacy interface (for backward compatibility)
    this.centers,
    this.showPath = true,
    this.highlightIndex,
    this.ringColor = const Color(0xFF6EE7F9),
    this.thickness = 2.0,
    this.arrowSize = 8.0,
  }) : worldToScreen = worldToScreen ?? vmath.Matrix4.identity();

  // Legacy constructor for backward compatibility
  BranchPathOverlayPainter.legacy({
    required List<Offset> centers,
    bool showPath = true,
    int? highlightIndex,
    Color pathColor = const Color(0xFF6EE7F9),
    Color ringColor = const Color(0xFF6EE7F9),
    double thickness = 2.0,
    double arrowSize = 8.0,
  }) : this(
    centers: centers,
    showPath: showPath,
    highlightIndex: highlightIndex,
    pathColor: pathColor,
    ringColor: ringColor,
    thickness: thickness,
    arrowSize: arrowSize,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Use legacy mode if centers is provided
    if (centers != null && centers!.isNotEmpty) {
      _paintLegacyMode(canvas, size);
      return;
    }

    // New mode: use positionsWorld and path
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

    // Glow stroke underneath (if specified)
    if (pathGlowColor != null) {
      final glow = Paint()
        ..color = pathGlowColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(poly, glow);
    }

    // Solid stroke on top
    final main = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(poly, main);

    _paintHalo(canvas);
    _paintStepNumbers(canvas);
  }

  void _paintLegacyMode(Canvas canvas, Size size) {
    if (centers == null || centers!.isEmpty) return;

    if (showPath && centers!.length > 1) {
      final p = Paint()
        ..color = pathColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()..moveTo(centers![0].dx, centers![0].dy);
      for (int i = 1; i < centers!.length; i++) {
        path.lineTo(centers![i].dx, centers![i].dy);
      }
      canvas.drawPath(path, p);

      // little arrows on segments
      for (int i = 1; i < centers!.length; i++) {
        _drawArrow(canvas, centers![i - 1], centers![i], pathColor);
      }
    }

    if (highlightIndex != null &&
        highlightIndex! >= 0 &&
        highlightIndex! < centers!.length) {
      final center = centers![highlightIndex!];
      final ring = Paint()
        ..color = ringColor.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 1;
      canvas.drawCircle(center, 22, ring);
    }
  }

  void _paintHalo(Canvas canvas) {
    if (currentStep < 0 || currentStep >= path.length || haloColor == null) return;
    final id = path[currentStep];
    final world = positionsWorld[id];
    if (world == null) return;
    final p = _w2s(worldToScreen, world);

    // Outer soft halo
    final halo = Paint()
      ..color = haloColor!.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(p, nodeRadius * 1.6, halo);

    // Inner rim
    final rim = Paint()
      ..color = haloColor!
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

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final a1 = angle + math.pi - math.pi / 7;
    final a2 = angle + math.pi + math.pi / 7;

    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final p1 = Offset(
      to.dx + arrowSize * math.cos(a1),
      to.dy + arrowSize * math.sin(a1),
    );
    final p2 = Offset(
      to.dx + arrowSize * math.cos(a2),
      to.dy + arrowSize * math.sin(a2),
    );

    canvas.drawLine(to, p1, p);
    canvas.drawLine(to, p2, p);
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
          old.showStepNumbers != showStepNumbers ||
          old.centers != centers ||
          old.showPath != showPath ||
          old.highlightIndex != highlightIndex ||
          old.ringColor != ringColor ||
          old.thickness != thickness ||
          old.arrowSize != arrowSize;
}