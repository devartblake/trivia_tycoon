import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiPaintUtils {

  /// ***Generate a Triangle Path**
  static Path createTrianglePath(double size) {
    return Path()
        ..moveTo(0, -size / 2)
        ..lineTo(size / 2, size / 2)
        ..lineTo(-size / 2, size /2)
        ..close();
  }

  /// ***Generate a Star Path**
  static Path createStarPath(double size) {
    Path path = Path();
    double outerRadius = size / 2;
    double innerRadius = outerRadius / 2;
    double angle = pi / 5;

    for (int i = 0; i < 10; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = r * cos(i * angle);
      double y = r * sin(i * angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// **Generate a Custom Shape Path**
  static Path getShapePath(String shape, double size) {
    switch (shape) {
      case 'triangle':
        return createTrianglePath(size);
      case 'star':
        return createStarPath(size);
      default:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size / 2));
    }
  }
}