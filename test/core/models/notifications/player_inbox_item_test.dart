import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/notifications/player_inbox_item.dart';

Map<String, dynamic> _baseJson({
  String id = 'notif1',
  String type = 'notification',
  String title = 'Welcome!',
  String body = 'You have a new message.',
  String timestamp = '2025-06-01T10:00:00.000Z',
  String? actionRoute,
  Map<String, dynamic>? payload,
  bool? unread,
  bool? isRead,
  String? icon,
  String? avatarUrl,
}) =>
    {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      if (actionRoute != null) 'actionRoute': actionRoute,
      if (payload != null) 'payload': payload,
      if (unread != null) 'unread': unread,
      if (isRead != null) 'isRead': isRead,
      if (icon != null) 'icon': icon,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

void main() {
  // -------------------------------------------------------------------------
  // InboxItem.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('InboxItem.fromJson — scalar fields', () {
    test('parses id', () {
      expect(InboxItem.fromJson(_baseJson(id: 'n99')).id, 'n99');
    });

    test('id falls back to notificationId', () {
      final json = _baseJson();
      json.remove('id');
      json['notificationId'] = 'nid_42';
      expect(InboxItem.fromJson(json).id, 'nid_42');
    });

    test('parses title', () {
      expect(InboxItem.fromJson(_baseJson(title: 'Hello')).title, 'Hello');
    });

    test('title falls back to headline', () {
      final json = _baseJson();
      json.remove('title');
      json['headline'] = 'Headline Text';
      expect(InboxItem.fromJson(json).title, 'Headline Text');
    });

    test('parses body', () {
      expect(InboxItem.fromJson(_baseJson(body: 'Test body')).body, 'Test body');
    });

    test('body falls back to summary', () {
      final json = _baseJson();
      json.remove('body');
      json['summary'] = 'Summary text';
      expect(InboxItem.fromJson(json).body, 'Summary text');
    });

    test('body falls back to message', () {
      final json = _baseJson();
      json.remove('body');
      json['message'] = 'Message text';
      expect(InboxItem.fromJson(json).body, 'Message text');
    });

    test('parses actionRoute', () {
      expect(
          InboxItem.fromJson(_baseJson(actionRoute: '/inbox/detail')).actionRoute,
          '/inbox/detail');
    });

    test('actionRoute falls back to route', () {
      final json = _baseJson();
      json['route'] = '/route/path';
      expect(InboxItem.fromJson(json).actionRoute, '/route/path');
    });

    test('actionRoute is null when absent', () {
      expect(InboxItem.fromJson(_baseJson()).actionRoute, isNull);
    });

    test('parses avatarUrl', () {
      expect(
          InboxItem.fromJson(_baseJson(avatarUrl: 'https://img/a.png'))
              .avatarUrl,
          'https://img/a.png');
    });

    test('avatarUrl falls back to imageUrl', () {
      final json = _baseJson();
      json['imageUrl'] = 'https://img/fallback.png';
      expect(InboxItem.fromJson(json).avatarUrl, 'https://img/fallback.png');
    });

    test('avatarUrl is null when absent', () {
      expect(InboxItem.fromJson(_baseJson()).avatarUrl, isNull);
    });

    test('parses icon', () {
      expect(InboxItem.fromJson(_baseJson(icon: 'star')).icon, 'star');
    });

    test('icon falls back to iconKey', () {
      final json = _baseJson();
      json['iconKey'] = 'trophy_key';
      expect(InboxItem.fromJson(json).icon, 'trophy_key');
    });

    test('icon is null when absent', () {
      expect(InboxItem.fromJson(_baseJson()).icon, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // InboxItem.fromJson — unread logic
  // -------------------------------------------------------------------------

  group('InboxItem.fromJson — unread', () {
    test('parses unread: true', () {
      expect(InboxItem.fromJson(_baseJson(unread: true)).unread, isTrue);
    });

    test('parses unread: false', () {
      expect(InboxItem.fromJson(_baseJson(unread: false)).unread, isFalse);
    });

    test('unread inferred from isRead: true → unread=false', () {
      expect(InboxItem.fromJson(_baseJson(isRead: true)).unread, isFalse);
    });

    test('unread inferred from isRead: false → unread=true', () {
      expect(InboxItem.fromJson(_baseJson(isRead: false)).unread, isTrue);
    });

    test('unread defaults to true when both absent', () {
      expect(InboxItem.fromJson(_baseJson()).unread, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // InboxItem.fromJson — timestamp
  // -------------------------------------------------------------------------

  group('InboxItem.fromJson — timestamp', () {
    test('parses timestamp field', () {
      final item = InboxItem.fromJson(
          _baseJson(timestamp: '2025-08-15T09:30:00.000Z'));
      expect(item.timestamp.month, 8);
      expect(item.timestamp.day, 15);
    });

    test('falls back to createdAtUtc', () {
      final json = _baseJson();
      json.remove('timestamp');
      json['createdAtUtc'] = '2025-09-01T00:00:00.000Z';
      expect(InboxItem.fromJson(json).timestamp.month, 9);
    });

    test('falls back to createdAt', () {
      final json = _baseJson();
      json.remove('timestamp');
      json['createdAt'] = '2025-10-05T00:00:00.000Z';
      expect(InboxItem.fromJson(json).timestamp.month, 10);
    });

    test('falls back to sentAtUtc', () {
      final json = _baseJson();
      json.remove('timestamp');
      json['sentAtUtc'] = '2025-11-20T00:00:00.000Z';
      expect(InboxItem.fromJson(json).timestamp.month, 11);
    });
  });

  // -------------------------------------------------------------------------
  // InboxItem.fromJson — payload
  // -------------------------------------------------------------------------

  group('InboxItem.fromJson — payload', () {
    test('parses payload map', () {
      final item = InboxItem.fromJson(
          _baseJson(payload: {'challengeId': 'ch1', 'reward': 50}));
      expect(item.payload!['challengeId'], 'ch1');
    });

    test('payload is null when absent', () {
      expect(InboxItem.fromJson(_baseJson()).payload, isNull);
    });

    test('payload is null when not a Map', () {
      final json = _baseJson();
      json['payload'] = 'not-a-map';
      expect(InboxItem.fromJson(json).payload, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // _parseInboxType — all aliases
  // -------------------------------------------------------------------------

  group('_parseInboxType — type field routing', () {
    test('"alert" → InboxType.alert', () {
      expect(InboxItem.fromJson(_baseJson(type: 'alert')).type, InboxType.alert);
    });

    test('"urgent" → InboxType.alert', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'urgent')).type, InboxType.alert);
    });

    test('"friend" → InboxType.friend', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'friend')).type, InboxType.friend);
    });

    test('"social" → InboxType.friend', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'social')).type, InboxType.friend);
    });

    test('"friend_request" → InboxType.friend', () {
      expect(InboxItem.fromJson(_baseJson(type: 'friend_request')).type,
          InboxType.friend);
    });

    test('"friend-request" (hyphen) → InboxType.friend', () {
      expect(InboxItem.fromJson(_baseJson(type: 'friend-request')).type,
          InboxType.friend);
    });

    test('"achievement" → InboxType.achievement', () {
      expect(InboxItem.fromJson(_baseJson(type: 'achievement')).type,
          InboxType.achievement);
    });

    test('"reward" → InboxType.achievement', () {
      expect(InboxItem.fromJson(_baseJson(type: 'reward')).type,
          InboxType.achievement);
    });

    test('"system" → InboxType.system', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'system')).type, InboxType.system);
    });

    test('"update" → InboxType.system', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'update')).type, InboxType.system);
    });

    test('"challenge" → InboxType.challenge', () {
      expect(InboxItem.fromJson(_baseJson(type: 'challenge')).type,
          InboxType.challenge);
    });

    test('"game" → InboxType.challenge', () {
      expect(InboxItem.fromJson(_baseJson(type: 'game')).type,
          InboxType.challenge);
    });

    test('"notification" → InboxType.notification', () {
      expect(InboxItem.fromJson(_baseJson(type: 'notification')).type,
          InboxType.notification);
    });

    test('"info" → InboxType.notification', () {
      expect(InboxItem.fromJson(_baseJson(type: 'info')).type,
          InboxType.notification);
    });

    test('unknown type → InboxType.notification (default)', () {
      expect(InboxItem.fromJson(_baseJson(type: 'promo')).type,
          InboxType.notification);
    });

    test('case-insensitive: "ALERT" → alert', () {
      expect(
          InboxItem.fromJson(_baseJson(type: 'ALERT')).type, InboxType.alert);
    });

    test('type from category key', () {
      final json = _baseJson();
      json.remove('type');
      json['category'] = 'social';
      expect(InboxItem.fromJson(json).type, InboxType.friend);
    });

    test('type from kind key', () {
      final json = _baseJson();
      json.remove('type');
      json['kind'] = 'reward';
      expect(InboxItem.fromJson(json).type, InboxType.achievement);
    });
  });

  // -------------------------------------------------------------------------
  // inboxTypeConfig — all six InboxType values
  // -------------------------------------------------------------------------

  group('inboxTypeConfig', () {
    test('alert config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.alert);
      expect(cfg.color, const Color(0xFFED4245));
      expect(cfg.icon, Icons.warning_rounded);
      expect(cfg.label, 'ALERT');
    });

    test('friend config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.friend);
      expect(cfg.color, const Color(0xFF3BA55C));
      expect(cfg.icon, Icons.people_rounded);
      expect(cfg.label, 'SOCIAL');
    });

    test('achievement config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.achievement);
      expect(cfg.color, const Color(0xFFFAA61A));
      expect(cfg.icon, Icons.military_tech);
      expect(cfg.label, 'ACHIEVEMENT');
    });

    test('challenge config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.challenge);
      expect(cfg.color, const Color(0xFFF26522));
      expect(cfg.icon, Icons.emoji_events);
      expect(cfg.label, 'CHALLENGE');
    });

    test('system config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.system);
      expect(cfg.color, const Color(0xFF8B5CF6));
      expect(cfg.icon, Icons.settings);
      expect(cfg.label, 'SYSTEM');
    });

    test('notification config: color, icon, label', () {
      final cfg = inboxTypeConfig(InboxType.notification);
      expect(cfg.color, const Color(0xFF5865F2));
      expect(cfg.icon, Icons.notifications);
      expect(cfg.label, 'INFO');
    });
  });

  // -------------------------------------------------------------------------
  // InboxItem.copyWith
  // -------------------------------------------------------------------------

  group('InboxItem.copyWith', () {
    late InboxItem base;
    setUp(() => base = InboxItem.fromJson(_baseJson()));

    test('copies title', () {
      expect(base.copyWith(title: 'New Title').title, 'New Title');
    });

    test('copies body', () {
      expect(base.copyWith(body: 'New body text').body, 'New body text');
    });

    test('copies type', () {
      expect(base.copyWith(type: InboxType.alert).type, InboxType.alert);
    });

    test('copies unread', () {
      expect(base.copyWith(unread: false).unread, isFalse);
    });

    test('copies actionRoute', () {
      expect(base.copyWith(actionRoute: '/new/route').actionRoute, '/new/route');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(unread: false);
      expect(updated.id, base.id);
      expect(updated.title, base.title);
      expect(updated.body, base.body);
    });
  });
}
