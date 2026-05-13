import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/conversation_models.dart';

Map<String, dynamic> _baseJson({
  String id = 'conv1',
  String type = 'direct',
  List<dynamic>? participantIds,
  String? name,
  String? avatar,
  String? lastMessageId,
  String? lastMessageTime,
  int unreadCount = 0,
  Map<String, dynamic>? metadata,
  String createdAt = '2025-01-01T08:00:00.000Z',
  String updatedAt = '2025-06-01T12:00:00.000Z',
}) =>
    {
      'id': id,
      'type': type,
      'participantIds': participantIds ?? ['uid_a', 'uid_b'],
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (lastMessageId != null) 'lastMessageId': lastMessageId,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

void main() {
  // -------------------------------------------------------------------------
  // Conversation.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('Conversation.fromJson — scalar fields', () {
    test('parses id', () {
      expect(Conversation.fromJson(_baseJson(id: 'c99')).id, 'c99');
    });

    test('parses name', () {
      expect(
          Conversation.fromJson(_baseJson(name: 'Study Group')).name,
          'Study Group');
    });

    test('name is null when absent', () {
      expect(Conversation.fromJson(_baseJson()).name, isNull);
    });

    test('parses avatar', () {
      expect(
          Conversation.fromJson(_baseJson(avatar: 'https://img.test/g.png'))
              .avatar,
          'https://img.test/g.png');
    });

    test('avatar is null when absent', () {
      expect(Conversation.fromJson(_baseJson()).avatar, isNull);
    });

    test('parses lastMessageId', () {
      expect(
          Conversation.fromJson(_baseJson(lastMessageId: 'msg_42'))
              .lastMessageId,
          'msg_42');
    });

    test('lastMessageId is null when absent', () {
      expect(Conversation.fromJson(_baseJson()).lastMessageId, isNull);
    });

    test('parses unreadCount', () {
      expect(
          Conversation.fromJson(_baseJson(unreadCount: 5)).unreadCount, 5);
    });

    test('unreadCount defaults to 0 when absent', () {
      final json = _baseJson();
      json.remove('unreadCount');
      expect(Conversation.fromJson(json).unreadCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.fromJson — DateTime fields
  // -------------------------------------------------------------------------

  group('Conversation.fromJson — DateTime fields', () {
    test('parses createdAt', () {
      final c = Conversation.fromJson(
          _baseJson(createdAt: '2024-03-15T09:00:00.000Z'));
      expect(c.createdAt.month, 3);
    });

    test('parses updatedAt', () {
      final c = Conversation.fromJson(
          _baseJson(updatedAt: '2025-07-04T00:00:00.000Z'));
      expect(c.updatedAt.month, 7);
    });

    test('parses lastMessageTime', () {
      final c = Conversation.fromJson(
          _baseJson(lastMessageTime: '2025-06-01T15:30:00.000Z'));
      expect(c.lastMessageTime, isNotNull);
    });

    test('lastMessageTime is null when absent', () {
      expect(Conversation.fromJson(_baseJson()).lastMessageTime, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.fromJson — type parsing
  // -------------------------------------------------------------------------

  group('Conversation.fromJson — type parsing', () {
    test('direct → ConversationType.direct', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'direct')).type,
          ConversationType.direct);
    });

    test('group → ConversationType.group', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'group')).type,
          ConversationType.group);
    });

    test('system → ConversationType.system', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'system')).type,
          ConversationType.system);
    });

    test('challenge → ConversationType.challenge', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'challenge')).type,
          ConversationType.challenge);
    });

    test('friendRequest → ConversationType.friendRequest', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'friendRequest')).type,
          ConversationType.friendRequest);
    });

    test('friend_request → ConversationType.friendRequest', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'friend_request')).type,
          ConversationType.friendRequest);
    });

    test('unknown type falls back to direct', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'unknown')).type,
          ConversationType.direct);
    });

    test('null type falls back to direct', () {
      final json = _baseJson();
      json.remove('type');
      expect(Conversation.fromJson(json).type, ConversationType.direct);
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.fromJson — participantIds parsing
  // -------------------------------------------------------------------------

  group('Conversation.fromJson — participantIds', () {
    test('parses string list', () {
      final c = Conversation.fromJson(
          _baseJson(participantIds: ['uid_x', 'uid_y']));
      expect(c.participantIds, ['uid_x', 'uid_y']);
    });

    test('parses map entries extracting playerId', () {
      final c = Conversation.fromJson({
        ..._baseJson(),
        'participantIds': [
          {'playerId': 'uid_1'},
          {'playerId': 'uid_2'},
        ],
      });
      expect(c.participantIds, contains('uid_1'));
      expect(c.participantIds, contains('uid_2'));
    });

    test('parses map entries extracting id fallback', () {
      final c = Conversation.fromJson({
        ..._baseJson(),
        'participantIds': [
          {'id': 'uid_3'},
        ],
      });
      expect(c.participantIds, contains('uid_3'));
    });

    test('uses participants key as fallback', () {
      final json = _baseJson();
      json.remove('participantIds');
      json['participants'] = ['p1', 'p2'];
      final c = Conversation.fromJson(json);
      expect(c.participantIds, ['p1', 'p2']);
    });

    test('filters empty string participants', () {
      final json = _baseJson();
      json['participantIds'] = [
        {'id': ''},
        {'id': 'uid_valid'},
      ];
      final c = Conversation.fromJson(json);
      expect(c.participantIds, contains('uid_valid'));
      expect(c.participantIds, isNot(contains('')));
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.fromJson — metadata merging
  // -------------------------------------------------------------------------

  group('Conversation.fromJson — metadata', () {
    test('merges top-level displayTitle into metadata', () {
      final json = _baseJson();
      json['displayTitle'] = 'My Chat';
      final c = Conversation.fromJson(json);
      expect(c.metadata!['displayTitle'], 'My Chat');
    });

    test('merges top-level lastMessagePreview into metadata', () {
      final json = _baseJson();
      json['lastMessagePreview'] = 'Hello!';
      final c = Conversation.fromJson(json);
      expect(c.metadata!['lastMessagePreview'], 'Hello!');
    });

    test('parses latestMessageId fallback', () {
      final json = _baseJson();
      json['latestMessageId'] = 'latest_msg';
      final c = Conversation.fromJson(json);
      expect(c.lastMessageId, 'latest_msg');
    });
  });

  // -------------------------------------------------------------------------
  // Conversation — computed properties
  // -------------------------------------------------------------------------

  group('Conversation — isGroupChat / isDirectMessage', () {
    test('isGroupChat true for group type', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'group')).isGroupChat(), isTrue);
    });

    test('isGroupChat false for direct type', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'direct')).isGroupChat(),
          isFalse);
    });

    test('isDirectMessage true for direct type', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'direct')).isDirectMessage(),
          isTrue);
    });

    test('isDirectMessage false for group type', () {
      expect(
          Conversation.fromJson(_baseJson(type: 'group')).isDirectMessage(),
          isFalse);
    });
  });

  group('Conversation — displayTitle', () {
    test('returns name when set', () {
      final c = Conversation.fromJson(_baseJson(name: 'Study Group'));
      expect(c.displayTitle, 'Study Group');
    });

    test('falls back to metadata displayTitle', () {
      final json = _baseJson();
      json['displayTitle'] = 'DM with Bob';
      final c = Conversation.fromJson(json);
      expect(c.displayTitle, 'DM with Bob');
    });

    test('falls back to "Direct Message" when no name or metadata', () {
      expect(Conversation.fromJson(_baseJson()).displayTitle, 'Direct Message');
    });
  });

  group('Conversation — lastMessagePreview', () {
    test('returns metadata preview', () {
      final json = _baseJson();
      json['lastMessagePreview'] = 'Hey there!';
      final c = Conversation.fromJson(json);
      expect(c.lastMessagePreview, 'Hey there!');
    });

    test('falls back to "Tap to view messages" when absent', () {
      expect(
          Conversation.fromJson(_baseJson()).lastMessagePreview,
          'Tap to view messages');
    });
  });

  group('Conversation — getOtherParticipantId', () {
    test('returns other participant for direct conversation', () {
      final c = Conversation.fromJson(
          _baseJson(type: 'direct', participantIds: ['uid_a', 'uid_b']));
      expect(c.getOtherParticipantId('uid_a'), 'uid_b');
    });

    test('returns null for non-direct conversation', () {
      final c = Conversation.fromJson(
          _baseJson(type: 'group', participantIds: ['uid_a', 'uid_b']));
      expect(c.getOtherParticipantId('uid_a'), isNull);
    });

    test('returns empty string when no other participant found', () {
      final c = Conversation.fromJson(
          _baseJson(type: 'direct', participantIds: ['uid_a']));
      expect(c.getOtherParticipantId('uid_a'), '');
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.toJson
  // -------------------------------------------------------------------------

  group('Conversation.toJson', () {
    test('serializes type as name string', () {
      final c = Conversation.fromJson(_baseJson(type: 'group'));
      expect(c.toJson()['type'], 'group');
    });

    test('serializes createdAt as ISO string', () {
      final c = Conversation.fromJson(_baseJson());
      expect(c.toJson()['createdAt'], isA<String>());
    });

    test('round-trip preserves id and type', () {
      final original = Conversation.fromJson(
          _baseJson(id: 'orig_conv', type: 'challenge'));
      final restored = Conversation.fromJson(original.toJson());
      expect(restored.id, 'orig_conv');
      expect(restored.type, ConversationType.challenge);
    });
  });

  // -------------------------------------------------------------------------
  // Conversation.copyWith
  // -------------------------------------------------------------------------

  group('Conversation.copyWith', () {
    late Conversation base;
    setUp(() => base = Conversation.fromJson(_baseJson()));

    test('copies type', () {
      expect(
          base.copyWith(type: ConversationType.group).type,
          ConversationType.group);
    });

    test('copies unreadCount', () {
      expect(base.copyWith(unreadCount: 10).unreadCount, 10);
    });

    test('copies name', () {
      expect(base.copyWith(name: 'New Name').name, 'New Name');
    });

    test('copies participantIds', () {
      final updated = base.copyWith(participantIds: ['uid_x']);
      expect(updated.participantIds, ['uid_x']);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(unreadCount: 3);
      expect(updated.id, base.id);
      expect(updated.type, base.type);
    });
  });
}
