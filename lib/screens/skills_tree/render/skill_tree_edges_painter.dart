import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../../../game/models/skill_tree_graph.dart';

class SkillTreeEdgesPainter extends CustomPainter {
  final SkillTreeGraph graph;
  final Map<String, Offset> positions; // world coordinates
  final vmath.Matrix4 worldToScreen;

  SkillTreeEdgesPainter({
    required this.graph,
    required this.positions,
    required this.worldToScreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final e in graph.edges) {
      final a = positions[e.fromId];
      final b = positions[e.toId];
      if (a == null || b == null) continue;

      final p1 = _toScreen(a);
      final p2 = _toScreen(b);

      // Slight curve towards center
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 20);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      canvas.drawPath(path, edgePaint);
    }
  }

  Offset _toScreen(Offset world) {
    final v = worldToScreen.transform3(vmath.Vector3(world.dx, world.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  @override
  bool shouldRepaint(covariant SkillTreeEdgesPainter old) =>
      old.graph != graph ||
          old.positions != positions ||
          old.worldToScreen != worldToScreen;
}
