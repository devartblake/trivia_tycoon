import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/conversation_models.dart';
import '../../game/providers/message_providers.dart';
import '../profile/dialogs/add_friend_dialog.dart';
import '../search/dialogs/search_dialog.dart';
import 'dialogs/create_dm_dialog.dart';
import 'dialogs/message_request_dialog.dart';
import 'message_detail_screen.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  int _messageRequests = 5;

  // TODO: Replace with actual user ID from auth service
  final String _currentUserId = 'current_user_id';

  @override
  Widget build(BuildContext context) {
    // Watch the conversations from the provider with userId parameter
    final conversations = ref.watch(userConversationsProvider(_currentUserId));
    final unreadCount = ref.watch(unreadMessagesProvider(_currentUserId));

    return _buildScreen(conversations, unreadCount);
  }

  Widget _buildScreen(List<Conversation> conversations, int unreadCount) {
    // Apply search filter
    final filteredConversations = _searchQuery.isEmpty
        ? conversations
        : conversations.where((conv) {
      final title = conv.name ?? 'Direct Message';
      return title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2F3136),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndAdd(unreadCount),
          _buildOnlineGroupsSection(),
          Expanded(
            child: _buildMessageList(filteredConversations),
          ),
        ],
      ),
      floatingActionButton: _buildCreateDMButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF202225),
      elevation: 0,
      title: const Text(
        'Messages',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSearchAndAdd(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF202225),
      child: Row(
        children: [
          _buildIconButton(Icons.search, () => _showSearchDialog()),
          const SizedBox(width: 12),
          _buildIconButton(Icons.mail_outline, () => _showMessageRequestDialog(),
              badgeCount: _messageRequests),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddFriendDialog(),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF40444B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Add Friends',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {int badgeCount = 0}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.white70, size: 20),
            onPressed: onPressed,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
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
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
        itemBuilder: (context, index) => OnlineGroupWidget(group: groups[index]),
      ),
    );
  }

  Widget _buildMessageList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return Container(
        color: const Color(0xFF36393F),
        child: const Center(
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
        ),
      );
    }

    return Container(
      color: const Color(0xFF36393F),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    // Get display title based on conversation type
    final String displayTitle = conversation.name ?? 'Direct Message';

    // Get last message preview (you'll need to implement this in repository)
    final String lastMessagePreview = 'Tap to view messages';

    return InkWell(
      onTap: () => _openConversationDetail(conversation),
      child: Container(
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
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add tags based on conversation type
                      if (conversation.type == ConversationType.challenge)
                        ...[
                          const SizedBox(width: 6),
                          _buildTag('CHALLENGE', const Color(0xFFFAA61A)),
                        ],
                      if (conversation.type == ConversationType.friendRequest)
                        ...[
                          const SizedBox(width: 6),
                          _buildTag('FRIEND REQUEST', const Color(0xFF3BA55C)),
                        ],
                      if (conversation.type == ConversationType.system)
                        ...[
                          const SizedBox(width: 6),
                          _buildTag('SYSTEM', const Color(0xFF5865F2)),
                        ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessagePreview,
                    style: const TextStyle(
                      color: Color(0xFFB9BBBE),
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
                    color: Color(0xFF72767D),
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.volume_up,
                  color: Color(0xFF72767D), size: 20),
              onPressed: () {},
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

  Widget _buildCreateDMButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateDMDialog(),
      backgroundColor: const Color(0xFF5865F2),
      foregroundColor: Colors.white,
      elevation: 6,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_comment_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Create DM',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _openConversationDetail(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(
          conversationId: conversation.id,
          contactName: conversation.name ?? 'Direct Message',
          contactAvatar: conversation.avatar,
          isOnline: true,
          currentActivity: null,
        ),
        fullscreenDialog: false,
      ),
    );
  }

  void _showSearchDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showAddFriendDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddFriendDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showMessageRequestDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageRequestDialog(
          requestCount: _messageRequests,
          onRequestHandled: (accepted) {
            setState(() {
              if (_messageRequests > 0) _messageRequests--;
            });
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showCreateDMDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateDMDialog(),
        fullscreenDialog: true,
      ),
    );
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
    return Container(
      width: 200,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3BA55C).withOpacity(0.3),
          width: 1,
        ),
      ),
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
                      fontWeight: FontWeight.w600),
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
              style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                ...group.avatars.take(4).toList().asMap().entries.map((entry) {
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
    );
  }
}