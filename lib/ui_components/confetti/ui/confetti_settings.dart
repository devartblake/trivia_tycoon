import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../core/confetti_theme.dart';

final showDebugOverlayProvider = StateProvider<bool>((ref) => false);

class ConfettiSettings extends ConsumerWidget {
  const ConfettiSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confettiController = ref.watch(confettiControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Confetti Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<ConfettiTheme>(
              value: confettiController.currentTheme,
              items: ConfettiTheme.presets.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(theme.name),
                );
              }).toList(),
              onChanged: (theme) {
                if (theme != null) {
                  confettiController.setTheme(theme);
                }
              },
            ),
            Slider(
              value: confettiController.speed,
              min: 0.5,
              max: 3.0,
              divisions: 5,
              label: "Speed: ${confettiController.speed.toStringAsFixed(1)}",
              onChanged: (value) {
                confettiController.setSpeed(value);
              },
            ),
            Slider(
              value: confettiController.particleCount.toDouble(),
              min: 10,
              max: 300,
              divisions: 10,
              label: "Particles: ${confettiController.particleCount}",
              onChanged: (value) {
                confettiController.setParticleCount(value.toInt());
              },
            ),
            SwitchListTile(
              title: Text("Random Theme"),
              value: confettiController.isRandomTheme,
              onChanged: (value) {
                confettiController.toggleRandomTheme();
              },
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text("Show Debug Overlay"),
              value: ref.watch(showDebugOverlayProvider),
              onChanged: (value) {
                ref.read(showDebugOverlayProvider.notifier).state = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
