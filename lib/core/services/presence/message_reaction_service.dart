import 'package:flutter/material.dart';

import '../../../game/models/message_reaction.dart';

class MessageReactionService extends ChangeNotifier {
  static final MessageReactionService _instance = MessageReactionService._internal();
  factory MessageReactionService() => _instance;
  MessageReactionService._internal();

  final Map<String, MessageReactionSummary> _reactionSummaries = {};
  final Map<String, List<MessageReaction>> _messageReactions = {};

  // Settings
  bool _reactionsEnabled = true;
  bool _customReactionsEnabled = false; // Premium feature
  int _maxReactionsPerMessage = 50;
  List<ReactionType> _quickReactions = [
    ReactionType.thumbsUp,
    ReactionType.heart,
    ReactionType.laugh,
    ReactionType.wow,
    ReactionType.fire,
    ReactionType.clap,
  ];

  // Getters
  bool get reactionsEnabled => _reactionsEnabled;
  bool get customReactionsEnabled => _customReactionsEnabled;
  List<ReactionType> get quickReactions => List.unmodifiable(_quickReactions);
  Map<String, MessageReactionSummary> get allReactionSummaries => Map.unmodifiable(_reactionSummaries);

  void initialize() {
    debugPrint('MessageReactionService initialized');
  }

  // Settings management
  void updateSettings({
    bool? reactionsEnabled,
    bool? customReactionsEnabled,
    int? maxReactionsPerMessage,
    List<ReactionType>? quickReactions,
  }) {
    _reactionsEnabled = reactionsEnabled ?? _reactionsEnabled;
    _customReactionsEnabled = customReactionsEnabled ?? _customReactionsEnabled;
    _maxReactionsPerMessage = maxReactionsPerMessage ?? _maxReactionsPerMessage;
    if (quickReactions != null) {
      _quickReactions = List.from(quickReactions);
    }

    debugPrint('MessageReactionService settings updated');
    notifyListeners();
  }

  // Add reaction to message
  Future<bool> addReaction({
    required String messageId,
    required String userId,
    required String userDisplayName,
    required ReactionType type,
    String? customEmoji,
    bool isPremium = false,
  }) async {
    if (!_reactionsEnabled) return false;
    if (type.isCustom && !_customReactionsEnabled) return false;

    // Remove existing reaction from user first
    await removeUserReaction(messageId, userId);

    final reaction = MessageReaction(
      id: _generateReactionId(),
      messageId: messageId,
      userId: userId,
      userDisplayName: userDisplayName,
      type: type,
      customEmoji: customEmoji,
      timestamp: DateTime.now(),
      isPremium: isPremium,
    );

    // Add to reactions list
    _messageReactions[messageId] ??= [];

    // Check max reactions limit
    if (_messageReactions[messageId]!.length >= _maxReactionsPerMessage) {
      debugPrint('Max reactions limit reached for message $messageId');
      return false;
    }

    _messageReactions[messageId]!.add(reaction);

    // Update summary
    _updateReactionSummary(messageId);

    debugPrint('Added reaction ${type.emoji} to message $messageId by $userDisplayName');
    notifyListeners();
    return true;
  }

