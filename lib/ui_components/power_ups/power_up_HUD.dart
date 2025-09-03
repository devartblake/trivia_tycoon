import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/power_up_timer_provider.dart';
import '../../game/providers/riverpod_providers.dart';

class PowerUpHUD extends ConsumerWidget {
  const PowerUpHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerUp = ref.watch(equippedPowerUpProvider);
    final remaining = ref.watch(powerUpTimeProvider);

    if (powerUp == null || remaining == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: remaining > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(powerUp.iconPath, height: 24, width: 24),
              const SizedBox(width: 10),
              Text("${powerUp.name} - ${remaining}s", style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
