import 'dart:math';
import 'package:flutter/material.dart';

class ColorPickerPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final bool isCircular;

  ColorPickerPainter({
    required this.colors,
    this.strokeWidth = 20.0,
    this.isCircular = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (isCircular) {
      _drawColorWheel(canvas, size, paint);
    } else {
      _drawColorGrid(canvas, size, paint);
    }
  }

  void _drawColorWheel(Canvas canvas, Size size, Paint paint) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final angleStep = (2 * pi) / colors.length;

    for (int i = 0; i < colors.length; i++) {
      final startAngle = i * angleStep;
      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        angleStep,
        false,
        paint,
      );
    }
  }

  void _drawColorGrid(Canvas canvas, Size size, Paint paint) {
    final rows = 4;
    final cols = (colors.length / rows).ceil();
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    for (int i = 0; i < colors.length; i++) {
      final x = (i % cols) * cellWidth;
      final y = (i ~/ cols) * cellHeight;
      paint.color = colors[i];

      canvas.drawRect(Rect.fromLTWH(x, y, cellWidth, cellHeight), paint);
    }
  }

  @override
  bool shouldRepaint(ColorPickerPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
