import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/power_up_timer_provider.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';
import '../../game/controllers/power_up_controller.dart';
import '../../game/models/store_item_model.dart';
import '../../game/providers/riverpod_providers.dart';

class PowerUpInventoryWidget extends ConsumerWidget {
  const PowerUpInventoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerUpsAsync = ref.watch(powerUpInventoryProvider);

    return powerUpsAsync.when(
      data: (powerUps) {
        if (powerUps.isEmpty) {
          return const Center(child: Text("No power-ups available"));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: powerUps.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final powerUp = powerUps[index];
            return _PowerUpCard(powerUp: powerUp);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading power-ups: $err')),
    );
  }
}

class _PowerUpCard extends ConsumerWidget {
  final StoreItemModel powerUp;

  const _PowerUpCard({required this.powerUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(equippedPowerUpProvider.notifier);
    final equipped = ref.watch(equippedPowerUpProvider);
    final isEquipped = equipped?.id == powerUp.id;
    final remaining = ref.watch(powerUpTimeProvider);

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
            const Spacer(),

            /// 🔘 Equip or Unequipped
            ElevatedButton.icon(
              icon: Icon(isEquipped ? Icons.close : Icons.bolt),
              label: Text(isEquipped ? "Unequipped" : "Equip"),
              onPressed: () async {
                if (isEquipped) {
                  controller.clearEquippedPowerUp();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${powerUp.name} unequipped.")),
                  );
                } else {
                  await controller.activate(powerUp as PowerUp);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${powerUp.name} equipped!")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
