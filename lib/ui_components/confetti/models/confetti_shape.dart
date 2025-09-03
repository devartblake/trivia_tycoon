import 'dart:math';
import 'package:flutter/material.dart';

enum ConfettiShapeType { circle, square, star, triangle, custom, image }

class ConfettiShape {
  final ConfettiShapeType type;
  final Color color;
  final double size;
  final double rotation;
  final Path? customPath;
  final String? imagePath;

  ConfettiShape({
    required this.type,
    required this.color,
    this.size = 10.0,
    this.rotation = 0.0,
    this.customPath,
    this.imagePath,
  });

  /// **Factory for image-based confetti.**
  factory ConfettiShape.image(String assetPath, {double size = 15.0}) {
    return ConfettiShape(
      type: ConfettiShapeType.image,
      color: Colors.transparent,
      size: size,
      rotation: 0.0,
      imagePath: assetPath,
    );
  }

  /// **Generates a random shape with random color and rotation.**
  static ConfettiShape random(List<Color> availableColors) {
    final random = Random();
    return ConfettiShape(
      type: ConfettiShapeType.values[random.nextInt(ConfettiShapeType.values.length)],
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      size: random.nextDouble() * 15 + 5, // Random size between 5 and 20
      rotation: random.nextDouble() * 360,  // Random rotation
    );
  }

  /// **Returns the path for the shape based on its type.**
  Path getPath() {
    switch (type) {
      case ConfettiShapeType.circle:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size / 2));
      case ConfettiShapeType.square:
        return Path()..addRect(Rect.fromCenter(center: Offset.zero, width: size, height: size));
      case ConfettiShapeType.triangle:
        return _createTrianglePath();
      case ConfettiShapeType.star:
        return _createStarPath();
      case ConfettiShapeType.custom:
        return customPath ?? Path();
      case ConfettiShapeType.image:
        return Path();
    }
  }

  /// **Creates a triangle path.**
  Path _createTrianglePath() {
    return Path()
        ..moveTo(0, -size / 2)
        ..lineTo(size / 2, size / 2)
        ..lineTo(-size / 2, size / 2)
        ..close();
  }

  /// **Create a simple star path.**
  Path _createStarPath() {
    Path path = Path();
    double outerRadius = size / 2;
    double innerRadius = outerRadius / 2.5;
    double angle = pi / 5;

    for (int i = 0; i < 10; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = r * cos(i  * angle);
      double y = r * sin( i * angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}