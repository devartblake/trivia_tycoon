import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/social/group_chat_service.dart';
import '../../core/services/presence/typing_indicator_service.dart';
import '../../core/services/presence/rich_presence_service.dart';
import '../../game/models/group_chat_models.dart';
import '../../ui_components/presence/typing_indicator_widget.dart';
import '../messages/widgets/enhanced_message_tile.dart';
import 'widgets/group_info_header.dart';
import 'widgets/member_presence_grid.dart';
import 'group_settings_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final String currentUserDisplayName;
  final bool userIsPremium;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.currentUserId,
    required this.currentUserDisplayName,
    this.userIsPremium = false,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TypingIndicatorMixin {
  final GroupChatService _groupService = GroupChatService();
  final TypingIndicatorService _typingService = TypingIndicatorService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<GroupChatMessage> _messages = [];
  bool _showMemberList = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // In a real app, this would fetch messages from a backend
    // For now, add some sample messages
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.addAll(_generateSampleMessages());
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  List<GroupChatMessage> _generateSampleMessages() {
    final group = _groupService.getGroup(widget.groupId);
    if (group == null) return [];

    return [
      GroupChatMessage.system(
        groupId: widget.groupId,
        content: 'Group created',
      ),
      GroupChatMessage.system(
        groupId: widget.groupId,
        content: '${group.members.length} members joined',
      ),
    ];
  }

  void _onScroll() {
    // Load more messages when scrolling up
    if (_scrollController.position.pixels <= 100 && !_isLoading) {
      // Load older messages
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupChat>(
      stream: _groupService.watchGroup(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data ?? _groupService.getGroup(widget.groupId);

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(child: Text('This group no longer exists.')),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(group),
          body: Column(
            children: [
              if (_showMemberList) _buildMemberList(group),
              Expanded(
                child: _buildMessageList(group),
              ),
              TypingIndicatorWidget(conversationId: widget.groupId),
              _buildMessageInput(group),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(GroupChat group) {
    final member = group.getMember(widget.currentUserId);
    final canManage = member?.role.canManageMembers ?? false;

    return AppBar(
      title: GestureDetector(
        onTap: () => setState(() => _showMemberList = !_showMemberList),
        child: GroupInfoHeader(
          group: group,
          compact: true,
        ),
      ),
      actions: [
        if (group.onlineMemberCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.onlineMemberCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () => _startGroupCall(group),
          tooltip: 'Start Video Call',
        ),
        if (canManage)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value, group),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Group Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Manage Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'invite',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Invite Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.notifications_off),
                  title: Text('Mute Notifications'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMemberList(GroupChat group) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showMemberList ? 120 : 0,
      child: _showMemberList
          ? Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Members (${group.memberCount})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showFullMemberList(group),
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: MemberPresenceGrid(
              group: group,
              compact: true,
              onMemberTap: (member) => _showMemberProfile(member),
            ),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildMessageList(GroupChat group) {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        if (message.isSystemMessage) {
          return _buildSystemMessage(message);
        }

        return EnhancedMessageTile(
          messageId: message.id,
          senderId: message.senderId,
          senderName: message.senderName,
          content: message.content,
          timestamp: message.timestamp,
          currentUserId: widget.currentUserId,
          currentUserDisplayName: widget.currentUserDisplayName,
          userIsPremium: widget.userIsPremium,
          isFromCurrentUser: message.senderId == widget.currentUserId,
          recipientIds: group.members
              .where((m) => m.userId != message.senderId)
              .map((m) => m.userId)
              .toList(),
          onReply: () => _handleReply(message),
        );
      },
    );
  }

  Widget _buildSystemMessage(GroupChatMessage message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(GroupChat group) {
    final member = group.getMember(widget.currentUserId);
    final canSend = member?.role.canSendMessages ?? false;

    if (!canSend) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.block,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'You can only view messages in this group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAttachmentOptions(group),
              tooltip: 'Add attachment',
            ),
            Expanded(
              child: TypingAwareTextField(
                controller: _messageController,
                conversationId: widget.groupId,
                onSubmitted: (text) => _sendMessage(text, group),
                maxLines: null, // Allows multi-line input
                decoration: InputDecoration(
                  hintText: 'Message ${group.name}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _messageController.text.isEmpty
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage(_messageController.text, group);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text, GroupChat group) {
    if (text.trim().isEmpty) return;

    final message = GroupChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserDisplayName,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });

    HapticFeedback.lightImpact();
    _scrollToBottom();

    // In a real app, send to backend here
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleReply(GroupChatMessage message) {
    // Implement reply functionality
    _messageController.text = '@${message.senderName} ';
  }

  void _handleMenuAction(String action, GroupChat group) {
    switch (action) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupSettingsScreen(
              groupId: widget.groupId,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
        break;
      case 'members':
        _showFullMemberList(group);
        break;
      case 'invite':
        _showInviteDialog(group);
        break;
      case 'mute':
        _toggleMute(group);
        break;
    }
  }

  void _showFullMemberList(GroupChat group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Members (${group.memberCount})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: MemberPresenceGrid(
                  group: group,
                  scrollController: scrollController,
                  onMemberTap: (member) {
                    Navigator.pop(context);
                    _showMemberProfile(member);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberProfile(GroupMember member) {
    // Navigate to member profile
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${member.role.displayName}'),
            Text('Status: ${member.isOnline ? "Online" : "Offline"}'),
            Text('Joined: ${_formatDate(member.joinedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to full profile
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(GroupChat group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text('Invite link functionality coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleMute(GroupChat group) {
    // Implement mute functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications muted')),
    );
  }

  void _startGroupCall(GroupChat group) {
    // Implement group call functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Group Call'),
        content: Text('Start a video call with ${group.onlineMemberCount} online members?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Start call
            },
            child: const Text('Start Call'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(GroupChat group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                // Handle video
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                // Handle file
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions),
              title: const Text('GIF'),
              onTap: () {
                Navigator.pop(context);
                // Handle GIF
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
