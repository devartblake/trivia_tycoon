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

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'],
    senderName: json['senderName'],
    senderAvatar: json['senderAvatar'],
    content: json['content'],
    type: MessageType.values.firstWhere((e) => e.name == json['type']),
    status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'],
    isRead: json['isRead'] ?? false,
    reactions: json['reactions'] != null ? List<String>.from(json['reactions']) : [],
    imageUrl: json['imageUrl'],
  );
}
