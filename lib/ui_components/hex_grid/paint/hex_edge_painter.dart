import 'package:flutter/material.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../model/coordinates.dart';
import '../math/hex_metrics.dart';
import '../math/hex_orientation.dart';

class HexEdgePainter extends CustomPainter {
  final SkillTreeGraph graph;
  final Map<String, Coordinates> hexOf; // nodeId -> coordinates
  final double hexSize;
  final HexOrientation orientation;
  final Color color;
  final double strokeWidth;
  // Pre-computed screen positions (preferred — avoids coordinate mismatch).
  // When provided, hexOf/hexSize/orientation are ignored for positioning.
  final Map<String, Offset>? screenPositions;

  HexEdgePainter({
    required this.graph,
    required this.hexOf,
    required this.hexSize,
    this.orientation = HexOrientation.pointy,
    this.color = const Color(0x44FFFFFF),
    this.strokeWidth = 2.0,
    this.screenPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (screenPositions != null) {
      // Use pre-computed positions — perfectly aligned with HexagonFreeGrid.
      for (final e in graph.edges) {
        final pa = screenPositions![e.fromId];
        final pb = screenPositions![e.toId];
        if (pa == null || pb == null) continue;
        canvas.drawLine(pa, pb, p);
      }
      return;
    }

    // Fallback: derive from axial coordinates (may be misaligned if spacing != 0).
    final center = Offset(size.width / 2, size.height / 2);
    for (final e in graph.edges) {
      final a = hexOf[e.fromId];
      final b = hexOf[e.toId];
      if (a == null || b == null) continue;

      final pa = HexMetrics.axialToPixel(a.q, a.r, hexSize, orientation);
      final pb = HexMetrics.axialToPixel(b.q, b.r, hexSize, orientation);
      canvas.drawLine(center + pa, center + pb, p);
    }
  }

  @override
  bool shouldRepaint(covariant HexEdgePainter old) =>
      old.graph != graph ||
      old.hexOf != hexOf ||
      old.hexSize != hexSize ||
      old.orientation != orientation ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.screenPositions != screenPositions;
}
