// lib/ui_components/presence/message_reaction_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/presence/message_reaction_service.dart';
import '../../game/models/message_reaction.dart';

class MessageReactionPicker extends StatefulWidget {
  final String messageId;
  final String currentUserId;
  final String currentUserDisplayName;
  final bool userIsPremium;
  final VoidCallback? onReactionAdded;
  final List<ReactionType>? customQuickReactions;

  const MessageReactionPicker({
    super.key,
    required this.messageId,
    required this.currentUserId,
    required this.currentUserDisplayName,
    this.userIsPremium = false,
    this.onReactionAdded,
    this.customQuickReactions,
  });

  @override
  State<MessageReactionPicker> createState() => _MessageReactionPickerState();
}

class _MessageReactionPickerState extends State<MessageReactionPicker>
    with TickerProviderStateMixin {
  final MessageReactionService _reactionService = MessageReactionService();
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickReactions = widget.customQuickReactions ?? _reactionService.quickReactions;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick reactions row
                _buildQuickReactionsRow(quickReactions),

                // Gaming reactions (if enabled)
                if (_shouldShowGamingReactions())
                  _buildGamingReactionsRow(),

                // Custom reactions (premium feature)
                if (_reactionService.canUseCustomReactions(widget.userIsPremium))
                  _buildCustomReactionsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReactionsRow(List<ReactionType> reactions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reactions.map((type) => _buildReactionButton(type)).toList(),
    );
  }

  Widget _buildGamingReactionsRow() {
    final gamingReactions = [
      ReactionType.trophy,
      ReactionType.brain,
      ReactionType.target,
      ReactionType.lightning,
      ReactionType.gem,
    ];

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: gamingReactions.map((type) => _buildReactionButton(type)).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomReactionsRow() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCustomReactionButton(),
            const SizedBox(width: 8),
            Text(
              'Custom',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionButton(ReactionType type) {
    return GestureDetector(
      onTap: () => _handleReactionTap(type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 100),
          child: Text(
            type.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomReactionButton() {
    return GestureDetector(
      onTap: _showCustomEmojiPicker,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  bool _shouldShowGamingReactions() {
    // Show gaming reactions based on context or user preference
    return true; // For now, always show
  }

  void _handleReactionTap(ReactionType type) async {
    HapticFeedback.lightImpact();

    final success = await _reactionService.toggleReaction(
      messageId: widget.messageId,
      userId: widget.currentUserId,
      userDisplayName: widget.currentUserDisplayName,
      type: type,
      isPremium: widget.userIsPremium,
    );

    if (success) {
      widget.onReactionAdded?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showCustomEmojiPicker() {
    // This would open a custom emoji picker
    // For now, just show a simple text input
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Reaction'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter emoji...',
            border: OutlineInputBorder(),
          ),
          maxLength: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Handle custom emoji addition
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class MessageReactionBar extends StatelessWidget {
  final String messageId;
  final String currentUserId;
  final VoidCallback? onAddReaction;
  final VoidCallback? onReactionTapped;

  const MessageReactionBar({
    Key? key,
    required this.messageId,
    required this.currentUserId,
    this.onAddReaction,
    this.onReactionTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageReactionSummary?>(
      stream: MessageReactionService().watchMessageReactions(messageId),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (summary == null || !summary.hasReactions) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...summary.getTopReactions(limit: 6).map((entry) =>
                  _buildReactionChip(context, entry.key, entry.value, summary)),
              if (summary.reactionTypes.length > 6)
                _buildMoreReactionsChip(context, summary),
              _buildAddReactionButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionChip(
      BuildContext context,
      ReactionType type,
      int count,
      MessageReactionSummary summary,
      ) {
    final hasUserReacted = summary.getUserReactionType(currentUserId) == type;

    return GestureDetector(
      onTap: () {
        onReactionTapped?.call();
        _showReactionDetails(context, messageId, type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: hasUserReacted
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: hasUserReacted
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: hasUserReacted
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoreReactionsChip(BuildContext context, MessageReactionSummary summary) {
    final remainingCount = summary.totalCount -
        summary.getTopReactions(limit: 6).fold<int>(0, (sum, entry) => sum + entry.value);

    return GestureDetector(
      onTap: () => _showAllReactions(context, messageId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          '+$remainingCount',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAddReactionButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddReaction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showReactionDetails(BuildContext context, String messageId, ReactionType type) {
    final summary = MessageReactionService().getReactionSummary(messageId);
    if (summary == null) return;

    final users = summary.getUsersForReaction(type);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '${users.length} ${users.length == 1 ? 'person' : 'people'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...users.map((user) => ListTile(
              dense: true,
              title: Text(user),
              leading: CircleAvatar(
                radius: 16,
                child: Text(user[0].toUpperCase()),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAllReactions(BuildContext context, String messageId) {
    final summary = MessageReactionService().getReactionSummary(messageId);
    if (summary == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'All Reactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: summary.reactionTypes.length,
                  itemBuilder: (context, index) {
                    final type = summary.reactionTypes[index];
                    final users = summary.getUsersForReaction(type);

                    return ExpansionTile(
                      leading: Text(
                        type.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text('${users.length} ${users.length == 1 ? 'person' : 'people'}'),
                      children: users.map((user) => ListTile(
                        dense: true,
                        title: Text(user),
                        leading: CircleAvatar(
                          radius: 16,
                          child: Text(user[0].toUpperCase()),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
