import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/message_providers.dart' as msg;
import '../../../game/providers/riverpod_providers.dart';

class StandardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String ageGroup;
  final bool showSearch;
  final bool showChat;
  final bool showNotifications;

  const StandardAppBar({
    super.key,
    required this.title,
    required this.ageGroup,
    this.showSearch = true,
    this.showChat = true,
    this.showNotifications = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = _getThemeData();
    ref.watch(notificationRealtimeSyncProvider);

    // Watch the async currentUserId
    final currentUserIdAsync = ref.watch(currentUserIdProvider);
    final unreadNotificationsAsync =
        ref.watch(playerNotificationUnreadCountProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: theme['gradient'] as LinearGradient,
          boxShadow: [
            BoxShadow(
              color: (theme['shadowColor'] as Color).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        if (showSearch)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => context.push('/search'),
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        if (showChat)
          // Handle async userId state
          currentUserIdAsync.when(
            data: (userId) => _buildChatButton(ref, userId),
            loading: () =>
                _buildChatButton(ref, 'guest'), // Show button in loading state
            error: (_, __) =>
                _buildChatButton(ref, 'guest'), // Show button in error state
          ),
        if (showNotifications)
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final unreadNotifications =
                      unreadNotificationsAsync.maybeWhen(
                    data: (value) => value,
                    orElse: () => 0,
                  );
                  if (unreadNotifications > 0) {
                    return Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatButton(WidgetRef ref, String userId) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              // Use context from ref to navigate
              final context = ref.context;
              context.push('/messages');
            },
            icon: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            // Now we can use the resolved userId
            final unreadMessages =
                ref.watch(msg.unreadMessagesProvider(userId));
            if (unreadMessages > 0) {
              return Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unreadMessages > 99 ? '99+' : unreadMessages.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _getThemeData() {
    switch (ageGroup) {
      case 'kids':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFF8E53),
              Color(0xFFFF6B9D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFFFF6B6B),
        };
      case 'teens':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF4ECDC4),
              Color(0xFF44A08D),
              Color(0xFF093637),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF4ECDC4),
        };
      case 'adults':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF667eea),
        };
      default:
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF6366F1),
        };
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
