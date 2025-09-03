import 'package:flutter/material.dart';
import 'dart:math' as math;


class ConstrainedScrollPhysics extends BouncingScrollPhysics {
  final double maxOverscroll;

  const ConstrainedScrollPhysics({super.parent, required this.maxOverscroll});

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!position.outOfRange) return offset;

    final double overscrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);

    final double direction = offset.sign;
    final double cur = offset + overscrollPast;
    final double ratio = math.max(0, 1 - cur / maxOverscroll);

    return direction * offset.abs() * ratio;
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.15, // 0.5
    stiffness: 250.0, // 100
    ratio: 1.25, // 1.1
  );
}
