import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/message_models.dart';

Map<String, dynamic> _baseJson({
  String id = 'msg1',
  String conversationId = 'conv1',
  String senderId = 'uid_a',
  String senderName = 'Alice',
  String? senderAvatar,
  String content = 'Hello!',
  String type = 'text',
  String status = 'sent',
  String timestamp = '2025-06-01T10:00:00.000Z',
  Map<String, dynamic>? metadata,
  bool isRead = false,
  List<dynamic>? reactions,
  String? imageUrl,
}) =>
    {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'content': content,
      'type': type,
      'status': status,
      'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      'isRead': isRead,
      if (reactions != null) 'reactions': reactions,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

void main() {
  // -------------------------------------------------------------------------
  // Message.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('Message.fromJson — scalar fields', () {
    test('parses id', () {
      expect(Message.fromJson(_baseJson(id: 'm99')).id, 'm99');
    });

    test('id defaults to "" when absent', () {
      final json = _baseJson();
      json.remove('id');
      expect(Message.fromJson(json).id, '');
    });

    test('parses conversationId', () {
      expect(
          Message.fromJson(_baseJson(conversationId: 'c42')).conversationId,
          'c42');
    });

    test('parses senderId', () {
      expect(Message.fromJson(_baseJson(senderId: 'u_x')).senderId, 'u_x');
    });

    test('senderId falls back to authorId', () {
      final json = _baseJson();
      json.remove('senderId');
      json['authorId'] = 'author_y';
      expect(Message.fromJson(json).senderId, 'author_y');
    });

    test('parses senderName', () {
      expect(Message.fromJson(_baseJson(senderName: 'Bob')).senderName, 'Bob');
    });

    test('senderName falls back to senderDisplayName', () {
      final json = _baseJson();
      json.remove('senderName');
      json['senderDisplayName'] = 'Charlie';
      expect(Message.fromJson(json).senderName, 'Charlie');
    });

    test('senderName defaults to "Player" when absent', () {
      final json = _baseJson();
      json.remove('senderName');
      expect(Message.fromJson(json).senderName, 'Player');
    });

    test('parses senderAvatar', () {
      expect(
          Message.fromJson(_baseJson(senderAvatar: 'https://img/a.png'))
              .senderAvatar,
          'https://img/a.png');
    });

    test('senderAvatar falls back to avatarUrl', () {
      final json = _baseJson();
      json['avatarUrl'] = 'https://img/fallback.png';
      expect(Message.fromJson(json).senderAvatar, 'https://img/fallback.png');
    });

    test('senderAvatar is null when absent', () {
      expect(Message.fromJson(_baseJson()).senderAvatar, isNull);
    });

    test('parses content', () {
      expect(
          Message.fromJson(_baseJson(content: 'Hi there')).content, 'Hi there');
    });

    test('content falls back to body field', () {
      final json = _baseJson();
      json.remove('content');
      json['body'] = 'Body text';
      expect(Message.fromJson(json).content, 'Body text');
    });

    test('content defaults to "" when absent', () {
      final json = _baseJson();
      json.remove('content');
      expect(Message.fromJson(json).content, '');
    });

    test('parses imageUrl', () {
      expect(
          Message.fromJson(_baseJson(imageUrl: 'https://img/photo.png'))
              .imageUrl,
          'https://img/photo.png');
    });

    test('imageUrl falls back to image field', () {
      final json = _baseJson();
      json['image'] = 'https://img/img.png';
      expect(Message.fromJson(json).imageUrl, 'https://img/img.png');
    });

    test('imageUrl is null when absent', () {
      expect(Message.fromJson(_baseJson()).imageUrl, isNull);
    });

    test('parses isRead', () {
      expect(Message.fromJson(_baseJson(isRead: true)).isRead, isTrue);
    });

    test('isRead inferred true when status is "read"', () {
      final json = _baseJson(status: 'read');
      json.remove('isRead');
      expect(Message.fromJson(json).isRead, isTrue);
    });

    test('isRead defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isRead');
      expect(Message.fromJson(json).isRead, isFalse);
    });

    test('parses reactions list', () {
      final msg = Message.fromJson(
          _baseJson(reactions: ['👍', '❤️']));
      expect(msg.reactions, ['👍', '❤️']);
    });

    test('reactions defaults to empty when absent', () {
      expect(Message.fromJson(_baseJson()).reactions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Message.fromJson — DateTime
  // -------------------------------------------------------------------------

  group('Message.fromJson — timestamp', () {
    test('parses timestamp', () {
      final msg = Message.fromJson(
          _baseJson(timestamp: '2025-09-15T14:30:00.000Z'));
      expect(msg.timestamp.month, 9);
    });

    test('parses createdAtUtc fallback', () {
      final json = _baseJson();
      json.remove('timestamp');
      json['createdAtUtc'] = '2025-10-01T00:00:00.000Z';
      final msg = Message.fromJson(json);
      expect(msg.timestamp.month, 10);
    });

    test('parses createdAt fallback', () {
      final json = _baseJson();
      json.remove('timestamp');
      json['createdAt'] = '2025-11-01T00:00:00.000Z';
      final msg = Message.fromJson(json);
      expect(msg.timestamp.month, 11);
    });
  });

  // -------------------------------------------------------------------------
  // Message.fromJson — type parsing
  // -------------------------------------------------------------------------

  group('Message.fromJson — type parsing', () {
    test('"text" → MessageType.text', () {
      expect(Message.fromJson(_baseJson(type: 'text')).type, MessageType.text);
    });

    test('"image" → MessageType.image', () {
      expect(
          Message.fromJson(_baseJson(type: 'image')).type, MessageType.image);
    });

    test('"system" → MessageType.system', () {
      expect(
          Message.fromJson(_baseJson(type: 'system')).type, MessageType.system);
    });

    test('"systemNotification" → MessageType.systemNotification', () {
      expect(
          Message.fromJson(_baseJson(type: 'systemNotification')).type,
          MessageType.systemNotification);
    });

    test('"system_notification" → MessageType.systemNotification', () {
      expect(
          Message.fromJson(_baseJson(type: 'system_notification')).type,
          MessageType.systemNotification);
    });

    test('"challenge" → MessageType.challenge', () {
      expect(Message.fromJson(_baseJson(type: 'challenge')).type,
          MessageType.challenge);
    });

    test('unknown type falls back to text', () {
      expect(
          Message.fromJson(_baseJson(type: 'unknown_type')).type,
          MessageType.text);
    });

    test('null type falls back to text', () {
      final json = _baseJson();
      json.remove('type');
      expect(Message.fromJson(json).type, MessageType.text);
    });
  });

  // -------------------------------------------------------------------------
  // Message.fromJson — status parsing
  // -------------------------------------------------------------------------

  group('Message.fromJson — status parsing', () {
    test('"sent" → MessageStatus.sent', () {
      expect(Message.fromJson(_baseJson(status: 'sent')).status,
          MessageStatus.sent);
    });

    test('"delivered" → MessageStatus.delivered', () {
      expect(Message.fromJson(_baseJson(status: 'delivered')).status,
          MessageStatus.delivered);
    });

    test('"read" → MessageStatus.read', () {
      expect(Message.fromJson(_baseJson(status: 'read')).status,
          MessageStatus.read);
    });

    test('"failed" → MessageStatus.failed', () {
      expect(Message.fromJson(_baseJson(status: 'failed')).status,
          MessageStatus.failed);
    });

    test('unknown status falls back to sent', () {
      expect(Message.fromJson(_baseJson(status: 'queued')).status,
          MessageStatus.sent);
    });
  });

  // -------------------------------------------------------------------------
  // Message.fromJson — metadata
  // -------------------------------------------------------------------------

  group('Message.fromJson — metadata', () {
    test('parses metadata map', () {
      final msg = Message.fromJson(
          _baseJson(metadata: {'challengeId': 'ch1', 'score': 900}));
      expect(msg.metadata!['challengeId'], 'ch1');
    });

    test('metadata is null when absent', () {
      expect(Message.fromJson(_baseJson()).metadata, isNull);
    });

    test('metadata is null when not a Map', () {
      final json = _baseJson();
      json['metadata'] = 'not-a-map';
      expect(Message.fromJson(json).metadata, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Message — hasImage
  // -------------------------------------------------------------------------

  group('Message — hasImage', () {
    test('true when imageUrl is set', () {
      expect(
          Message.fromJson(_baseJson(imageUrl: 'https://img/x.png')).hasImage,
          isTrue);
    });

    test('false when imageUrl is null', () {
      expect(Message.fromJson(_baseJson()).hasImage, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Message.toJson
  // -------------------------------------------------------------------------

  group('Message.toJson', () {
    test('serializes type as name string', () {
      expect(Message.fromJson(_baseJson(type: 'image')).toJson()['type'],
          'image');
    });

    test('serializes status as name string', () {
      expect(Message.fromJson(_baseJson(status: 'delivered')).toJson()['status'],
          'delivered');
    });

    test('serializes timestamp as ISO string', () {
      expect(Message.fromJson(_baseJson()).toJson()['timestamp'], isA<String>());
    });

    test('round-trip preserves type and status', () {
      final original = Message.fromJson(
          _baseJson(type: 'challenge', status: 'read'));
      final restored = Message.fromJson(original.toJson());
      expect(restored.type, MessageType.challenge);
      expect(restored.status, MessageStatus.read);
    });
  });

  // -------------------------------------------------------------------------
  // Message.copyWith
  // -------------------------------------------------------------------------

  group('Message.copyWith', () {
    late Message base;
    setUp(() => base = Message.fromJson(_baseJson()));

    test('copies type', () {
      expect(base.copyWith(type: MessageType.image).type, MessageType.image);
    });

    test('copies status', () {
      expect(base.copyWith(status: MessageStatus.delivered).status,
          MessageStatus.delivered);
    });

    test('copies isRead', () {
      expect(base.copyWith(isRead: true).isRead, isTrue);
    });

    test('copies content', () {
      expect(base.copyWith(content: 'New content').content, 'New content');
    });

    test('copies reactions', () {
      expect(base.copyWith(reactions: ['👍']).reactions, ['👍']);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(isRead: true);
      expect(updated.id, base.id);
      expect(updated.senderId, base.senderId);
      expect(updated.conversationId, base.conversationId);
    });
  });
}
