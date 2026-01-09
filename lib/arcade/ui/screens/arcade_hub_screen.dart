import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/arcade_game_card.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_definition.dart';
import '../../providers/arcade_providers.dart';
import 'arcade_game_shell.dart';

class ArcadeHubScreen extends ConsumerWidget {
  const ArcadeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(arcadeRegistryProvider);
    final games = registry.games;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Arcade'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final game = games[index];
          return ArcadeGameCard(
            game: game,
            onTap: () => _openDifficultyPicker(context, game),
          );
        },
      ),
    );
  }

  Future<void> _openDifficultyPicker(
      BuildContext context,
      ArcadeGameDefinition game,
      ) async {
    final selected = await showModalBottomSheet<ArcadeDifficulty>(
      context: context,
      backgroundColor: const Color(0xFF0E0E12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(game.icon, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        game.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...game.supportedDifficulties.map(
                      (d) => ListTile(
                    title: Text(d.label, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => Navigator.of(context).pop(d),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    // Launch through the common shell to standardize rewards & result UX
    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArcadeGameShell(
          game: game,
          difficulty: selected,
        ),
      ),
    );
  }
}
