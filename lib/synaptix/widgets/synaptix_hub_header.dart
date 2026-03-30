import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';

/// Mode-aware greeting header for the Synaptix Hub.
class SynaptixHubHeader extends ConsumerWidget {
  final String playerName;
  final bool isDarkBackground;

  const SynaptixHubHeader({
    super.key,
    required this.playerName,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(synaptixModeProvider);
    final greeting = _greeting(mode);
    final theme = Theme.of(context);

    final titleColor = isDarkBackground
        ? Colors.white
        : theme.colorScheme.onSurface;
    final subtitleColor = isDarkBackground
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(mode),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(SynaptixMode mode) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    switch (mode) {
      case SynaptixMode.kids:
        return 'Hey $playerName! 🎉';
      case SynaptixMode.teen:
        return '$timeGreeting, $playerName';
      case SynaptixMode.adult:
        return '$timeGreeting, $playerName';
    }
  }

  String _subtitle(SynaptixMode mode) {
    switch (mode) {
      case SynaptixMode.kids:
        return 'Ready to play and learn?';
      case SynaptixMode.teen:
        return 'Your Synaptix Hub awaits';
      case SynaptixMode.adult:
        return 'Pick up where you left off';
    }
  }
}
