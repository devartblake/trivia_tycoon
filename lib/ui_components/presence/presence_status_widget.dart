import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/presence/rich_presence_indicator.dart';
import '../../game/models/user_presence_models.dart';
import '../../core/animations/animation_manager.dart';

class PresenceStatusIndicator extends StatelessWidget {
  final PresenceStatus status;
  final double size;
  final bool showBorder;
  final bool animated;

  const PresenceStatusIndicator({
    super.key,
    required this.status,
    this.size = 10,
    this.showBorder = false,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        )
            : null,
      ),
    );

    // ✅ Use AnimationManager.pulse instead of manual animation
    if (animated && status == PresenceStatus.online) {
      return AnimationManager.pulse(
        child: indicator,
        minScale: 0.8,
        maxScale: 1.0,
        duration: const Duration(seconds: 2),
      );
    }

    return indicator;
  }
}

class DetailedPresenceCard extends StatelessWidget {
  final UserPresence presence;
  final String userName;
  final String? userAvatar;

  const DetailedPresenceCard({
    super.key,
    required this.presence,
    required this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: userAvatar != null
                          ? NetworkImage(userAvatar!)
                          : null,
                      child: userAvatar == null
                          ? Text(userName[0].toUpperCase())
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: PresenceStatusIndicator(
                        status: presence.status,
                        size: 14,
                        showBorder: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichPresenceIndicator(
                        presence: presence,
                        showDetailedInfo: true,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (presence.gameActivity != null) ...[
              const SizedBox(height: 12),
              _buildGameActivityDetails(context),
            ],
            const SizedBox(height: 8),
            Text(
              'Last seen: ${_formatLastSeen(presence.lastSeen)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameActivityDetails(BuildContext context) {
    final activity = presence.gameActivity!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (activity.gameState.icon != null)
                Icon(
                  activity.gameState.icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Text(
                activity.gameState.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if (activity.gameType != null) ...[
            const SizedBox(height: 4),
            Text('Game: ${activity.gameType}'),
          ],
          if (activity.gameMode != null) ...[
            const SizedBox(height: 4),
            Text('Mode: ${activity.gameMode}'),
          ],
          if (activity.score != null) ...[
            const SizedBox(height: 4),
            Text('Score: ${activity.score}'),
          ],
          if (activity.currentLevel != null) ...[
            const SizedBox(height: 4),
            Text('Level: ${activity.currentLevel}'),
          ],
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}