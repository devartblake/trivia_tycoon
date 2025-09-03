import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/power_up_controller.dart';
import '../../../core/services/settings/app_settings.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/models/store_item_model.dart';

class StoreItemCard extends ConsumerWidget {
  final String name;
  final String description;
  final String iconPath;
  final String price;
  final StoreItemModel item;
  final VoidCallback onBuy;

  const StoreItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.price,
    required this.item,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyManager = ref.watch(currencyManagerProvider);
    final isDiamond = item.currency == 'diamonds';
    final balance = currencyManager.getBalance(item.currencyType);
    final notifier = currencyManager.getNotifier(item.currencyType);
    final equipped = ref.watch(equippedPowerUpProvider);

    final isPowerUp = item.category.toLowerCase() == 'power-up';
    final tag = item.type?.toUpperCase() ?? '';
    final glowColor = _getGlowColor(item.type);

    return FutureBuilder(
        future: AppSettings.isInInventory(item.id),
        builder: (context, snapshot) {
          final isOwned = snapshot.data ?? false;
          final isEquipped = equipped?.id == item.id;

          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// 🏷️ Type/Badge
                  if (isPowerUp)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: glowColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  /// 🖼️ Glow Image
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: isPowerUp
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        iconPath,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// 📋 Info
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  /// 💰 Price + Buy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price ${isDiamond ? '💎' : '🪙'}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      ElevatedButton(
                        onPressed: () async {
                          final canAfford = balance >= item.price;

                          if (!canAfford) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Not enough currency!")),
                            );
                            return;
                          }

                          await notifier.deduct(item.price);
                          await AppSettings.addToInventory(item.id);
                          // await AudioService.play(); // 🔊 Add custom jingle
                          onBuy();
                        },
                        child: const Text("Buy"),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// 🔥 Glow color per power-up type
  Color _getGlowColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'xp':
        return Colors.amberAccent;
      case 'shield':
        return Colors.blueAccent;
      case 'hint':
        return Colors.green;
      case 'eliminate':
        return Colors.redAccent;
      case 'boost':
        return Colors.purple;
      default:
        return Colors.deepOrangeAccent;
    }
  }
}
