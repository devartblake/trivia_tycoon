import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/game_controller.dart';
import '../../../ui_components/power_ups/equipped_power_up_tile.dart';

class ScoreDisplay extends ConsumerWidget {
  final int score;

  const ScoreDisplay({super.key, required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final powerUp = game.equippedPowerUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Score",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          "$score",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),

        // Show equipped power-up if available
        if (powerUp != null)
          FutureBuilder<Duration>(
            future: ref.read(gameControllerProvider.notifier).getPowerUpRemainingTime(),
            builder: (context, snapshot) {
              final remaining = snapshot.data ?? Duration.zero;

              return EquippedPowerUpTile(
                powerUp: powerUp,
                duration: remaining.inSeconds,
                onClear: () async {
                  await ref.read(gameControllerProvider.notifier).clearEquippedPowerUp();
                },
              );
            },
          ),
      ],
    );
  }
}
