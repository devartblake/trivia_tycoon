enum ConversationType {
  direct, // One-on-one chat
  group, // Group chat
  system, // System notifications
  challenge, // Challenge-related conversations
  friendRequest, // Friend request conversations
}

class Conversation {
  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final String? name; // For group chats
  final String? avatar; // For group chats
  final String? lastMessageId;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    this.name,
    this.avatar,
    this.lastMessageId,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isGroupChat() => type == ConversationType.group;
  bool isDirectMessage() => type == ConversationType.direct;
  String get displayTitle =>
      name ??
      metadata?['displayTitle']?.toString() ??
      metadata?['title']?.toString() ??
      'Direct Message';
  String get lastMessagePreview =>
      metadata?['lastMessagePreview']?.toString() ??
      metadata?['preview']?.toString() ??
      'Tap to view messages';

  String? getOtherParticipantId(String currentUserId) {
    if (type != ConversationType.direct) return null;
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Conversation copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    String? name,
    String? avatar,
    String? lastMessageId,
    DateTime? lastMessageTime,
    int? unreadCount,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'participantIds': participantIds,
        'name': name,
        'avatar': avatar,
        'lastMessageId': lastMessageId,
        'lastMessageTime': lastMessageTime?.toIso8601String(),
        'unreadCount': unreadCount,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawParticipants =
        json['participantIds'] ?? json['participants'] ?? const <dynamic>[];
    final participantIds = rawParticipants is List
        ? rawParticipants
            .map((entry) {
              if (entry is String) return entry;
              if (entry is Map) {
                return (entry['playerId'] ?? entry['id'] ?? '').toString();
              }
              return entry.toString();
            })
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final metadata = <String, dynamic>{
      if (json['metadata'] is Map)
        ...(json['metadata'] as Map)
            .map((key, value) => MapEntry(key.toString(), value)),
      if (json['displayTitle'] != null) 'displayTitle': json['displayTitle'],
      if (json['lastMessagePreview'] != null)
        'lastMessagePreview': json['lastMessagePreview'],
      if (json['preview'] != null) 'preview': json['preview'],
    };

    return Conversation(
      id: (json['id'] ?? '').toString(),
      type: _parseConversationType(json['type']?.toString()),
      participantIds: participantIds,
      name: (json['name'] ?? json['displayTitle'])?.toString(),
      avatar: (json['avatar'] ?? json['avatarUrl'])?.toString(),
      lastMessageId:
          (json['lastMessageId'] ?? json['latestMessageId'])?.toString(),
      lastMessageTime: _parseTimestamp(
        json['lastMessageTime'] ??
            json['lastMessageTimestamp'] ??
            json['latestMessageAtUtc'],
      ),
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
      metadata: metadata.isEmpty ? null : metadata,
      createdAt: _parseTimestamp(json['createdAt'] ?? json['createdAtUtc']) ??
          DateTime.now(),
      updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updatedAtUtc']) ??
          DateTime.now(),
    );
  }

  static ConversationType _parseConversationType(String? rawValue) {
    switch (rawValue?.trim().toLowerCase()) {
      case 'group':
        return ConversationType.group;
      case 'system':
        return ConversationType.system;
      case 'challenge':
        return ConversationType.challenge;
      case 'friendrequest':
      case 'friend_request':
        return ConversationType.friendRequest;
      case 'direct':
      default:
        return ConversationType.direct;
    }
  }

  static DateTime? _parseTimestamp(Object? rawValue) {
    if (rawValue is DateTime) return rawValue;
    if (rawValue is String && rawValue.isNotEmpty) {
      return DateTime.tryParse(rawValue)?.toLocal();
    }
    return null;
  }

  static int? _parseInt(Object? rawValue) {
    if (rawValue is int) return rawValue;
    if (rawValue is String) return int.tryParse(rawValue);
    return null;
  }
}
