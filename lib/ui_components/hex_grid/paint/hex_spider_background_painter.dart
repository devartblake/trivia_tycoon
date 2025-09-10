// lib/ui_components/hex_grid/paint/hex_spider_background_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../core/theme/hex_spider_theme.dart';
import '../math/hex_metrics.dart';
import '../math/hex_orientation.dart';

class HexSpiderBackgroundPainter extends CustomPainter {
  final int ringCount;
  final double ringSpacing;
  final int rayCount;
  final double hexRadius;
  final HexOrientation orientation;

  /// Current InteractiveViewer scale (used to fade background)
  final double scale;

  /// Align the guide grid to actual node positions (if present)
  final bool alignToNodes;
  final vmath.Matrix4? worldToScreen;
  final Map<String, Offset>? positions; // nodeId -> world(=layout) coordinates

  /// Theme with brand/flag palettes etc.
  final HexSpiderTheme theme;

  /// Kept for backward compatibility
  final Color gridColor;
  final Color ringColor;
  final Color rayColor;
  final double baseGridAlpha; // 0..1 opacity multiplier
  final double baseRingAlpha;
  final double baseRayAlpha;

  HexSpiderBackgroundPainter({
    this.ringCount = 6,
    this.ringSpacing = 140,
    this.rayCount = 20,
    this.hexRadius = 48,
    this.orientation = HexOrientation.pointy,
    this.scale = 1.0,
    this.alignToNodes = false,
    this.worldToScreen,
    this.positions,
    this.theme = HexSpiderTheme.neon,
    this.gridColor = const Color(0x22FFFFFF),
    this.ringColor = const Color(0x33FFFFFF),
    this.rayColor = const Color(0x22FFFFFF),
    this.baseGridAlpha = 1.0,
    this.baseRingAlpha = 0.75,
    this.baseRayAlpha = 0.65,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = paletteFor(theme);

    // Fade factors with scale: zoom-in => lines become subtler (scale ~0.5..2.5)
    final t = _clamp((scale - 1.0) / (2.5 - 1.0), 0, 1);
    final gridAlpha = _lerp(baseGridAlpha, 0.15, t);
    final ringAlpha = _lerp(baseRingAlpha, 0.20, t);
    final rayAlpha  = _lerp(baseRayAlpha,  0.18, t);

    // Compute origin: center, or align to a reference node transformed to screen
    Offset origin = size.center(Offset.zero);
    if (alignToNodes && worldToScreen != null && positions != null && positions!.isNotEmpty) {
      final anchorWorld = _chooseAnchor(positions!);
      origin = _transformPoint(worldToScreen!, anchorWorld);
    }

    // 1) Hex guide grid (a few rings around center)
    final paintHex = Paint()
      ..color = gridColor.withOpacity(gridAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final tileSize = HexMetrics.tileSize(hexRadius, orientation);
    // Draw a limited disc of axial cells around 0,0
    final radiusCells = (ringSpacing * ringCount / (tileSize.height / 2)).ceil() + 2;

    for (int q = -radiusCells; q <= radiusCells; q++) {
      final r1 = math.max(-radiusCells, -q - radiusCells);
      final r2 = math.min(radiusCells, -q + radiusCells);
      for (int r = r1; r <= r2; r++) {
        final c = HexMetrics.axialToPixel(q, r, hexRadius, orientation);
        final rect = Rect.fromCenter(center: origin + c, width: tileSize.width, height: tileSize.height);
        final path = HexMetrics.pathInRect(rect, orientation);
        canvas.drawPath(path, paintHex);
      }
    }

    // Build safe gradients (colors + stops lengths always match)
    final rayColors = _safeColors(
      // palette.rayGradient is expected to exist; fallback to two-color rayColor gradient
      _tryGetColors(palette, 'rayGradient'),
      fallback: [rayColor.withOpacity(rayAlpha), rayColor.withOpacity(0)],
    );
    final rayStops  = _evenStops(rayColors.length);

    final ringColors = _safeColors(
      // Prefer ringGradient if present; else reuse rayGradient; else fallback to ringColor fade
      _tryGetColors(palette, 'ringGradient') ?? _tryGetColors(palette, 'rayGradient'),
      fallback: [
        ringColor.withOpacity(ringAlpha),
        ringColor.withOpacity(ringAlpha * 0.6),
        ringColor.withOpacity(0),
      ],
    );
    final ringStops  = _evenStops(ringColors.length);

    /// 2) Radial rays (with soft gradient along length)
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * (2 * math.pi);
      final end = Offset(
        origin.dx + ringCount * ringSpacing * math.cos(angle),
        origin.dy + ringCount * ringSpacing * math.sin(angle),
      );
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          colors: rayColors,
          stops: rayStops,
        ).createShader(Rect.fromPoints(origin, end));
      canvas.drawLine(origin, end, rayPaint);
    }

    // 3) Concentric rings (radial gradient)
    for (int i = 1; i <= ringCount; i++) {
      final radius = i * ringSpacing;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = RadialGradient(
          colors: ringColors,
          stops: ringStops,
          center: Alignment.center,
          radius: 1.0,
        ).createShader(Rect.fromCircle(center: origin, radius: radius));
      canvas.drawCircle(origin, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HexSpiderBackgroundPainter old) =>
      old.ringCount != ringCount ||
          old.ringSpacing != ringSpacing ||
          old.rayCount != rayCount ||
          old.hexRadius != hexRadius ||
          old.orientation != orientation ||
          old.scale != scale ||
          old.alignToNodes != alignToNodes ||
          old.worldToScreen != worldToScreen ||
          old.positions != positions ||
          old.theme != theme ||
          old.gridColor != gridColor ||
          old.ringColor != ringColor ||
          old.rayColor != rayColor ||
          old.baseGridAlpha != baseGridAlpha ||
          old.baseRingAlpha != baseRingAlpha ||
          old.baseRayAlpha != baseRayAlpha;

  // ---- helpers ----
  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  Offset _chooseAnchor(Map<String, Offset> pos) {
    // Prefer a root-like node id if present; else average center
    const preferred = ['root', 'core', 'center'];
    for (final id in preferred) {
      final p = pos[id];
      if (p != null) return p;
    }
    // average
    double x = 0, y = 0;
    for (final p in pos.values) {
      x += p.dx; y += p.dy;
    }
    final n = pos.length;
    return Offset(x / n, y / n);
  }

  double _clamp(double v, double min, double max) => v < min ? min : (v > max ? max : v);
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // Ensures we always return a non-empty list of Colors
  List<Color> _safeColors(List<Color>? maybe, {required List<Color> fallback}) {
    if (maybe == null || maybe.isEmpty) return fallback;
    return maybe;
  }

  // Generates evenly spaced stops for N colors
  List<double> _evenStops(int n) {
    if (n <= 1) return const [1.0];
    return List<double>.generate(n, (i) => i / (n - 1));
  }

  // Tries to read a List<Color> field from palette (dynamic) safely.
  // Replace the old _tryGetColors with this version
  List<Color>? _tryGetColors(Object palette, String field) {
    try {
      // If palette is a simple map-like structure
      if (palette is Map<String, List<Color>>) {
        return palette[field];
      }

      // If palette is a class with properties/getters
      final dyn = palette as dynamic; // ignore: avoid_dynamic_calls
      if (field == 'rayGradient') {
        final v = dyn.rayGradient;
        if (v is List<Color>) return v;
      }
      if (field == 'ringGradient') {
        final v = dyn.ringGradient;
        if (v is List<Color>) return v;
      }
    } catch (_) {
      // Swallow and let caller fall back
    }
    return null;
  }
}
