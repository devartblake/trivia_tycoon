import 'dart:math';
import 'package:flutter/material.dart';
import '../core/confetti_theme.dart';

class ConfettiPainter extends CustomPainter {
  final ConfettiTheme theme;
  final List<Offset> _pooledPositions = [];
  final List<Color> _colors = [];

  ConfettiPainter(this.theme) {
    final random = Random();
    for (int i = 0; i < theme.density; i++) {
      _pooledPositions.add(Offset(
        random.nextDouble() * 500, // Using a predefined max width
        random.nextDouble() * 800, // Using a predefined max height
      ));
      _colors.add(theme.colors[random.nextInt(theme.colors.length)]);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if(_pooledPositions.isEmpty) {
      final random = Random();
      for (int i = 0; i < theme.density; i++) {
        _pooledPositions.add(Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
        ));
      }
    }
    final Path path = Path();
    for (int i = 0; i < _pooledPositions.length; i++) {
      path.addOval(Rect.fromCircle(center: _pooledPositions[i], radius: theme.speed));
    }

    final Paint paint = Paint()..color = theme.colors[0];
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
