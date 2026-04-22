import 'package:flutter/material.dart';

/// Visual meter showing remaining stock compared with total stock.
/// Hidden for unlimited items and for owned one-time cosmetics.
class StockMeterBar extends StatelessWidget {
  final int remaining;
  final int max;
  final String? caption;

  const StockMeterBar({
    super.key,
    required this.remaining,
    required this.max,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    if (max <= 0) return const SizedBox.shrink();

    final fraction = (remaining / max).clamp(0.0, 1.0);
    final isUrgent = remaining <= 1;
    final barColor = isUrgent
        ? const Color(0xFFEF4444)
        : remaining <= (max * 0.3).ceil()
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6366F1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: barColor.withValues(alpha: 0.12),
                  color: barColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              caption ?? '$remaining / $max',
              style: TextStyle(
                fontSize: 11,
                color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        if (isUrgent && remaining > 0) ...[
          const SizedBox(height: 2),
          Text(
            'Only $remaining left!',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
