import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/models/currency_type.dart';

class CurrencyDisplayBar extends ConsumerWidget {
  const CurrencyDisplayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyManager = ref.watch(currencyManagerProvider);
    final coinBalance = ref.watch(currencyManager.getProvider(CurrencyType.coins));
    final diamondBalance = ref.watch(currencyManager.getProvider(CurrencyType.diamonds));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCurrencyDisplay(
          icon: Icons.monetization_on,
          label: '$coinBalance Coins',
          color: Colors.amber,
        ),
        _buildCurrencyDisplay(
          icon: Icons.diamond,
          label: '$diamondBalance Diamonds',
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildCurrencyDisplay({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, color: color),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.grey[100],
    );
  }
}

