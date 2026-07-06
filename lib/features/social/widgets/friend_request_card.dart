import 'package:flutter/material.dart';
import '../../../core/services/social/friends_models.dart';

/// Card widget displaying a pending friend request
///
/// Shows:
/// - Requester's avatar
/// - Requester's username
/// - When the request was sent
/// - Accept/Decline buttons
class FriendRequestCard extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const FriendRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<FriendRequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and username
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: widget.request.fromAvatarUrl != null
                      ? NetworkImage(widget.request.fromAvatarUrl!)
                      : null,
                  child: widget.request.fromAvatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Username and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.fromUsername,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sent ${_formatTime(widget.request.sentAtUtc)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleDecline,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _handleAccept,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle accept button press
  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      widget.onAccept?.call();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Handle decline button press
  Future<void> _handleDecline() async {
    setState(() => _isProcessing = true);
    try {
      widget.onDecline?.call();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Format timestamp to relative time string
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }
}
