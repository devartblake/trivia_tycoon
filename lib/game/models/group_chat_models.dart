class GroupChatInvitation {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterId;
  final String inviterName;
  final String inviteeId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isAccepted;
  final bool isDeclined;

  const GroupChatInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    required this.createdAt,
    this.expiresAt,
    this.isAccepted = false,
    this.isDeclined = false,
  });

  bool get isPending => !isAccepted && !isDeclined;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  GroupChatInvitation copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? inviterId,
    String? inviterName,
    String? inviteeId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isAccepted,
    bool? isDeclined,
  }) {
    return GroupChatInvitation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      inviterId: inviterId ?? this.inviterId,
      inviterName: inviterName ?? this.inviterName,
      inviteeId: inviteeId ?? this.inviteeId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isDeclined: isDeclined ?? this.isDeclined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'isAccepted': isAccepted,
      'isDeclined': isDeclined,
    };
  }

  factory GroupChatInvitation.fromJson(Map<String, dynamic> json) {
    return GroupChatInvitation(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      inviterId: json['inviterId'] as String,
      inviterName: json['inviterName'] as String,
      inviteeId: json['inviteeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isAccepted: json['isAccepted'] as bool? ?? false,
      isDeclined: json['isDeclined'] as bool? ?? false,
    );
  }
}

// Helper class for group chat messages (extends your existing message model)
class GroupChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;

  const GroupChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isSystemMessage = false,
    this.replyToMessageId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isSystemMessage': isSystemMessage,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    return GroupChatMessage(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSystemMessage: json['isSystemMessage'] as bool? ?? false,
      replyToMessageId: json['replyToMessageId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Factory for system messages
  factory GroupChatMessage.system({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return GroupChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      timestamp: DateTime.now(),
      isSystemMessage: true,
      metadata: metadata,
    );
  }
}
