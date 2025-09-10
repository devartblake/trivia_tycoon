import 'dart:math';
import '../../../core/utils/math_types.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;


class SkillTreeBackgroundPainter extends CustomPainter {
  final Matrix4 worldToScreen;
  final double hexRadius;
  final int ringCount;
  final double ringSpacing;
  final int rayCount;

  SkillTreeBackgroundPainter({
    required this.worldToScreen,
    required this.hexRadius,
    this.ringCount = 6,
    this.ringSpacing = 80.0,
    this.rayCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintHex = Paint()
      ..color = Colors.grey.shade200.withOpacity(0.3)
      ..style = PaintingStyle.stroke;

    final paintRings = Paint()
      ..color = Colors.blueGrey.shade300.withOpacity(0.4)
      ..style = PaintingStyle.stroke;

    final paintRays = Paint()
      ..color = Colors.blueGrey.shade300.withOpacity(0.4)
      ..style = PaintingStyle.stroke;

    final invMatrix = Matrix4.inverted(worldToScreen);
    final screenCenter = Offset(size.width / 2, size.height / 2);
    final centerWorld = _transformPoint(invMatrix, screenCenter);

    // Draw hex grid
    final bounds = _visibleWorldBounds(invMatrix, size);
    _drawHexGrid(canvas, centerWorld, bounds, hexRadius, paintHex);

    // Draw radial rays
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * (2 * 3.1415926);
      final dx = centerWorld.dx + ringCount * ringSpacing * cos(angle);
      final dy = centerWorld.dy + ringCount * ringSpacing * sin(angle);

      final p1 = _transformPoint(worldToScreen, centerWorld);
      final p2 = _transformPoint(worldToScreen, Offset(dx, dy));

      canvas.drawLine(p1, p2, paintRays);
    }

    // Draw concentric rings
    for (int i = 1; i <= ringCount; i++) {
      final radius = i * ringSpacing;
      final screenRadius = (worldToScreen.transform3(Vec3(radius, 0, 0))).x;
      canvas.drawCircle(screenCenter, screenRadius, paintRings);
    }
  }

  void _drawHexGrid(Canvas canvas, Offset center, Rect bounds, double radius, Paint paint) {
    final double width = radius * 2;
    final double height = sqrt(3) * radius;

    for (double q = -100; q < 100; q++) {
      for (double r = -100; r < 100; r++) {
        final x = width * (3.0 / 4.0 * q);
        final y = height * (r + q / 2);

        final worldOffset = Offset(center.dx + x, center.dy + y);

        if (bounds.contains(worldOffset)) {
          final screenOffset = _transformPoint(worldToScreen, worldOffset);
          _drawHexagon(canvas, screenOffset, radius, paint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 3 * i;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  Offset _transformPoint(Matrix4 matrix, Offset point) {
    final result = matrix.transform3(Vec3(point.dx, point.dy, 0));
    return Offset(result.x, result.y);
  }

  Rect _visibleWorldBounds(Matrix4 invMatrix, Size screenSize) {
    final topLeft = _transformPoint(invMatrix, Offset.zero);
    final bottomRight = _transformPoint(invMatrix, Offset(screenSize.width, screenSize.height));
    return Rect.fromPoints(topLeft, bottomRight);
  }

  @override
  bool shouldRepaint(covariant SkillTreeBackgroundPainter oldDelegate) {
    return worldToScreen != oldDelegate.worldToScreen ||
        hexRadius != oldDelegate.hexRadius ||
        ringCount != oldDelegate.ringCount ||
        ringSpacing != oldDelegate.ringSpacing ||
        rayCount != oldDelegate.rayCount;
  }
}