  // Remove specific reaction
  Future<bool> removeReaction(String reactionId) async {
    for (final entry in _messageReactions.entries) {
      final messageId = entry.key;
      final reactions = entry.value;

      final reactionIndex = reactions.indexWhere((r) => r.id == reactionId);
      if (reactionIndex != -1) {
        final removedReaction = reactions.removeAt(reactionIndex);
        _updateReactionSummary(messageId);

        debugPrint('Removed reaction ${removedReaction.type.emoji} from message $messageId');
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  // Remove all reactions from a user on a message
  Future<bool> removeUserReaction(String messageId, String userId) async {
    final reactions = _messageReactions[messageId];
    if (reactions == null) return false;

    final initialLength = reactions.length;
    reactions.removeWhere((reaction) => reaction.userId == userId);

    if (reactions.length != initialLength) {
      _updateReactionSummary(messageId);
      debugPrint('Removed user reactions from message $messageId for user $userId');
      notifyListeners();
      return true;
    }

    return false;
  }

  // Toggle reaction (add if not present, remove if present)
  Future<bool> toggleReaction({
    required String messageId,
    required String userId,
    required String userDisplayName,
    required ReactionType type,
    String? customEmoji,
    bool isPremium = false,
  }) async {
    final currentSummary = getReactionSummary(messageId);
    if (currentSummary?.getUserReactionType(userId) == type) {
      // User already reacted with this type, remove it
      return await removeUserReaction(messageId, userId);
    } else {
      // Add new reaction (this will remove any existing reaction first)
      return await addReaction(
        messageId: messageId,
        userId: userId,
        userDisplayName: userDisplayName,
        type: type,
        customEmoji: customEmoji,
        isPremium: isPremium,
      );
    }
  }

  // Get reaction summary for a message
  MessageReactionSummary? getReactionSummary(String messageId) {
    return _reactionSummaries[messageId];
  }

  // Get all reactions for a message
  List<MessageReaction> getMessageReactions(String messageId) {
    return _messageReactions[messageId] ?? [];
  }

  // Update reaction summary after changes
  void _updateReactionSummary(String messageId) {
    final reactions = _messageReactions[messageId] ?? [];

    if (reactions.isEmpty) {
      _reactionSummaries.remove(messageId);
      return;
    }

    final Map<ReactionType, List<MessageReaction>> groupedReactions = {};

    for (final reaction in reactions) {
      groupedReactions[reaction.type] ??= [];
      groupedReactions[reaction.type]!.add(reaction);
    }

    // Sort reactions within each group by timestamp
    for (final reactionList in groupedReactions.values) {
      reactionList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    _reactionSummaries[messageId] = MessageReactionSummary(
      messageId: messageId,
      reactions: groupedReactions,
      totalCount: reactions.length,
      lastUpdated: DateTime.now(),
    );
  }

  // Bulk operations
  Future<void> loadReactionsForMessages(List<String> messageIds) async {
    // This would typically fetch from backend
    // For now, simulate some reactions for demo
    debugPrint('Loading reactions for ${messageIds.length} messages');

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Clear all reactions for a message
  Future<void> clearMessageReactions(String messageId) async {
    _messageReactions.remove(messageId);
    _reactionSummaries.remove(messageId);

    debugPrint('Cleared all reactions for message $messageId');
    notifyListeners();
  }

  // Get popular reactions across all messages
  List<MapEntry<ReactionType, int>> getPopularReactions({int limit = 10}) {
    final reactionCounts = <ReactionType, int>{};

    for (final reactions in _messageReactions.values) {
      for (final reaction in reactions) {
        reactionCounts[reaction.type] = (reactionCounts[reaction.type] ?? 0) + 1;
      }
    }

    final sorted = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }

  // Analytics
  Map<String, dynamic> getReactionAnalytics() {
    final totalMessages = _messageReactions.length;
    final totalReactions = _messageReactions.values.fold<int>(0, (sum, reactions) => sum + reactions.length);
    final averageReactionsPerMessage = totalMessages > 0 ? totalReactions / totalMessages : 0.0;

    final reactionCounts = <String, int>{};
    for (final reactions in _messageReactions.values) {
      for (final reaction in reactions) {
        reactionCounts[reaction.type.code] = (reactionCounts[reaction.type.code] ?? 0) + 1;
      }
    }

    return {
      'totalMessages': totalMessages,
      'totalReactions': totalReactions,
      'averageReactionsPerMessage': averageReactionsPerMessage,
      'reactionDistribution': reactionCounts,
      'popularReactions': getPopularReactions(limit: 5)
          .map((entry) => {'type': entry.key.code, 'count': entry.value})
          .toList(),
      'settingsEnabled': {
        'reactions': _reactionsEnabled,
        'customReactions': _customReactionsEnabled,
      },
    };
  }

  // Utility methods
  String _generateReactionId() {
    return 'reaction_${DateTime.now().millisecondsSinceEpoch}_${_messageReactions.length}';
  }

  // Stream for watching reactions on a specific message
  Stream<MessageReactionSummary?> watchMessageReactions(String messageId) {
    return Stream.periodic(const Duration(milliseconds: 100))
        .map((_) => _reactionSummaries[messageId])
        .distinct();
  }

  // Helper for UI: Get reaction tooltip text
  String getReactionTooltip(String messageId, ReactionType type) {
    final summary = getReactionSummary(messageId);
    if (summary == null) return '';

    final users = summary.getUsersForReaction(type);
    if (users.isEmpty) return '';

    if (users.length == 1) {
      return '${users.first} reacted with ${type.emoji}';
    } else if (users.length <= 3) {
      return '${users.join(', ')} reacted with ${type.emoji}';
    } else {
      return '${users.take(2).join(', ')} and ${users.length - 2} others reacted with ${type.emoji}';
    }
  }

  // Check if user can add custom reactions
  bool canUseCustomReactions(bool userIsPremium) {
    return _customReactionsEnabled && userIsPremium;
  }

  // Get suggested reactions based on message content
  List<ReactionType> getSuggestedReactions(String messageContent) {
    final content = messageContent.toLowerCase();
    final suggestions = <ReactionType>[];

    // Add contextual suggestions
    if (content.contains('congratulations') || content.contains('congrats') || content.contains('well done')) {
      suggestions.addAll([ReactionType.clap, ReactionType.party, ReactionType.trophy]);
    }
    if (content.contains('funny') || content.contains('lol') || content.contains('haha')) {
      suggestions.add(ReactionType.laugh);
    }
    if (content.contains('amazing') || content.contains('awesome') || content.contains('incredible')) {
      suggestions.addAll([ReactionType.fire, ReactionType.wow]);
    }
    if (content.contains('love') || content.contains('❤️')) {
      suggestions.add(ReactionType.heart);
    }
    if (content.contains('smart') || content.contains('brilliant') || content.contains('genius')) {
      suggestions.add(ReactionType.brain);
    }

    // Always include the quick reactions
    suggestions.addAll(_quickReactions);

    // Remove duplicates and return
    return suggestions.toSet().toList();
  }
}
