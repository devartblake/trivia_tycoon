import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_detail_screen.dart';

// === Models & Providers ===
enum InboxType {
  alert,        // Red - urgent
  notification, // Blue - general
  friend,       // Green - social
  achievement,  // Gold - rewards
  system,       // Purple - updates
  challenge,    // Orange - game
}

class InboxItem {
  final String id;
  final InboxType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? actionRoute;
  final Map<String, String>? payload;
  final bool unread;
  final String? icon;
  final String? avatarUrl;

  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.actionRoute,
    this.payload,
    this.unread = true,
    this.icon,
    this.avatarUrl,
  });
}

// Sample data provider
final inboxProvider = StateProvider<List<InboxItem>>((ref) => [
  InboxItem(
    id: '1',
    type: InboxType.friend,
    title: 'Sarah Chen sent you a friend request',
    body: 'You have 12 mutual friends',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    icon: 'person_add',
    unread: true,
  ),
  InboxItem(
    id: '2',
    type: InboxType.challenge,
    title: 'New Challenge Available!',
    body: 'Mike Johnson challenged you to a trivia duel',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    icon: 'emoji_events',
    unread: true,
  ),
  InboxItem(
    id: '3',
    type: InboxType.achievement,
    title: 'Achievement Unlocked!',
    body: 'You earned the "Quiz Master" badge',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    icon: 'military_tech',
    unread: false,
  ),
  InboxItem(
    id: '4',
    type: InboxType.system,
    title: 'App Update Available',
    body: 'Version 2.1.0 includes new features and bug fixes',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    icon: 'system_update',
    unread: false,
  ),
]);

final unreadCountProvider = Provider<int>(
      (ref) => ref.watch(inboxProvider).where((i) => i.unread).length,
);

// === Screen ===
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all'; // all, unread, friend, challenge, etc.

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(inboxProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    // Filter items based on selection
    final filteredItems = _filter == 'all'
        ? allItems
        : _filter == 'unread'
        ? allItems.where((i) => i.unread).toList()
        : allItems.where((i) => i.type.name == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: _buildAppBar(context, unreadCount),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(filteredItems),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int unreadCount) {
    return AppBar(
      backgroundColor: const Color(0xFF202225),
      elevation: 0,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (unreadCount > 0)
          TextButton.icon(
            onPressed: () {
              // Mark all as read
              final items = ref.read(inboxProvider);
              ref.read(inboxProvider.notifier).state = items.map((item) {
                return InboxItem(
                  id: item.id,
                  type: item.type,
                  title: item.title,
                  body: item.body,
                  timestamp: item.timestamp,
                  actionRoute: item.actionRoute,
                  payload: item.payload,
                  unread: false,
                  icon: item.icon,
                  avatarUrl: item.avatarUrl,
                );
              }).toList();
            },
            icon: const Icon(Icons.done_all, color: Color(0xFF5865F2), size: 18),
            label: const Text(
              'Mark all read',
              style: TextStyle(color: Color(0xFF5865F2)),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      color: const Color(0xFF2F3136),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all', Icons.inbox),
          const SizedBox(width: 8),
          _buildFilterChip('Unread', 'unread', Icons.circle,
              badge: ref.watch(unreadCountProvider)),
          const SizedBox(width: 8),
          _buildFilterChip('Friends', 'friend', Icons.people),
          const SizedBox(width: 8),
          _buildFilterChip('Challenges', 'challenge', Icons.emoji_events),
          const SizedBox(width: 8),
          _buildFilterChip('Achievements', 'achievement', Icons.military_tech),
          const SizedBox(width: 8),
          _buildFilterChip('System', 'system', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, {int? badge}) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFFB9BBBE)),
          const SizedBox(width: 6),
          Text(label),
          if (badge != null && badge > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: const Color(0xFF40444B),
      selectedColor: const Color(0xFF5865F2),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFFB9BBBE),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  Widget _buildNotificationList(List<InboxItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NotificationCard(
          item: item,
          onTap: () => _handleNotificationTap(item),
          onDismiss: () => _dismissNotification(item.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF40444B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Color(0xFF72767D),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Color(0xFF72767D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(InboxItem item) {
    // Mark as read
    final items = ref.read(inboxProvider);
    ref.read(inboxProvider.notifier).state = items.map((i) {
      if (i.id == item.id) {
        return InboxItem(
          id: i.id,
          type: i.type,
          title: i.title,
          body: i.body,
          timestamp: i.timestamp,
          actionRoute: i.actionRoute,
          payload: i.payload,
          unread: false,
          icon: i.icon,
          avatarUrl: i.avatarUrl,
        );
      }
      return i;
    }).toList();

    // Navigate if there's an action
    if (item.actionRoute != null && item.actionRoute!.isNotEmpty) {
      context.push(item.actionRoute!, extra: item.payload);
    }
    // Navigate to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: item),
      ),
    );
  }

  void _dismissNotification(String id) {
    final items = ref.read(inboxProvider);
    ref.read(inboxProvider.notifier).state =
        items.where((i) => i.id != id).toList();
  }
}

// === Custom Notification Card Widget ===
class NotificationCard extends StatelessWidget {
  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFED4245),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3136),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.unread ? config.color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: config.color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: item.unread ? FontWeight.w600 : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.unread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: config.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: const TextStyle(
                            color: Color(0xFFB9BBBE),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: config.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                config.label,
                                style: TextStyle(
                                  color: config.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(item.timestamp),
                              style: const TextStyle(
                                color: Color(0xFF72767D),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  NotificationConfig _getNotificationConfig(InboxType type) {
    switch (type) {
      case InboxType.alert:
        return NotificationConfig(
          color: const Color(0xFFED4245),
          icon: Icons.warning_rounded,
          label: 'ALERT',
        );
      case InboxType.friend:
        return NotificationConfig(
          color: const Color(0xFF3BA55C),
          icon: Icons.people_rounded,
          label: 'SOCIAL',
        );
      case InboxType.achievement:
        return NotificationConfig(
          color: const Color(0xFFFAA61A),
          icon: Icons.military_tech,
          label: 'ACHIEVEMENT',
        );
      case InboxType.challenge:
        return NotificationConfig(
          color: const Color(0xFFF26522),
          icon: Icons.emoji_events,
          label: 'CHALLENGE',
        );
      case InboxType.system:
        return NotificationConfig(
          color: const Color(0xFF8B5CF6),
          icon: Icons.settings,
          label: 'SYSTEM',
        );
      case InboxType.notification:
        return NotificationConfig(
          color: const Color(0xFF5865F2),
          icon: Icons.notifications,
          label: 'INFO',
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}

class NotificationConfig {
  final Color color;
  final IconData icon;
  final String label;

  NotificationConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
