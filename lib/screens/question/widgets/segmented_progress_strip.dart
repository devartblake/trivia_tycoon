import 'package:flutter/material.dart';

/// Slim segmented progress strip: one segment per question. Answered/past
/// segments fill with the category color, the current one glows brighter,
/// upcoming ones stay translucent. Replaces the "Question X of Y / N%
/// Complete" text block.
class SegmentedProgressStrip extends StatelessWidget {
  final int total;
  final int currentIndex; // 0-based
  final Color activeColor;

  const SegmentedProgressStrip({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return Semantics(
      label: 'Question ${currentIndex + 1} of $total',
      child: Row(
        children: List.generate(total, (i) {
          final Color color;
          if (i < currentIndex) {
            color = activeColor.withValues(alpha: 0.75);
          } else if (i == currentIndex) {
            color = activeColor;
          } else {
            color = Colors.white.withValues(alpha: 0.18);
          }
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
