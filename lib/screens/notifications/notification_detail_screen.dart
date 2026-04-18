import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifications_screen.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final InboxItem notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Mark as read when opened
    _markAsRead();
  }

  void _markAsRead() {
    // Delay the provider modification until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = ref.read(inboxProvider);
      ref.read(inboxProvider.notifier).state = items.map((i) {
        if (i.id == widget.notification.id) {
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
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(widget.notification.type);

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(config),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(config),
                    _buildContent(),
                    _buildMetadata(),
                    _buildActions(config),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(NotificationConfig config) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF202225),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () {
          if (GoRouter.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/notifications');
          }
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.color,
                config.color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: _PatternPainter(),
                  ),
                ),
              ),
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    config.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationConfig config) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: config.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  config.label,
                  style: TextStyle(
                    color: config.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                color: const Color(0xFF72767D),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _formatFullTimestamp(widget.notification.timestamp),
                style: const TextStyle(
                  color: Color(0xFF72767D),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.notification.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.notification.body,
            style: const TextStyle(
              color: Color(0xFFB9BBBE),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailedContent(),
        ],
      ),
    );
  }

  Widget _buildDetailedContent() {
    // Generate different content based on notification type
    switch (widget.notification.type) {
      case InboxType.friend:
        return _buildFriendRequestDetails();
      case InboxType.challenge:
        return _buildChallengeDetails();
      case InboxType.achievement:
        return _buildAchievementDetails();
      case InboxType.system:
        return _buildSystemUpdateDetails();
      case InboxType.alert:
        return _buildAlertDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFriendRequestDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF3BA55C),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sarah Chen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@sarah_chen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Level 15 • 2,500 points',
                  style: TextStyle(
                    color: Color(0xFF72767D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFAA61A), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trivia Duel Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Category', 'General Knowledge', Icons.category),
          const SizedBox(height: 8),
          _buildInfoRow('Questions', '10 Questions', Icons.quiz),
          const SizedBox(height: 8),
          _buildInfoRow('Time Limit', '5 minutes', Icons.timer),
          const SizedBox(height: 8),
          _buildInfoRow('Wager', '100 points', Icons.monetization_on),
        ],
      ),
    );
  }

  Widget _buildAchievementDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFAA61A).withValues(alpha: 0.2),
            const Color(0xFFFAA61A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFAA61A).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFFAA61A), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Quiz Master',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete 100 quizzes',
            style: TextStyle(
              color: Color(0xFFB9BBBE),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAA61A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '+500 XP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemUpdateDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s New',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildUpdateItem('New multiplayer mode', Icons.groups),
        _buildUpdateItem('Improved performance', Icons.speed),
        _buildUpdateItem('Bug fixes and improvements', Icons.build),
        _buildUpdateItem('New achievement system', Icons.military_tech),
      ],
    );
  }

  Widget _buildAlertDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFED4245).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFED4245).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFED4245), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This is an important alert that requires your attention.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF72767D), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF72767D),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB9BBBE),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildMetadataItem(
            Icons.visibility_outlined,
            'Received',
            _formatFullTimestamp(widget.notification.timestamp),
          ),
          const SizedBox(width: 24),
          _buildMetadataItem(
            Icons.notifications_active_outlined,
            'Status',
            widget.notification.unread ? 'Unread' : 'Read',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF72767D), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF72767D),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(NotificationConfig config) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primary action based on type
          if (widget.notification.type == InboxType.friend)
            _buildPrimaryButton(
              'Accept Friend Request',
              config.color,
              Icons.person_add,
                  () {
                // Handle accept friend request
                _showSuccessSnackBar('Friend request accepted!');
                context.pop();
              },
            ),
          if (widget.notification.type == InboxType.challenge)
            _buildPrimaryButton(
              'Accept Challenge',
              config.color,
              Icons.emoji_events,
                  () {
                // Handle accept challenge
                context.go('/multiplayer/challenge/${widget.notification.id}');
              },
            ),
          if (widget.notification.type == InboxType.system)
            _buildPrimaryButton(
              'Update Now',
              config.color,
              Icons.download,
                  () {
                // Handle update
                _showSuccessSnackBar('Update started!');
              },
            ),

          const SizedBox(height: 12),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  'Share',
                  Icons.share,
                      () => _handleShare(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  'Delete',
                  Icons.delete_outline,
                      () => _handleDelete(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
      String label,
      Color color,
      IconData icon,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      String label,
      IconData icon,
      VoidCallback onTap,
      ) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF40444B)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F3136),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF72767D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _handleShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Colors.white),
              title: const Text('Save', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Notification saved!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFED4245)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFED4245))),
              onTap: () {
                Navigator.pop(context);
                _handleDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    _showSuccessSnackBar('Sharing functionality coming soon!');
  }

  void _handleDelete() {
    final items = ref.read(inboxProvider);
    ref.read(inboxProvider.notifier).state =
        items.where((i) => i.id != widget.notification.id).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Color(0xFFED4245),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3BA55C),
        behavior: SnackBarBehavior.floating,
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

  String _formatFullTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// Custom painter for decorative pattern
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw decorative circles
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.15), size.height * 0.3),
        20 + i * 10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
