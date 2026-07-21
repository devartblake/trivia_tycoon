import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import '../../../core/services/social/friends_models.dart';

/// Card widget displaying a friend's information
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
    return AdaptiveGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Stack(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
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
        title: Text(
          friend.username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(
              friend.isOnline ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: friend.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              friend.isOnline ? 'Online' : 'Offline',
              style: const TextStyle(color: Colors.white70),
            ),
            if (friend.level != null) ...[
              const SizedBox(width: 8),
              Text(
                'Lvl ${friend.level}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          iconColor: Colors.white70,
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
                  const Icon(Icons.person_remove_rounded,
                      size: 20, color: Colors.red),
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
