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

  HexEdgePainter({
    required this.graph,
    required this.hexOf,
    required this.hexSize,
    this.orientation = HexOrientation.pointy,
    this.color = const Color(0x44FFFFFF),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

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
      old.strokeWidth != strokeWidth;
}
