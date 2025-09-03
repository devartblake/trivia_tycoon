import 'package:flutter/material.dart';
import '../../models/wheel_segment.dart';

class SegmentLabel extends StatelessWidget {
  final WheelSegment segment;
  final bool isLocked;

  const SegmentLabel({
    super.key,
    required this.segment,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      segment.label,
      style: TextStyle(
        color: isLocked ? Colors.grey : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    return Semantics(
      label: segment.label,
      enabled: !isLocked,
      readOnly: true,
      child: MouseRegion(
        cursor: isLocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Tooltip(
          message: isLocked ? 'Locked Segment' : segment.label,
          child: text,
        ),
      ),
    );
  }
}