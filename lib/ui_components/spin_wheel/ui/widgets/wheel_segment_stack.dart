import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/widget_wheel_segment.dart';
import '../../models/wheel_segment.dart';

class WheelSegmentStack extends StatelessWidget {
  final List<WheelSegment> segments;
  final double rotationAngle;
  final int? activeIndex;
  final void Function(int)? onSegmentTap;
  final void Function(double velovity)? onGestureSpin;

  const WheelSegmentStack({
    super.key,
    required this.segments,
    required this.rotationAngle,
    this.activeIndex,
    this.onSegmentTap,
    this.onGestureSpin,
  });

  @override
  Widget build(BuildContext context) {
    final double sliceAngle = 2 * pi / segments.length;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(segments.length, (index) {
        final segment = segments[index];
        final angle = sliceAngle * index;

        return WidgetWheelSegment(
          segment: segment,
          angle: rotationAngle + angle,
          isActive: activeIndex == index,
          isLocked: segment.isExclusive,
          onTap: () => onSegmentTap?.call(index),
          onGestureSpin: onGestureSpin,
        );
      }),
    );
  }
}
