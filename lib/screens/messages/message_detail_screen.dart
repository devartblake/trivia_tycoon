import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// A simple model for chat messages, now with reactions.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool hasImage;
  final String? imageUrl;
  final List<String> reactions; // Added for reactions
  bool isRead; // Added for read receipts

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.hasImage = false,
    this.imageUrl,
    this.reactions = const [],
    this.isRead = false,
  });
}

class MessageDetailScreen extends StatefulWidget {
  final String contactName;
  final String? contactAvatar;
  final bool isOnline;
  final String? currentActivity;

  const MessageDetailScreen({
    super.key,
    required this.contactName,
    this.contactAvatar,
    this.isOnline = false,
    this.currentActivity,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _loadSampleMessages();
    _simulateTyping();
  }

  void _loadSampleMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          senderId: 'other',
          senderName: 'LMX_Blade',
          content: 'Lmao, you need a Guyver suit like the anime.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          hasImage: true,
          imageUrl: 'assets/images/sample_anime.jpg',
          reactions: ['😂', '👍'],
          isRead: true,
        ),
        ChatMessage(
          id: '2',
          senderId: 'other',
          senderName: 'LMX_Blade',
          content: 'What is this game you\'re playing with the Vice City Guild?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          isRead: true,
        ),
        ChatMessage(
          id: '3',
          senderId: 'me',
          senderName: 'CavemanYeti',
          content: 'Throne and liberty',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          isRead: true,
        ),
      ]);
    });
  }

  // --- Feature: Typing Indicator Simulation ---
  void _simulateTyping() {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isOtherUserTyping = true);
        _scrollToBottom();
      }
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _isOtherUserTyping = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (_isOtherUserTyping) const TypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF36393F),
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.contactAvatar != null
                ? AssetImage(widget.contactAvatar!)
                : null,
            child: widget.contactAvatar == null
                ? Text(widget.contactName.isNotEmpty ? widget.contactName[0] : '?')
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
                else if (widget.isOnline)
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

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final previousMessage = index > 0 ? _messages[index - 1] : null;
        final showSenderInfo = previousMessage == null ||
            previousMessage.senderId != message.senderId ||
            message.timestamp.difference(previousMessage.timestamp).inMinutes > 5;

        return _buildMessageBubble(message, showSenderInfo);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showSenderInfo) {
    final isMe = message.senderId == 'me';
    return Padding(
      padding: EdgeInsets.only(top: showSenderInfo ? 16 : 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showSenderInfo)
            CircleAvatar(radius: 16, backgroundImage: AssetImage(widget.contactAvatar!))
          else if (!isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderInfo && !isMe)
                  Text(
                    message.senderName,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                if (showSenderInfo && !isMe) const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: () => _showReactionPicker(message),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF5865F2)
                          : const Color(0xFF40444B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                if (message.reactions.isNotEmpty)
                  MessageReactions(reactions: message.reactions),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      color: message.isRead ? Colors.blueAccent : Colors.grey,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Feature: Message Reactions ---
  void _showReactionPicker(ChatMessage message) {
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
                  setState(() {
                    if (message.reactions.contains(emoji)) {
                      message.reactions.remove(emoji);
                    } else {
                      message.reactions.add(emoji);
                    }
                  });
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      color: const Color(0xFF40444B),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70),
              onPressed: () {},
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF5865F2)),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        senderName: 'You',
        content: text.trim(),
        timestamp: DateTime.now(),
      ));
      // Mark previous messages as read
      for (var msg in _messages.where((m) => m.senderId != 'me')) {
        msg.isRead = true;
      }
    });
    _messageController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();
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
}

// --- New Widget for Typing Indicator ---
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: Color(0xFF40444B)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF40444B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Typing...',
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// --- New Widget for Message Reactions ---
class MessageReactions extends StatelessWidget {
  final List<String> reactions;
  const MessageReactions({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) => Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF5865F2).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }
}
