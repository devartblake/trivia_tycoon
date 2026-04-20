import 'package:flutter/material.dart';

enum InboxType {
  alert,
  notification,
  friend,
  achievement,
  system,
  challenge,
}

class InboxItem {
  final String id;
  final InboxType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? actionRoute;
  final Map<String, dynamic>? payload;
  final bool unread;
  final String? icon;
  final String? avatarUrl;

  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.actionRoute,
    this.payload,
    this.unread = true,
    this.icon,
    this.avatarUrl,
  });

  InboxItem copyWith({
    String? id,
    InboxType? type,
    String? title,
    String? body,
    DateTime? timestamp,
    String? actionRoute,
    Map<String, dynamic>? payload,
    bool? unread,
    String? icon,
    String? avatarUrl,
  }) {
    return InboxItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      actionRoute: actionRoute ?? this.actionRoute,
      payload: payload ?? this.payload,
      unread: unread ?? this.unread,
      icon: icon ?? this.icon,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return InboxItem(
      id: (json['id'] ?? json['notificationId'] ?? '').toString(),
      type: _parseInboxType(
        (json['type'] ?? json['category'] ?? json['kind']).toString(),
      ),
      title: (json['title'] ?? json['headline'] ?? '').toString(),
      body:
          (json['body'] ?? json['summary'] ?? json['message'] ?? '').toString(),
      timestamp: _parseTimestamp(
        json['createdAtUtc'] ??
            json['createdAt'] ??
            json['timestamp'] ??
            json['sentAtUtc'],
      ),
      actionRoute: (json['actionRoute'] ?? json['route'])?.toString(),
      payload: payload is Map
          ? payload.map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : null,
      unread: json['unread'] as bool? ?? !(json['isRead'] as bool? ?? false),
      icon: (json['icon'] ?? json['iconKey'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['imageUrl'])?.toString(),
    );
  }

  static DateTime _parseTimestamp(Object? rawValue) {
    if (rawValue is DateTime) return rawValue;
    if (rawValue is String) {
      return DateTime.tryParse(rawValue)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static InboxType _parseInboxType(String rawValue) {
    final normalized = rawValue.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'alert':
      case 'urgent':
        return InboxType.alert;
      case 'friend':
      case 'social':
      case 'friend_request':
        return InboxType.friend;
      case 'achievement':
      case 'reward':
        return InboxType.achievement;
      case 'system':
      case 'update':
        return InboxType.system;
      case 'challenge':
      case 'game':
        return InboxType.challenge;
      case 'notification':
      case 'info':
      default:
        return InboxType.notification;
    }
  }
}

class NotificationConfig {
  final Color color;
  final IconData icon;
  final String label;

  const NotificationConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

NotificationConfig inboxTypeConfig(InboxType type) {
  switch (type) {
    case InboxType.alert:
      return const NotificationConfig(
        color: Color(0xFFED4245),
        icon: Icons.warning_rounded,
        label: 'ALERT',
      );
    case InboxType.friend:
      return const NotificationConfig(
        color: Color(0xFF3BA55C),
        icon: Icons.people_rounded,
        label: 'SOCIAL',
      );
    case InboxType.achievement:
      return const NotificationConfig(
        color: Color(0xFFFAA61A),
        icon: Icons.military_tech,
        label: 'ACHIEVEMENT',
      );
    case InboxType.challenge:
      return const NotificationConfig(
        color: Color(0xFFF26522),
        icon: Icons.emoji_events,
        label: 'CHALLENGE',
      );
    case InboxType.system:
      return const NotificationConfig(
        color: Color(0xFF8B5CF6),
        icon: Icons.settings,
        label: 'SYSTEM',
      );
    case InboxType.notification:
      return const NotificationConfig(
        color: Color(0xFF5865F2),
        icon: Icons.notifications,
        label: 'INFO',
      );
  }
}
