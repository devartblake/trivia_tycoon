import 'dart:math';
import 'package:flutter/material.dart';

Offset polarOffset(double angleDeg, double radius) {
  final rad = angleDeg * pi / 180.0;
  return Offset(cos(rad) * radius, sin(rad) * radius);
}
