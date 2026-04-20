import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/presence/presence_status_widget.dart';
import '../../game/models/user_presence_models.dart';

class RichPresenceIndicator extends StatelessWidget {
  final UserPresence presence;
  final bool showDetailedInfo;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  const RichPresenceIndicator({
    super.key,
    required this.presence,
    this.showDetailedInfo = true,
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator(context);
    }

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: presence.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: presence.status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceStatusIndicator(
            status: presence.status,
            size: 8,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _getPresenceText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (presence.gameActivity != null && showDetailedInfo)
            _buildGameActivityIcon(context),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceStatusIndicator(
          status: presence.status,
          size: 6,
        ),
        const SizedBox(width: 4),
        Text(
          presence.status.displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Widget _buildGameActivityIcon(BuildContext context) {
    final activity = presence.gameActivity;
    if (activity == null) return const SizedBox.shrink();

    final icon = activity.gameState.icon;
    if (icon == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        icon,
        size: 12,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _getPresenceText() {
    if (!showDetailedInfo) {
      return presence.status.displayName;
    }

    final activity = presence.gameActivity;
    if (activity != null && presence.status != PresenceStatus.offline) {
      switch (activity.gameState) {
        case GameState.playing:
          return 'Playing ${activity.gameType}${activity.gameMode != null ? " - ${activity.gameMode}" : ""}';
        case GameState.paused:
          return 'Paused ${activity.gameType}';
        case GameState.lobby:
          return 'In game lobby';
        case GameState.waiting:
          return 'Waiting to start';
        case GameState.finished:
      }
    }

    return presence.status.displayName;
  }
}

extension PresenceStatusExtension on PresenceStatus {
  Color get color {
    switch (this) {
      case PresenceStatus.online:
        return const Color(0xFF3BA55C); // Green
      case PresenceStatus.away:
        return const Color(0xFFFAA61A); // Yellow
      case PresenceStatus.busy:
        return const Color(0xFFED4245); // Red
      case PresenceStatus.inGame:
        return const Color(0xFF5865F2); // Blue
      case PresenceStatus.offline:
        return const Color(0xFF747F8D); // Gray
    }
  }
}

extension GameStateExtension on GameState {
  IconData? get icon {
    switch (this) {
      case GameState.playing:
        return Icons.sports_esports;
      case GameState.lobby:
        return Icons.people;
      case GameState.paused:
        return Icons.pause;
      case GameState.waiting:
        return Icons.hourglass_empty;
      case GameState.finished:
        return Icons.check_circle;
    }
  }
}
