import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../game/providers/riverpod_providers.dart';

/// ✅ A live-updating widget to display the user's coin balance
/// Can be placed in app bars, overlay panels, or sidebars.
class CoinBalanceDisplay extends ConsumerWidget {
  final bool animate;

  const CoinBalanceDisplay({super.key, this.animate = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBalance = ref.watch(coinNotifierProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: Colors.amber),
        const SizedBox(width: 4),
        AnimatedSwitcher(
          duration: animate ? const Duration(milliseconds: 500) : Duration.zero,
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Text(
            '$coinBalance',
            key: ValueKey(coinBalance),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
