import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trivia_tycoon/screens/messages/widgets/message_reactions_widget.dart';
import '../../game/models/message_models.dart';
import '../../game/providers/message_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class MessageDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String contactName;
  final String? contactAvatar;
  final bool isOnline;
  final String? currentActivity;

  const MessageDetailScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.contactAvatar,
    this.isOnline = false,
    this.currentActivity,
  });

  @override
  ConsumerState<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _currentUserId => ref.read(currentUserIdProvider);
  String get _currentUsername {
    if (Hive.isBoxOpen('settings')) {
      final box = Hive.box('settings');
      final name = box.get('username') as String? ?? box.get('playerName') as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Guest';
  }

  // Typing indicator state
  bool _isOtherUserTyping = false;
  bool _amITyping = false;
  Timer? _typingDebounceTimer;
  Timer? _typingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markConversationAsRead(ref, widget.conversationId);
    });

    // Listen for text changes to detect typing
    _messageController.addListener(_onTextChanged);

    // Typing status is observed via conversationTypingStatusProvider in build()
  }

  void _onTextChanged() {
    final hasText = _messageController.text
        .trim()
        .isNotEmpty;

    if (hasText && !_amITyping) {
      // User started typing
      _amITyping = true;
      _broadcastTypingStatus(true);

      // Set timeout to stop typing after 5 seconds of no changes
      _typingTimeoutTimer?.cancel();
      _typingTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (_amITyping) {
          _amITyping = false;
          _broadcastTypingStatus(false);
        }
      });
    } else if (!hasText && _amITyping) {
      // User cleared text
      _amITyping = false;
      _broadcastTypingStatus(false);
      _typingTimeoutTimer?.cancel();
    } else if (hasText) {
      // User is still typing, reset timeout
      _typingTimeoutTimer?.cancel();
      _typingTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (_amITyping) {
          _amITyping = false;
          _broadcastTypingStatus(false);
        }
      });
    }

    // Debounce the typing broadcast (send at most once per 2 seconds)
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (_amITyping) {
        _broadcastTypingStatus(true);
      }
    });
  }

  void _broadcastTypingStatus(bool isTyping) {
    sendTypingStatus(
      ref,
      conversationId: widget.conversationId,
      userId: _currentUserId,
      userName: _currentUsername,
      isTyping: isTyping,
    );
    LogManager.debug('[Chat] Typing broadcast: $isTyping for ${widget.conversationId}');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _scrollController.dispose();
    _typingDebounceTimer?.cancel();
    _typingTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch messages for this conversation
    final messages = ref.watch(
        conversationMessagesProvider(widget.conversationId));

    final typingStatus = ref.watch(conversationTypingStatusProvider(widget.conversationId));
    _isOtherUserTyping = typingStatus.maybeWhen(
      data: (statuses) => statuses.any((s) => s.userId != _currentUserId && s.isTyping),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(messages)),
          if (_isOtherUserTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF5865F2),
            backgroundImage: widget.contactAvatar != null
                ? AssetImage(widget.contactAvatar!)
                : null,
            child: widget.contactAvatar == null
                ? Text(
              widget.contactName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF40444B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value + delay) % 1.0);
        final opacity = (animValue < 0.5)
            ? animValue * 2
            : (1.0 - animValue) * 2;

        return Opacity(
          opacity: 0.3 + (opacity * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Loop the animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      // Stop typing indicator
      _amITyping = false;
      _broadcastTypingStatus(false);
      _typingDebounceTimer?.cancel();
      _typingTimeoutTimer?.cancel();

      _messageController.clear();

      await sendTextMessage(
        ref,
        conversationId: widget.conversationId,
        senderId: _currentUserId,
        senderName: 'You',
        content: text,
      );

      HapticFeedback.lightImpact();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _messageController.text = text;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF36393F),
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF5865F2),
            backgroundImage: widget.contactAvatar != null
                ? AssetImage(widget.contactAvatar!)
                : null,
            child: widget.contactAvatar == null
                ? Text(
              widget.contactName.isNotEmpty
                  ? widget.contactName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.currentActivity != null && widget.isOnline)
                  Text(
                    widget.currentActivity!,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  if (widget.isOnline)
                    const Text(
                      'Online',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.white70),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white70),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF72767D), size: 64),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Color(0xFF72767D),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(
                color: Color(0xFF72767D),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final showSenderInfo = previousMessage == null ||
            previousMessage.senderId != message.senderId ||
            message.timestamp
                .difference(previousMessage.timestamp)
                .inMinutes > 5;

        return _buildMessageBubble(message, showSenderInfo);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool showSenderInfo) {
    final isMe = message.senderId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(top: showSenderInfo ? 16 : 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showSenderInfo)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5865F2),
              backgroundImage: widget.contactAvatar != null
                  ? AssetImage(widget.contactAvatar!)
                  : null,
              child: widget.contactAvatar == null
                  ? Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            )
          else
            if (!isMe)
              const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderInfo && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                _buildMessageContent(message, isMe),
                _buildMessageMetadata(message, isMe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    // Handle different message types
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(message, isMe);

      case MessageType.system:
      case MessageType.systemNotification:
        return _buildSystemMessage(message);

      case MessageType.challenge:
      case MessageType.challengeRequest:
      case MessageType.challengeAccepted:
      case MessageType.challengeResult:
        return _buildChallengeMessage(message);

      case MessageType.friendRequest:
      case MessageType.friendAccepted:
        return _buildFriendRequestMessage(message);

      case MessageType.image:
        return _buildImageMessage(message, isMe);

      case MessageType.gameInvite:
        return _buildGameInviteMessage(message);

      case MessageType.lifeRequest:
        return _buildLifeRequestMessage(message);

      case MessageType.gift:
        return _buildGiftMessage(message);

      case MessageType.achievement:
        return _buildAchievementMessage(message);

      case MessageType.groupInvite:
        return _buildGroupInviteMessage(message);
    }
  }

