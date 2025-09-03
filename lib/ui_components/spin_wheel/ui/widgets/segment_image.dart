import 'package:flutter/material.dart';
import '../../models/wheel_segment.dart';

class SegmentImage extends StatelessWidget {
  final WheelSegment segment;
  final bool isLocked;

  const SegmentImage({
    super.key,
    required this.segment,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = segment.imagePath != null
        ? Image.asset(
      segment.imagePath!,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      color: isLocked ? Colors.grey.withOpacity(0.4) : null,
    )
        : const Icon(Icons.card_giftcard, size: 36);

    return Semantics(
      label: segment.label,
      enabled: !isLocked,
      button: true,
      child: MouseRegion(
        cursor: isLocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Tooltip(
          message: isLocked ? 'Locked: Requires unlock' : segment.label,
          child: image,
        ),
      ),
    );
  }
}
