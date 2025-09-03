import 'package:flutter/material.dart';

class LightingOptions {
  final double intensity;
  final Color color;
  final Offset direction;

  const LightingOptions({
    this.intensity = 0.8,
    this.color = Colors.white,
    this.direction = const Offset(1, 0),
  });
}