// Helper methods for each message type
  Widget _buildTextMessage(Message message, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showReactionPicker(message),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF5865F2) : const Color(0xFF40444B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (message.reactions.isNotEmpty)
            MessageReactions(reactions: message.reactions),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.content,
        style: const TextStyle(
          color: Color(0xFFB9BBBE),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChallengeMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAA61A).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFFFAA61A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFAA61A), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3BA55C).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFF3BA55C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add, color: Color(0xFF3BA55C), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Message message, bool isMe) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isMe ? const Color(0xFF5865F2) : const Color(0xFF40444B),
      ),
      child: message.imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          message.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '[Image unavailable]',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      )
          : const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '[Image]',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildGameInviteMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5865F2).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFF5865F2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_esports, color: Color(0xFF5865F2), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeRequestMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFED4245).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFFED4245)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFED4245), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF26522).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFFF26522)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, color: Color(0xFFF26522), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE75C).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFFFEE75C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFFEE75C), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInviteMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3BA55C).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFF3BA55C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_add, color: Color(0xFF3BA55C), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Add reaction picker
  void _showReactionPicker(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F3136),
      builder: (context) {
        final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: reactions.map((emoji) => GestureDetector(
                onTap: () {
                  final storage = ref.read(messageStorageServiceProvider);
                  final updated = [...message.reactions];
                  if (!updated.contains(emoji)) updated.add(emoji);
                  storage.updateMessage(message.id, message.copyWith(reactions: updated));
                  LogManager.debug('[Chat] Reaction $emoji added to ${message.id}');
                  Navigator.pop(context);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F3136),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text('Photo & Video Library', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  LogManager.debug('[Chat] Attachment selected: ${picked.path}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white70),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  LogManager.debug('[Chat] Camera photo: ${picked.path}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.white70),
              title: const Text('File', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.isNotEmpty) {
                  LogManager.debug('[Chat] File selected: ${result.files.first.name}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageMetadata(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(message.timestamp),
            style: const TextStyle(
              color: Color(0xFF72767D),
              fontSize: 11,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              color: message.isRead ? Colors.blueAccent : const Color(
                  0xFF72767D),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
        timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today - show time only
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now
        .difference(timestamp)
        .inDays < 7) {
      // This week - show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      color: const Color(0xFF40444B),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3136),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Message ${widget.contactName}',
                    hintStyle: const TextStyle(color: Color(0xFF72767D)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (text) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF5865F2)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
