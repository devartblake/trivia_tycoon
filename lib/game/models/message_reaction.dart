enum ReactionType {
  // Standard emoji reactions
  thumbsUp('👍', 'thumbs_up'),
  thumbsDown('👎', 'thumbs_down'),
  heart('❤️', 'heart'),
  laugh('😂', 'laugh'),
  wow('😮', 'wow'),
  sad('😢', 'sad'),
  angry('😠', 'angry'),
  fire('🔥', 'fire'),
  clap('👏', 'clap'),
  party('🎉', 'party'),

  // Gaming-specific reactions
  trophy('🏆', 'trophy'),
  brain('🧠', 'brain'),
  target('🎯', 'target'),
  lightning('⚡', 'lightning'),
  gem('💎', 'gem'),

  // Custom reactions (for premium users)
  custom('', 'custom');

  const ReactionType(this.emoji, this.code);

  final String emoji;
  final String code;

  static ReactionType? fromCode(String code) {
    try {
      return ReactionType.values.firstWhere((type) => type.code == code);
    } catch (e) {
      return null;
    }
  }

  static ReactionType? fromEmoji(String emoji) {
    try {
      return ReactionType.values.firstWhere((type) => type.emoji == emoji);
    } catch (e) {
      return null;
    }
  }

  bool get isCustom => this == ReactionType.custom;
  bool get isGamingSpecific => [trophy, brain, target, lightning, gem].contains(this);
}

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String userDisplayName;
  final ReactionType type;
  final String? customEmoji; // For custom reactions
  final DateTime timestamp;
  final bool isPremium;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.userDisplayName,
    required this.type,
    this.customEmoji,
    required this.timestamp,
    this.isPremium = false,
  });

  String get displayEmoji => type.isCustom && customEmoji != null ? customEmoji! : type.emoji;

  MessageReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? userDisplayName,
    ReactionType? type,
    String? customEmoji,
    DateTime? timestamp,
    bool? isPremium,
  }) {
    return MessageReaction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      type: type ?? this.type,
      customEmoji: customEmoji ?? this.customEmoji,
      timestamp: timestamp ?? this.timestamp,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'type': type.code,
      if (customEmoji != null) 'customEmoji': customEmoji,
      'timestamp': timestamp.toIso8601String(),
      'isPremium': isPremium,
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      type: ReactionType.fromCode(json['type'] as String) ?? ReactionType.thumbsUp,
      customEmoji: json['customEmoji'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}

class MessageReactionSummary {
  final String messageId;
  final Map<ReactionType, List<MessageReaction>> reactions;
  final int totalCount;
  final DateTime lastUpdated;

  const MessageReactionSummary({
    required this.messageId,
    required this.reactions,
    required this.totalCount,
    required this.lastUpdated,
  });

  bool get hasReactions => totalCount > 0;
  List<ReactionType> get reactionTypes => reactions.keys.toList();

  int getCountForType(ReactionType type) => reactions[type]?.length ?? 0;
  List<MessageReaction> getReactionsForType(ReactionType type) => reactions[type] ?? [];

  bool hasUserReacted(String userId) {
    return reactions.values.any((reactionList) =>
        reactionList.any((reaction) => reaction.userId == userId));
  }

  ReactionType? getUserReactionType(String userId) {
    for (final entry in reactions.entries) {
      if (entry.value.any((reaction) => reaction.userId == userId)) {
        return entry.key;
      }
    }
    return null;
  }

  MessageReaction? getUserReaction(String userId) {
    for (final reactionList in reactions.values) {
      for (final reaction in reactionList) {
        if (reaction.userId == userId) return reaction;
      }
    }
    return null;
  }

  // Get top 3 most used reactions for display
  List<MapEntry<ReactionType, int>> getTopReactions({int limit = 3}) {
    final counts = reactions.entries
        .map((entry) => MapEntry(entry.key, entry.value.length))
        .toList();

    counts.sort((a, b) => b.value.compareTo(a.value));
    return counts.take(limit).toList();
  }

  // Get formatted summary text
  String getFormattedSummary({int maxUsers = 3}) {
    if (!hasReactions) return '';

    final topReactions = getTopReactions(limit: 3);
    if (topReactions.isEmpty) return '';

    return topReactions
        .map((entry) => '${entry.key.emoji} ${entry.value}')
        .join('  ');
  }

  // Get users who reacted with specific type
  List<String> getUsersForReaction(ReactionType type) {
    return reactions[type]
        ?.map((reaction) => reaction.userDisplayName)
        .toList() ?? [];
  }
}

