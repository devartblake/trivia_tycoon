import 'package:flutter/material.dart';
import '../../../core/services/presence/message_reaction_service.dart';
import '../../../core/services/presence/rich_presence_service.dart';
import '../../../core/services/presence/read_receipt_service.dart';
import '../../../game/models/message_reaction.dart';
import '../../../game/models/user_presence_models.dart';
import '../../../ui_components/presence/message_reaction_picker.dart';
import '../../../ui_components/presence/presence_status_widget.dart';
import '../../../ui_components/presence/rich_presence_indicator.dart';

class EnhancedMessageTile extends StatefulWidget {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String currentUserId;
  final String currentUserDisplayName;
  final bool userIsPremium;
  final bool isFromCurrentUser;
  final List<String>? recipientIds;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EnhancedMessageTile({
    super.key,
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.currentUserId,
    required this.currentUserDisplayName,
    this.userIsPremium = false,
    required this.isFromCurrentUser,
    this.recipientIds,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<EnhancedMessageTile> createState() => _EnhancedMessageTileState();
}

class _EnhancedMessageTileState extends State<EnhancedMessageTile> {
  final RichPresenceService _presenceService = RichPresenceService();
  final ReadReceiptService _receiptService = ReadReceiptService();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isFromCurrentUser) ...[
            _buildPresenceAwareAvatar(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: widget.isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageHeader(),
                const SizedBox(height: 4),
                _buildMessageBubble(),
                _buildMessageReactions(),
                if (widget.isFromCurrentUser) _buildReadStatus(),
              ],
            ),
          ),
          if (widget.isFromCurrentUser) ...[
            const SizedBox(width: 12),
            _buildPresenceAwareAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildPresenceAwareAvatar() {
    return StreamBuilder<UserPresence?>(
      stream: _presenceService.watchUserPresence(widget.senderId),
      builder: (context, snapshot) {
        final presence = snapshot.data;

        return Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: PresenceStatusIndicator(
                status: presence?.status ?? PresenceStatus.offline,
                size: 12,
                showBorder: true,
              ),
            ),
            if (presence?.gameActivity != null)
              Positioned(
                top: -2,
                right: -2,
                child: _buildGameActivityIndicator(presence!.gameActivity!),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGameActivityIndicator(GameActivity activity) {
    // Get icon based on game state
    IconData? icon;
    switch (activity.gameState) {
      case GameState.lobby:
        icon = Icons.people;
        break;
      case GameState.waiting:
        icon = Icons.schedule;
        break;
      case GameState.playing:
        icon = Icons.sports_esports;
        break;
      case GameState.paused:
        icon = Icons.pause;
        break;
      case GameState.finished:
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 10,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildMessageHeader() {
    return Row(
      mainAxisAlignment: widget.isFromCurrentUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!widget.isFromCurrentUser) ...[
          Text(
            widget.senderName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(width: 8),
          _buildPresenceIndicator(),
        ],
        const Spacer(),
        Text(
          _formatTimestamp(widget.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildPresenceIndicator() {
    return StreamBuilder<UserPresence?>(
      stream: _presenceService.watchUserPresence(widget.senderId),
      builder: (context, snapshot) {
        final presence = snapshot.data;
        if (presence == null) return const SizedBox.shrink();

        return RichPresenceIndicator(
          presence: presence,
          showDetailedInfo: false,
          compact: true,
        );
      },
    );
  }

  Widget _buildMessageBubble() {
    return GestureDetector(
      onLongPress: _showMessageActions,
      onDoubleTap: _quickReaction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isFromCurrentUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: widget.isFromCurrentUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: widget.isFromCurrentUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: Text(
          widget.content,
          style: TextStyle(
            color: widget.isFromCurrentUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageReactions() {
    return MessageReactionBar(
      messageId: widget.messageId,
      currentUserId: widget.currentUserId,
      onAddReaction: _showReactionPicker,
      onReactionTapped: () {
        // Handle reaction tapped
      },
    );
  }

  Widget _buildReadStatus() {
    if (widget.recipientIds == null || widget.recipientIds!.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<MessageReadStatus?>(
      stream: _receiptService.watchMessageStatus(widget.messageId),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                _getStatusIcon(status),
                size: 12,
                color: _getStatusColor(status, context),
              ),
              const SizedBox(width: 4),
              Text(
                _receiptService.getStatusSummary(widget.messageId),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(MessageReadStatus status) {
    if (status.hasFailures) return Icons.error_outline;
    if (status.isReadByAll) return Icons.done_all;
    if (status.isDeliveredToAll) return Icons.done;
    return Icons.schedule;
  }

  Color _getStatusColor(MessageReadStatus status, BuildContext context) {
    if (status.hasFailures) return Theme.of(context).colorScheme.error;
    if (status.isReadByAll) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  void _showMessageActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker();
              },
            ),
            if (widget.onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply?.call();
                },
              ),
            if (widget.isFromCurrentUser && widget.onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit?.call();
                },
              ),
            if (widget.isFromCurrentUser && widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Copy message content
              },
            ),
          ],
        ),
      ),
    );
  }

  void _quickReaction() {
    // Quick reaction with thumbs up
    MessageReactionService().toggleReaction(
      messageId: widget.messageId,
      userId: widget.currentUserId,
      userDisplayName: widget.currentUserDisplayName,
      type: ReactionType.thumbsUp,
      isPremium: widget.userIsPremium,
    );
  }

  void _showReactionPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: MessageReactionPicker(
              messageId: widget.messageId,
              currentUserId: widget.currentUserId,
              currentUserDisplayName: widget.currentUserDisplayName,
              userIsPremium: widget.userIsPremium,
              onReactionAdded: () {
                // Handle reaction added
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
