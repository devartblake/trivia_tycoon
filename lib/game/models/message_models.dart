enum MessageType {
  text,
  image,
  gameInvite,
  challengeRequest,
  challengeAccepted,
  challengeResult,
  lifeRequest,
  gift,
  achievement,
  friendRequest,
  friendAccepted,
  groupInvite,
  systemNotification,
  system,
  challenge,
}

enum MessageStatus {
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final List<String> reactions;
  final String? imageUrl;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.isRead = false,
    this.reactions = const [],
    this.imageUrl,
  });

  // Helper getter for backward compatibility
  bool get hasImage => imageUrl != null;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isRead,
    List<String>? reactions,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'type': type.name,
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'isRead': isRead,
        'reactions': reactions,
        'imageUrl': imageUrl,
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return Message(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['authorId'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['senderDisplayName'] ?? 'Player')
          .toString(),
      senderAvatar: (json['senderAvatar'] ?? json['avatarUrl'])?.toString(),
      content: (json['content'] ?? json['body'] ?? '').toString(),
      type: _parseMessageType(json['type']?.toString()),
      status: _parseMessageStatus(json['status']?.toString()),
      timestamp: _parseTimestamp(
            json['timestamp'] ?? json['createdAtUtc'] ?? json['createdAt'],
          ) ??
          DateTime.now(),
      metadata: metadata is Map
          ? metadata.map((key, value) => MapEntry(key.toString(), value))
          : null,
      isRead: json['isRead'] as bool? ??
          (json['status']?.toString().toLowerCase() == 'read'),
      reactions: json['reactions'] != null
          ? List<String>.from(json['reactions'] as List)
          : const <String>[],
      imageUrl: (json['imageUrl'] ?? json['image'])?.toString(),
    );
  }

  static MessageType _parseMessageType(String? rawValue) {
    switch (rawValue?.trim().toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      case 'systemnotification':
      case 'system_notification':
        return MessageType.systemNotification;
      case 'challenge':
        return MessageType.challenge;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? rawValue) {
    switch (rawValue?.trim().toLowerCase()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  static DateTime? _parseTimestamp(Object? rawValue) {
    if (rawValue is DateTime) return rawValue;
    if (rawValue is String && rawValue.isNotEmpty) {
      return DateTime.tryParse(rawValue)?.toLocal();
    }
    return null;
  }
}
