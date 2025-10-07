enum ConversationType {
  direct,      // One-on-one chat
  group,       // Group chat
  system,      // System notifications
  challenge,   // Challenge-related conversations
  friendRequest, // Friend request conversations
}

class Conversation {
  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final String? name;           // For group chats
  final String? avatar;         // For group chats
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

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    type: ConversationType.values.firstWhere((e) => e.name == json['type']),
    participantIds: List<String>.from(json['participantIds']),
    name: json['name'],
    avatar: json['avatar'],
    lastMessageId: json['lastMessageId'],
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.parse(json['lastMessageTime'])
        : null,
    unreadCount: json['unreadCount'] ?? 0,
    metadata: json['metadata'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}