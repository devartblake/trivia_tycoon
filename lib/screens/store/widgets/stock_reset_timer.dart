import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/store_stock_providers.dart';

/// Live countdown showing when stock resets or when a flash sale expires.
///
/// Display examples:
/// - "Resets in 5h 12m"
/// - "Refreshes tomorrow"
/// - "Ends in 00:17:24"
/// - "Expired"
///
/// Uses the shared [stockCountdownProvider] ticker rather than a per-widget Timer.
class StockResetTimer extends ConsumerWidget {
  final DateTime? nextResetAt;
  final DateTime? expiresAt;

  /// When true, shows expiry countdown if both [nextResetAt] and [expiresAt] are set.
  final bool preferExpiry;
  final TextStyle? style;

  const StockResetTimer({
    super.key,
    this.nextResetAt,
    this.expiresAt,
    this.preferExpiry = false,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stockCountdownProvider); // rebuild every second

    final target = preferExpiry
        ? (expiresAt ?? nextResetAt)
        : (nextResetAt ?? expiresAt);

    if (target == null) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    final remaining = target.difference(now);

    final isExpiry = (target == expiresAt);
    final label = _label(remaining, isExpiry: isExpiry);
    final color = _color(remaining);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          remaining.isNegative ? Icons.timer_off_outlined : Icons.timer_outlined,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: (style ?? const TextStyle(fontSize: 12)).copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _label(Duration d, {required bool isExpiry}) {
    if (d.isNegative || d.inSeconds == 0) {
      return isExpiry ? 'Expired' : 'Resetting…';
    }

    final verb = isExpiry ? 'Ends in' : 'Resets in';

    if (d.inDays >= 2) {
      return '$verb ${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours >= 24) {
      return '$verb tomorrow';
    }
    if (d.inHours >= 1) {
      return '$verb ${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes >= 1) {
      final mm = _pad(d.inMinutes.remainder(60));
      final ss = _pad(d.inSeconds.remainder(60));
      return '$verb $mm:$ss';
    }
    return '$verb ${d.inSeconds}s';
  }

  Color _color(Duration d) {
    if (d.isNegative) return const Color(0xFF94A3B8);
    if (d.inMinutes < 60) return const Color(0xFFEF4444);
    if (d.inHours < 6) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
