import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/providers/wallet_providers.dart';

class WalletCountersRow extends ConsumerWidget {
  final bool compact;
  final bool backplate;

  const WalletCountersRow({
    super.key,
    this.compact = true,
    this.backplate = true, // NEW: enable backplate by default
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(playerCoinsProvider);
    final gems = ref.watch(playerGemsProvider);

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterChip(
          icon: Icons.monetization_on_rounded,
          value: coins,
          label: 'Coins',
          compact: compact,
        ),
        const SizedBox(width: 8),
        _CounterChip(
          icon: Icons.diamond_rounded,
          value: gems,
          label: 'Gems',
          compact: compact,
        ),
      ],
    );

    if (!backplate) return row;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.28), // frosted backplate
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: row,
    );
  }
}

class _CounterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool compact;

  const _CounterChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 16 : 18, color: Colors.white),
          const SizedBox(width: 6),
          if (!compact)
            Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (!compact) const SizedBox(width: 6),
          Text(
            _format(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _format(int v) {
    // Compact formatting (e.g. 12.3K)
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}
