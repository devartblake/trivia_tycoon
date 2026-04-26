import 'package:flutter/material.dart';
import '../math/hex_orientation.dart';
import '../model/coordinates.dart';

/// Draws the three cube-coordinate axes (q, r, s) through the selected hex,
/// plus tinted borders on nodes that share an axis with the selection.
///
/// Colors match the redblobgames convention:
///   q-axis (constant q)  → blue  (r-axis rows)
///   r-axis (constant r)  → green (q-axis columns)
///   s-axis (constant s)  → purple
class HexAxisOverlayPainter extends CustomPainter {
  final Coordinates selected;
  final Map<String, Coordinates> hexOf;
  final Map<String, Offset> screenPositions;
  final double hexSize;
  final HexOrientation orientation;

  static const Color _qAxisColor = Color(0x886EE7F9); // blue
  static const Color _rAxisColor = Color(0x8866BB6A); // green
  static const Color _sAxisColor = Color(0x88CE93D8); // purple
  static const double _lineWidth = 2.0;
  static const double _nodeRingWidth = 2.5;

  const HexAxisOverlayPainter({
    required this.selected,
    required this.hexOf,
    required this.screenPositions,
    required this.hexSize,
    required this.orientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (screenPositions.isEmpty) return;

    final selectedPos = screenPositions.entries
        .where((e) => hexOf[e.key] == selected)
        .map((e) => e.value)
        .firstOrNull;
    if (selectedPos == null) return;

    final int selQ = selected.q;
    final int selR = selected.r;
    final int selS = selected.s; // -q - r

    // Axis paints
    final qPaint = _linePaint(_qAxisColor);
    final rPaint = _linePaint(_rAxisColor);
    final sPaint = _linePaint(_sAxisColor);

    // Ring paints for nodes on each axis
    final qRingPaint = _ringPaint(_qAxisColor);
    final rRingPaint = _ringPaint(_rAxisColor);
    final sRingPaint = _ringPaint(_sAxisColor);

    // Collect axis-member positions for drawing connecting lines
    final qAxisPts = <Offset>[];
    final rAxisPts = <Offset>[];
    final sAxisPts = <Offset>[];

    for (final entry in hexOf.entries) {
      final coord = entry.value;
      final pos = screenPositions[entry.key];
      if (pos == null) continue;

      final onQ = coord.q == selQ;
      final onR = coord.r == selR;
      final onS = coord.s == selS;

      if (onQ) qAxisPts.add(pos);
      if (onR) rAxisPts.add(pos);
      if (onS) sAxisPts.add(pos);

      // Draw tinted ring around nodes on any axis (skip the selected node itself)
      if (coord == selected) continue;

      final nodeRadius = hexSize * 0.55;
      if (onQ) canvas.drawCircle(pos, nodeRadius, qRingPaint);
      if (onR) canvas.drawCircle(pos, nodeRadius, rRingPaint);
      if (onS) canvas.drawCircle(pos, nodeRadius, sRingPaint);
    }

    // Draw connecting lines along each axis (sorted by position for clean lines)
    _drawAxisLine(canvas, qAxisPts, qPaint, horizontal: false);
    _drawAxisLine(canvas, rAxisPts, rPaint, horizontal: true);
    _drawAxisLine(canvas, sAxisPts, sPaint, horizontal: false);
  }

  void _drawAxisLine(
      Canvas canvas, List<Offset> pts, Paint paint,
      {required bool horizontal}) {
    if (pts.length < 2) return;
    // Sort by the dominant axis coordinate for clean sequential segments
    final sorted = List<Offset>.from(pts)
      ..sort((a, b) =>
          horizontal ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));

    final path = Path()..moveTo(sorted.first.dx, sorted.first.dy);
    for (int i = 1; i < sorted.length; i++) {
      path.lineTo(sorted[i].dx, sorted[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  Paint _linePaint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = _lineWidth
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  Paint _ringPaint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = _nodeRingWidth;

  @override
  bool shouldRepaint(covariant HexAxisOverlayPainter old) =>
      old.selected != selected ||
      old.hexOf != hexOf ||
      old.screenPositions != screenPositions ||
      old.hexSize != hexSize ||
      old.orientation != orientation;
}
