import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/power_up.dart';
import '../../game/models/store_item_model.dart';
import '../../game/providers/power_up_timer_provider.dart';
import '../../game/providers/riverpod_providers.dart';

class PowerUpCard extends ConsumerWidget {
  final StoreItemModel powerUpItem;

  const PowerUpCard({super.key, required this.powerUpItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(equippedPowerUpProvider.notifier);
    final equippedPowerUp = ref.watch(equippedPowerUpProvider);
    final isEquipped = equippedPowerUp?.id == powerUpItem.id;
    final remainingTime = ref.watch(powerUpTimeProvider);

    return Card(
      elevation: isEquipped ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEquipped
            ? BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Power-up icon
            Stack(
              children: [
                Image.asset(
                  powerUpItem.iconPath,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.bolt,
                      size: 48,
                      color: Colors.amber,
                    );
                  },
                ),
                if (isEquipped)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Power-up name
            Text(
              powerUpItem.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isEquipped ? Colors.amber.shade700 : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              powerUpItem.description ?? '',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Timer (if equipped)
            if (isEquipped && remainingTime != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      "${remainingTime ~/ 60}m ${remainingTime % 60}s",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isEquipped ? Icons.close : Icons.bolt),
                label: Text(isEquipped ? "Unequip" : "Equip"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isEquipped ? Colors.grey.shade300 : Colors.amber,
                  foregroundColor: isEquipped ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (isEquipped) {
                    controller.clearEquippedPowerUp();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${powerUpItem.name} unequipped"),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.grey.shade700,
                      ),
                    );
                  } else {
                    // FIXED: Convert StoreItemModel to PowerUp properly
                    final powerUp = PowerUp.fromStoreItem(powerUpItem);
                    await controller.activate(powerUp);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${powerUpItem.name} equipped!"),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}