import 'package:flutter/material.dart';
import '../../../core/services/social/friends_models.dart';

/// Card widget displaying a friend's information
///
/// Shows:
/// - Avatar
/// - Username
/// - Online status indicator
/// - Level/rank (if available)
/// - Action menu (challenge, message, remove)
class FriendCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onChallenge;
  final VoidCallback? onRemove;

  const FriendCard({
    super.key,
    required this.friend,
    this.onChallenge,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: ListTile(
        leading: Stack(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            // Online status indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: friend.isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(friend.username),
        subtitle: Row(
          children: [
            Icon(
              friend.isOnline ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: friend.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(friend.isOnline ? 'Online' : 'Offline'),
            if (friend.level != null) ...[
              const SizedBox(width: 8),
              Text('Lvl ${friend.level}'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'challenge':
                onChallenge?.call();
                break;
              case 'remove':
                onRemove?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'challenge',
              child: Row(
                children: [
                  Icon(Icons.sports_esports_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Challenge'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  const Icon(Icons.person_remove_rounded, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
