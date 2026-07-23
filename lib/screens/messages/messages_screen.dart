import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/navigation_extensions.dart';
import '../../core/helpers/responsive_layout.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/neon_button.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../../game/models/conversation_models.dart';
import '../../game/providers/message_providers.dart';
import '../../synaptix/mode/synaptix_mode_provider.dart';
import 'package:synaptix/ui_components/spin_wheel/core/sound_manager.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  int _messageRequests = 5;
  Conversation? _previewConversation;

  String get _currentUserId => ref.read(currentUserIdProvider);

  @override
  void initState() {
    super.initState();
    // Synaptix analytics — Circles surface opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = ref.read(synaptixModeProvider);
      ref.read(analyticsServiceProvider).trackEvent('synaptix_surface_opened', {
        'surface': 'circles',
        'synaptix_mode': mode.name,
        'entry_point': 'navigation',
        'audience_segment': mode.name,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(messageRealtimeSyncProvider);
    final conversationsAsync =
        ref.watch(userConversationsProvider(_currentUserId));
    final unreadCount = ref.watch(unreadMessagesProvider(_currentUserId));

    return conversationsAsync.when(
      data: (conversations) => _buildScreen(conversations, unreadCount),
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF36393F),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFF36393F),
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(List<Conversation> conversations, int unreadCount) {
    // Apply search filter
    final filteredConversations = _searchQuery.isEmpty
        ? conversations
        : conversations.where((conv) {
            final title = conv.name ?? 'Direct Message';
            return title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppBreakpoints.classify(constraints.maxWidth);
        final previewConversation = _previewConversation != null &&
                filteredConversations
                    .any((item) => item.id == _previewConversation!.id)
            ? _previewConversation
            : null;

        return SynaptixScaffold(
          appBar: GlassAppBar(
            leading: IconButton(
              onPressed: () => context.safeBack(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: const GlowText('Messages'),
          ),
          body: SafeArea(
            child: layout.isDesktop
                ? _buildDesktopMessagesLayout(
                    filteredConversations,
                    unreadCount,
                    previewConversation,
                  )
                : AppResponsiveWidth(
                    tabletMaxWidth: 760,
                    desktopMaxWidth: 860,
                    padding: EdgeInsets.zero,
                    child: _buildMessagesColumn(
                      filteredConversations,
                      unreadCount,
                    ),
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDMDialog(),
            backgroundColor: const Color(0xFF5865F2),
            child: const Icon(Icons.add_comment_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildMessagesColumn(
    List<Conversation> conversations,
    int unreadCount, {
    bool framed = false,
  }) {
    final content = Column(
      children: [
        _buildSearchAndAdd(unreadCount),
        _buildOnlineGroupsSection(),
        Expanded(
          child: _buildMessageList(conversations),
        ),
      ],
    );

    if (!framed) return content;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF36393F),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: content,
    );
  }

  Widget _buildDesktopMessagesLayout(
    List<Conversation> conversations,
    int unreadCount,
    Conversation? previewConversation,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 430,
                child: _buildMessagesColumn(
                  conversations,
                  unreadCount,
                  framed: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildConversationPreview(previewConversation),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
            onPressed: () => context.safeBack(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: const Text(
        'Messages',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchAndAdd(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 360;
          final actions = Row(
            mainAxisSize: stack ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _buildIconButton(Icons.search, () => _showSearchDialog()),
              const SizedBox(width: 12),
              _buildIconButton(
                Icons.mail_outline,
                () => _showMessageRequestDialog(),
                badgeCount: _messageRequests,
              ),
            ],
          );

          final addFriend = NeonButton(
            onPressed: () => _showAddFriendDialog(),
            height: 48,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Add Friends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                actions,
                const SizedBox(height: 12),
                addFriend,
              ],
            );
          }

          return Row(
            children: [
              actions,
              const SizedBox(width: 12),
              Expanded(child: addFriend),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {int badgeCount = 0}) {
    return AdaptiveGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (badgeCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineGroupsSection() {
    final groups = [
      OnlineGroup(
        id: '1',
        name: 'Study Squad',
        memberCount: 8,
        onlineCount: 3,
        avatars: [
          'assets/images/avatars/avatar-1.png',
          'assets/images/avatars/avatar-2.png',
          'assets/images/avatars/avatar-3.png',
        ],
        activity: 'Working on Math homework',
      ),
      OnlineGroup(
        id: '2',
        name: 'Gaming Crew',
        memberCount: 12,
        onlineCount: 6,
        avatars: [
          'assets/images/avatars/avatar-4.png',
          'assets/images/avatars/avatar-5.png',
        ],
        activity: 'Playing Valorant',
      ),
    ];

    return Container(
      height: 120,
      color: const Color(0xFF202225),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: groups.length,
        itemBuilder: (context, index) =>
            OnlineGroupWidget(group: groups[index]),
      ),
    );
  }

  Widget _buildMessageList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF72767D), size: 64),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Color(0xFF72767D),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    // Get display title based on conversation type
    final String displayTitle = conversation.displayTitle;
    final String lastMessagePreview = conversation.lastMessagePreview;

    return AdaptiveGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.zero,
      onTap: () {
        soundManager.playButtonClick();
        if (AppResponsive.layoutOf(context).isDesktop) {
          setState(() => _previewConversation = conversation);
        } else {
          _openConversationDetail(conversation);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _previewConversation?.id == conversation.id
              ? const Color(0xFF5865F2).withValues(alpha: 0.16)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildConversationAvatar(conversation),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add tags based on conversation type
                      if (conversation.type == ConversationType.challenge) ...[
                        const SizedBox(width: 6),
                        _buildTag('CHALLENGE', const Color(0xFFFAA61A)),
                      ],
                      if (conversation.type ==
                          ConversationType.friendRequest) ...[
                        const SizedBox(width: 6),
                        _buildTag('FRIEND REQUEST', const Color(0xFF3BA55C)),
                      ],
                      if (conversation.type == ConversationType.system) ...[
                        const SizedBox(width: 6),
                        _buildTag('SYSTEM', const Color(0xFF5865F2)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessagePreview,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.lastMessageTime != null
                      ? _formatTimestamp(conversation.lastMessageTime!)
                      : 'New',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5865F2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConversationPreview(Conversation? conversation) {
    if (conversation == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF36393F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, color: Color(0xFF72767D), size: 72),
              SizedBox(height: 18),
              Text(
                'Select a conversation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Messages open here on wider screens.',
                style: TextStyle(color: Color(0xFFB9BBBE), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildConversationAvatar(conversation),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessagePreview,
                      style: const TextStyle(
                        color: Color(0xFFB9BBBE),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openConversationDetail(conversation),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5865F2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationAvatar(Conversation conversation) {
    final String displayText = conversation.name?.isNotEmpty == true
        ? conversation.name!.substring(0, 1).toUpperCase()
        : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF5865F2),
          backgroundImage: conversation.avatar != null
              ? AssetImage(conversation.avatar!)
              : null,
          child: conversation.avatar == null
              ? Text(
                  displayText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    }
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  void _openConversationDetail(Conversation conversation) {
    context.push(
      '/messages/detail/${conversation.id}',
      extra: {
        'contactName': conversation.name ?? 'Direct Message',
        'contactAvatar': conversation.avatar,
        'isOnline': true,
        'currentActivity': null,
      },
    );
  }

  void _showSearchDialog() {
    context.push('/messages/search');
  }

  void _showAddFriendDialog() {
    context.push('/messages/add-friend');
  }

  void _showMessageRequestDialog() {
    context.push('/messages/requests', extra: {
      'requestCount': _messageRequests,
      'onRequestHandled': (bool accepted) {
        setState(() {
          if (_messageRequests > 0) _messageRequests--;
        });
      },
    });
  }

  void _showCreateDMDialog() {
    context.push('/messages/new');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Keep these classes for online groups section
class OnlineGroup {
  final String id;
  final String name;
  final int memberCount;
  final int onlineCount;
  final List<String> avatars;
  final String activity;

  OnlineGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.onlineCount,
    required this.avatars,
    required this.activity,
  });
}

class OnlineGroupWidget extends StatelessWidget {
  final OnlineGroup group;

  const OnlineGroupWidget({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3BA55C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.onlineCount}/${group.memberCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                group.activity,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 24,
              child: Stack(
                children: [
                  ...group.avatars
                      .take(4)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final avatar = entry.value;
                    return Positioned(
                      left: index * 16.0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF40444B),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundImage: AssetImage(avatar),
                        ),
                      ),
                    );
                  }),
                  if (group.avatars.length > 4)
                    Positioned(
                      left: 4 * 16.0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF40444B),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFF72767D),
                          child: Text(
                            '+${group.avatars.length - 4}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
