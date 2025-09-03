import 'dart:math';
import 'math_types.dart';
import 'package:flutter/material.dart';

class SkillTreeBackgroundPainter extends CustomPainter {
  final Mat4 worldToScreen;
  final double nodeSize;
  final int rings;
  final int spokes;

  SkillTreeBackgroundPainter({
    required this.worldToScreen,
    this.nodeSize = 100.0,
    this.rings = 4,
    this.spokes = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    final vm = worldToScreen.clone().invert();
    final Offset center = _transform(vm as Mat4, Offset(size.width / 2, size.height / 2));

    // Draw radial lines (spider legs)
    for (int i = 0; i < spokes; i++) {
      final angle = 2 * pi * i / spokes;
      final dx = cos(angle) * nodeSize * rings * 1.2;
      final dy = sin(angle) * nodeSize * rings * 1.2;
      canvas.drawLine(center, center + Offset(dx, dy), paint);
    }

    // Draw concentric rings
    for (int i = 1; i <= rings; i++) {
      canvas.drawCircle(center, nodeSize * i.toDouble(), paint);
    }

    // Draw honeycomb hex grid
    final double hexRadius = nodeSize * 0.95;
    final double hexWidth = hexRadius * 2;
    final double hexHeight = sqrt(3) * hexRadius;

    final cols = (size.width / hexWidth).ceil() + 2;
    final rows = (size.height / hexHeight).ceil() + 2;

    for (int q = -cols; q < cols; q++) {
      for (int r = -rows; r < rows; r++) {
        final hexCenter = _hexToPixel(q, r, hexRadius) + center;
        _drawHexagon(canvas, hexCenter, hexRadius, paint);
      }
    }
  }

  Offset _transform(Matrix4 matrix, Offset point) {
    final v = matrix.transform3(Vec3(point.dx, point.dy, 0));
    return Offset(v.x, v.y);
  }

  Offset _hexToPixel(int q, int r, double size) {
    final x = size * 3 / 2 * q;
    final y = size * sqrt(3) * (r + q / 2);
    return Offset(x, y);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 3 * i - pi / 6;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
