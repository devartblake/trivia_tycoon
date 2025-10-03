import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/services/flow_connect_level_generator.dart';

class FlowConnectSettingsDialog extends ConsumerWidget {
  const FlowConnectSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(flowSettingsProvider);
    final settingsNotifier = ref.read(flowSettingsProvider.notifier);
    final gameNotifier = ref.read(flowConnectStateProvider.notifier);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Game Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grid Size: ${settings.gridSize} x ${settings.gridSize}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: settings.gridSize.toDouble(),
            min: 4,
            max: 8,
            divisions: 4,
            label: settings.gridSize.toString(),
            onChanged: (value) {
              settingsNotifier.setGridSize(value.toInt());
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          CupertinoSlidingSegmentedControl<FlowConnectDifficulty>(
            groupValue: settings.difficulty,
            onValueChanged: (value) {
              if (value != null) {
                settingsNotifier.setDifficulty(value);
              }
            },
            children: const {
              FlowConnectDifficulty.easy: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Easy'),
              ),
              FlowConnectDifficulty.medium: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Medium'),
              ),
              FlowConnectDifficulty.hard: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Hard'),
              ),
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Apply settings and start a new game
            gameNotifier.initializeGame(settings.gridSize, settings.difficulty);
            Navigator.of(context).pop();
          },
          child: const Text('New Game'),
        ),
      ],
    );
  }
}
