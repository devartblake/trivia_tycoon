import 'dart:math';
import 'package:flutter/material.dart';

class NeuralBloomData {
  final String label;
  final double value; // 0.0 to 1.0
  final Color color;

  NeuralBloomData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class NeuralBloomPainter extends CustomPainter {
  final List<NeuralBloomData> data;
  final double animationValue;
  final Color accentColor;

  NeuralBloomPainter({
    required this.data,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.5;
    final angleStep = (2 * pi) / data.length;

    final webPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // 1. Draw background web (rings)
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), webPaint);
    }

    // 2. Draw axes and data area
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final angle = i * angleStep - pi / 2;
      final val = data[i].value * animationValue;
      final point = Offset(
        center.dx + radius * val * cos(angle),
        center.dy + radius * val * sin(angle),
      );
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }

      // Draw axis line
      canvas.drawLine(
        center,
        Offset(
            center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        webPaint,
      );
    }
    path.close();

    // 3. Draw filled data area with gradient
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.4),
          accentColor.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Draw data nodes (blooms)
    for (var i = 0; i < data.length; i++) {
      final point = points[i];
      final nodeColor = data[i].color;

      // Outer glow
      canvas.drawCircle(
        point,
        6 + 4 * sin(animationValue * pi),
        Paint()..color = nodeColor.withValues(alpha: 0.3 * animationValue),
      );

      // Core node
      canvas.drawCircle(point, 4, nodePaint..color = nodeColor);
    }
  }

  @override
  bool shouldRepaint(NeuralBloomPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data;
  }
}
