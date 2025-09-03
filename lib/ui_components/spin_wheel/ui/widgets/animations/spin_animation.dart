import 'package:flutter/material.dart';

class SpinAnimation extends StatelessWidget {
  final double rotationAngle;
  final Widget child;

  const SpinAnimation({
    super.key,
    required this.rotationAngle,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: child,
    );
  }
}