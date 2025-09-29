import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../profile/dialogs/add_friend_dialog.dart';
import '../search/dialogs/search_dialog.dart';
import 'dialogs/create_dm_dialog.dart';
import 'dialogs/message_request_dialog.dart';
import 'message_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _messageRequests = 5; // Example number of pending message requests

  final List<Message> _messages = [
    Message(
      id: '1',
      name: 'TIMBS N HOGANS',
      subtitle: 'Yeti Kenobi, and 3 o...',
      avatarUrl: 'assets/images/avatars/avatar-1.png',
      status: MessageStatus.online,
      activity: "Jinxy's Cat Cafe",
      lastSeen: 'now',
      hasNotification: true,
      notificationCount: 2,
    ),
    Message(
      id: '2',
      name: 'Discord',
      subtitle: 'Updates to Server Boosting',
      avatarUrl: 'assets/images/avatars/avatar-2.png',
      status: MessageStatus.online,
      activity: '',
      lastSeen: '3mo',
      isOfficial: true,
    ),
    Message(
      id: '3',
      name: 'CavemanYeti',
      subtitle: 'Throne and liberty',
      avatarUrl: 'assets/images/avatars/avatar-3.png',
      status: MessageStatus.online,
      activity: '',
      lastSeen: '11mo',
    ),
    Message(
      id: '4',
      name: 'WantedGalaxy607',
      subtitle: 'Playing Warframe',
      avatarUrl: 'assets/images/avatars/avatar-4.png',
      status: MessageStatus.online,
      activity: 'WUWA',
      lastSeen: '1y',
    ),
    Message(
      id: '5',
      name: 'Just1KillPlz',
      subtitle: 'Kick',
      avatarUrl: 'assets/images/avatars/avatar-5.png',
      status: MessageStatus.away,
      activity: '',
      lastSeen: '2y',
    ),
    Message(
      id: '6',
      name: 'Midjourney Bot',
      subtitle: 'Your free trial has come to an end. Please...',
      avatarUrl: 'assets/images/avatars/avatar-6.png',
      status: MessageStatus.online,
      activity: '',
      lastSeen: '2y',
      isBot: true,
    ),
    Message(
      id: '7',
      name: 'javien',
      subtitle: 'Playing THRONE AND LIBERTY',
      avatarUrl: 'assets/images/avatars/avatar-7.png',
      status: MessageStatus.online,
      activity: '',
      lastSeen: '2y',
    ),
    Message(
      id: '8',
      name: 'itty',
      subtitle: 'its a good work horse machine',
      avatarUrl: 'assets/images/avatars/avatar-8.png',
      status: MessageStatus.offline,
      activity: 'TING',
      lastSeen: '2y',
    ),
    Message(
      id: '9',
      name: 'phobia0290',
      subtitle: 'one piece problem its alot of fillers... get strai...',
      avatarUrl: 'assets/images/avatars/avatar-9.png',
      status: MessageStatus.offline,
      activity: '',
      lastSeen: '3y',
    ),
    Message(
      id: '10',
      name: 'MEE6',
      subtitle: 'Playing /mee6-games',
      avatarUrl: 'assets/images/avatars/avatar-10.png',
      status: MessageStatus.online,
      activity: '',
      lastSeen: '3y',
      isBot: true,
    ),

  ];

  List<Message> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    return _messages
        .where((message) =>
    message.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        message.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F3136),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndAdd(),
          _buildOnlineGroupsSection(),
          Expanded(
            child: _buildMessageList(),
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

  Widget _buildSearchAndAdd() {
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

  Widget _buildMessageList() {
    return Container(
      color: const Color(0xFF36393F),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredMessages.length,
        itemBuilder: (context, index) {
          final message = _filteredMessages[index];
          return _buildMessageTile(message);
        },
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    return InkWell(
      onTap: () => _openMessageDetail(message),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(message),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (message.isOfficial) ...[
                        const SizedBox(width: 6),
                        _buildTag('OFFICIAL', const Color(0xFF5865F2)),
                      ],
                      if (message.activity.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildTag(message.activity, const Color(0xFF3BA55C)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.subtitle,
                    style: const TextStyle(
                        color: Color(0xFFB9BBBE), fontSize: 14),
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
                Text(message.lastSeen,
                    style: const TextStyle(
                        color: Color(0xFF72767D), fontSize: 12)),
                const SizedBox(height: 4),
                if (message.hasNotification)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFF5865F2), shape: BoxShape.circle),
                    child: Text(
                      message.notificationCount.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAvatar(Message message) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF5865F2),
          child: message.avatarUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              message.avatarUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildAvatarFallback(message.name),
            ),
          )
              : _buildAvatarFallback(message.name),
        ),
        if (message.status != MessageStatus.offline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getStatusColor(message.status),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF36393F), width: 3),
              ),
            ),
          ),
        if (message.isBot)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF36393F), width: 2),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Text(
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.online:
        return const Color(0xFF3BA55C);
      case MessageStatus.away:
        return const Color(0xFFFAA61A);
      case MessageStatus.busy:
        return const Color(0xFFED4245);
      case MessageStatus.offline:
        return const Color(0xFF747F8D);
    }
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

  void _openMessageDetail(Message message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(
          contactName: message.name,
          contactAvatar: message.avatarUrl.isNotEmpty ? message.avatarUrl : null,
          isOnline: message.status == MessageStatus.online,
          currentActivity: message.activity.isNotEmpty ? message.activity : null,
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
}

class Message {
  final String id;
  final String name;
  final String subtitle;
  final String avatarUrl;
  final MessageStatus status;
  final String activity;
  final String lastSeen;
  final bool hasNotification;
  final int notificationCount;
  final bool isOfficial;
  final bool isBot;

  Message({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.status,
    required this.activity,
    required this.lastSeen,
    this.hasNotification = false,
    this.notificationCount = 0,
    this.isOfficial = false,
    this.isBot = false,
  });
}

enum MessageStatus {
  online,
  away,
  busy,
  offline,
}

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