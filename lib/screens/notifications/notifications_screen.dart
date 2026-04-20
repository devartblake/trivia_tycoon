import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/notifications/player_inbox_item.dart';
import '../../game/providers/player_notification_providers.dart';
import '../../core/services/api_service.dart';
import 'notification_detail_screen.dart';

// === Screen ===
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all'; // all, unread, friend, challenge, etc.

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationRealtimeSyncProvider);
    final allItemsAsync = ref.watch(playerNotificationInboxProvider);
    final unreadCount = ref
        .watch(playerNotificationUnreadCountProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0);

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: _buildAppBar(context, unreadCount),
      body: Column(
        children: [
          _buildFilterChips(unreadCount),
          Expanded(
            child: allItemsAsync.when(
              data: (allItems) {
                final filteredItems = _applyFilter(allItems);
                return filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(filteredItems);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
            ),
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
            onPressed: () async {
              try {
                await ref.read(playerNotificationActionsProvider).markAllRead();
              } on ApiRequestException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
              }
            },
            icon:
                const Icon(Icons.done_all, color: Color(0xFF5865F2), size: 18),
            label: const Text(
              'Mark all read',
              style: TextStyle(color: Color(0xFF5865F2)),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterChips(int unreadCount) {
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
              badge: unreadCount),
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

  Widget _buildFilterChip(String label, String value, IconData icon,
      {int? badge}) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFFB9BBBE)),
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

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Color(0xFF72767D)),
            const SizedBox(height: 16),
            const Text(
              'Unable to load notifications',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error is ApiRequestException ? error.message : error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB9BBBE)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(InboxItem item) async {
    if (item.unread) {
      try {
        await ref.read(playerNotificationActionsProvider).markRead(item.id);
      } catch (_) {
        // Allow detail navigation even if mark-read refresh fails.
      }
    }
    // Navigate to detail screen
    context.push('/notifications/detail', extra: item);
  }

  Future<void> _dismissNotification(String id) async {
    try {
      await ref.read(playerNotificationActionsProvider).dismiss(id);
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  List<InboxItem> _applyFilter(List<InboxItem> allItems) {
    if (_filter == 'all') return allItems;
    if (_filter == 'unread') {
      return allItems.where((item) => item.unread).toList(growable: false);
    }
    return allItems
        .where((item) => item.type.name == _filter)
        .toList(growable: false);
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
    final config = inboxTypeConfig(item.type);

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
            color: item.unread
                ? config.color.withValues(alpha: 0.5)
                : Colors.transparent,
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
                                  fontWeight: item.unread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
