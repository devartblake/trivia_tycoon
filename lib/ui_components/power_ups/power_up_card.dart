import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';

import '../../game/providers/power_up_timer_provider.dart';
import '../../game/models/store_item_model.dart';
import '../../game/providers/riverpod_providers.dart';

class PowerUpCard extends ConsumerWidget {
  final StoreItemModel powerUp;

  const PowerUpCard({super.key, required this.powerUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(equippedPowerUpProvider);
    final notifier = ref.read(equippedPowerUpProvider.notifier);

    final isActive = controller?.id == powerUp.id;
    final remainingSeconds = ref.watch(powerUpTimeProvider); // Timer provider

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Image.asset(powerUp.iconPath, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(powerUp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(powerUp.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            if (isActive && remainingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "⏳ ${Duration(seconds: remainingSeconds).inMinutes}m ${remainingSeconds % 60}s",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt),
              label: Text(isActive ? "Equipped" : "Use"),
              onPressed: () async {
                if (!isActive) {
                  final used = await notifier.usePowerUp(powerUp as PowerUp);
                  if (used && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${powerUp.name} activated!")),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
