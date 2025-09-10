import 'dart:math';
import 'package:flutter/material.dart';
import '../math/hex_orientation.dart';

Path buildHexPath({
  required Offset center,
  required double radius,
  required HexOrientation orientation,
}) {
  final path = Path();
  for (int i = 0; i < 6; i++) {
    final ang = _vertexAngle(i, orientation);
    final x = center.dx + radius * cos(ang);
    final y = center.dy + radius * sin(ang);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

double _vertexAngle(int i, HexOrientation o) {
  // Flutter's canvas is y-down, so we rotate appropriately
  if (o == HexOrientation.pointy) {
    // starts at 30° and steps 60°
    return (pi / 180) * (60 * i - 30);
  } else {
    // flat: starts at 0°
    return (pi / 180) * (60 * i);
  }
}
