import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/group_chat_models.dart';

Map<String, dynamic> _inviteJson({
  String id = 'inv1',
  String groupId = 'grp1',
  String groupName = 'Study Squad',
  String inviterId = 'uid_a',
  String inviterName = 'Alice',
  String inviteeId = 'uid_b',
  String createdAt = '2025-06-01T08:00:00.000Z',
  String? expiresAt,
  bool isAccepted = false,
  bool isDeclined = false,
}) =>
    {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'createdAt': createdAt,
      if (expiresAt != null) 'expiresAt': expiresAt,
      'isAccepted': isAccepted,
      'isDeclined': isDeclined,
    };

Map<String, dynamic> _msgJson({
  String id = 'gm1',
  String groupId = 'grp1',
  String senderId = 'uid_a',
  String senderName = 'Alice',
  String content = 'Hello group!',
  String timestamp = '2025-06-01T10:00:00.000Z',
  bool isSystemMessage = false,
  String? replyToMessageId,
  Map<String, dynamic>? metadata,
}) =>
    {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp,
      'isSystemMessage': isSystemMessage,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (metadata != null) 'metadata': metadata,
    };

void main() {
  // -------------------------------------------------------------------------
  // GroupChatInvitation.fromJson
  // -------------------------------------------------------------------------

  group('GroupChatInvitation.fromJson — scalar fields', () {
    test('parses id', () {
      expect(GroupChatInvitation.fromJson(_inviteJson(id: 'i99')).id, 'i99');
    });

    test('parses groupId', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(groupId: 'g42')).groupId,
          'g42');
    });

    test('parses groupName', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(groupName: 'Quiz Club'))
              .groupName,
          'Quiz Club');
    });

    test('parses inviterId', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(inviterId: 'uid_x'))
              .inviterId,
          'uid_x');
    });

    test('parses inviterName', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(inviterName: 'Bob'))
              .inviterName,
          'Bob');
    });

    test('parses inviteeId', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(inviteeId: 'uid_y'))
              .inviteeId,
          'uid_y');
    });

    test('parses isAccepted', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(isAccepted: true))
              .isAccepted,
          isTrue);
    });

    test('isAccepted defaults to false when absent', () {
      final json = _inviteJson();
      json.remove('isAccepted');
      expect(GroupChatInvitation.fromJson(json).isAccepted, isFalse);
    });

    test('parses isDeclined', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(isDeclined: true))
              .isDeclined,
          isTrue);
    });

    test('isDeclined defaults to false when absent', () {
      final json = _inviteJson();
      json.remove('isDeclined');
      expect(GroupChatInvitation.fromJson(json).isDeclined, isFalse);
    });
  });

  group('GroupChatInvitation.fromJson — DateTime fields', () {
    test('parses createdAt', () {
      final inv = GroupChatInvitation.fromJson(
          _inviteJson(createdAt: '2025-03-15T09:00:00.000Z'));
      expect(inv.createdAt.month, 3);
    });

    test('parses expiresAt', () {
      final inv = GroupChatInvitation.fromJson(
          _inviteJson(expiresAt: '2025-06-08T08:00:00.000Z'));
      expect(inv.expiresAt, isNotNull);
      expect(inv.expiresAt!.day, 8);
    });

    test('expiresAt is null when absent', () {
      expect(GroupChatInvitation.fromJson(_inviteJson()).expiresAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatInvitation — computed: isPending / isExpired
  // -------------------------------------------------------------------------

  group('GroupChatInvitation — isPending', () {
    test('true when not accepted and not declined', () {
      expect(GroupChatInvitation.fromJson(_inviteJson()).isPending, isTrue);
    });

    test('false when accepted', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(isAccepted: true)).isPending,
          isFalse);
    });

    test('false when declined', () {
      expect(
          GroupChatInvitation.fromJson(_inviteJson(isDeclined: true)).isPending,
          isFalse);
    });
  });

  group('GroupChatInvitation — isExpired', () {
    test('false when expiresAt is null', () {
      expect(GroupChatInvitation.fromJson(_inviteJson()).isExpired, isFalse);
    });

    test('true when expiresAt is in the past', () {
      final past =
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      expect(
          GroupChatInvitation.fromJson(_inviteJson(expiresAt: past)).isExpired,
          isTrue);
    });

    test('false when expiresAt is in the future', () {
      final future =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();
      expect(
          GroupChatInvitation.fromJson(_inviteJson(expiresAt: future)).isExpired,
          isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatInvitation.toJson
  // -------------------------------------------------------------------------

  group('GroupChatInvitation.toJson', () {
    test('serializes createdAt as ISO string', () {
      final inv = GroupChatInvitation.fromJson(_inviteJson());
      expect(inv.toJson()['createdAt'], isA<String>());
    });

    test('expiresAt absent from toJson when null', () {
      final inv = GroupChatInvitation.fromJson(_inviteJson());
      expect(inv.toJson().containsKey('expiresAt'), isFalse);
    });

    test('expiresAt present in toJson when set', () {
      final future =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();
      final inv = GroupChatInvitation.fromJson(_inviteJson(expiresAt: future));
      expect(inv.toJson().containsKey('expiresAt'), isTrue);
    });

    test('round-trip preserves all scalar fields', () {
      final original = GroupChatInvitation.fromJson(_inviteJson(
        isAccepted: true,
        expiresAt: '2025-07-01T00:00:00.000Z',
      ));
      final restored = GroupChatInvitation.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.groupId, original.groupId);
      expect(restored.isAccepted, original.isAccepted);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatInvitation.copyWith
  // -------------------------------------------------------------------------

  group('GroupChatInvitation.copyWith', () {
    late GroupChatInvitation base;
    setUp(() => base = GroupChatInvitation.fromJson(_inviteJson()));

    test('copies isAccepted', () {
      expect(base.copyWith(isAccepted: true).isAccepted, isTrue);
    });

    test('copies isDeclined', () {
      expect(base.copyWith(isDeclined: true).isDeclined, isTrue);
    });

    test('copies groupName', () {
      expect(base.copyWith(groupName: 'New Group').groupName, 'New Group');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(isAccepted: true);
      expect(updated.id, base.id);
      expect(updated.inviteeId, base.inviteeId);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatMessage.fromJson
  // -------------------------------------------------------------------------

  group('GroupChatMessage.fromJson — scalar fields', () {
    test('parses id', () {
      expect(GroupChatMessage.fromJson(_msgJson(id: 'gm99')).id, 'gm99');
    });

    test('parses groupId', () {
      expect(GroupChatMessage.fromJson(_msgJson(groupId: 'g99')).groupId, 'g99');
    });

    test('parses senderId', () {
      expect(
          GroupChatMessage.fromJson(_msgJson(senderId: 'u_x')).senderId, 'u_x');
    });

    test('parses senderName', () {
      expect(
          GroupChatMessage.fromJson(_msgJson(senderName: 'Bob')).senderName,
          'Bob');
    });

    test('parses content', () {
      expect(GroupChatMessage.fromJson(_msgJson(content: 'Hi!')).content, 'Hi!');
    });

    test('parses isSystemMessage', () {
      expect(
          GroupChatMessage.fromJson(_msgJson(isSystemMessage: true))
              .isSystemMessage,
          isTrue);
    });

    test('isSystemMessage defaults to false when absent', () {
      final json = _msgJson();
      json.remove('isSystemMessage');
      expect(GroupChatMessage.fromJson(json).isSystemMessage, isFalse);
    });

    test('parses replyToMessageId', () {
      expect(
          GroupChatMessage.fromJson(
                  _msgJson(replyToMessageId: 'orig_msg'))
              .replyToMessageId,
          'orig_msg');
    });

    test('replyToMessageId is null when absent', () {
      expect(
          GroupChatMessage.fromJson(_msgJson()).replyToMessageId, isNull);
    });

    test('parses metadata', () {
      final msg = GroupChatMessage.fromJson(
          _msgJson(metadata: {'action': 'join', 'userId': 'u1'}));
      expect(msg.metadata!['action'], 'join');
    });

    test('metadata is null when absent', () {
      expect(GroupChatMessage.fromJson(_msgJson()).metadata, isNull);
    });
  });

  group('GroupChatMessage.fromJson — timestamp', () {
    test('parses timestamp', () {
      final msg = GroupChatMessage.fromJson(
          _msgJson(timestamp: '2025-09-10T12:00:00.000Z'));
      expect(msg.timestamp.month, 9);
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatMessage.toJson
  // -------------------------------------------------------------------------

  group('GroupChatMessage.toJson', () {
    test('serializes timestamp as ISO string', () {
      expect(GroupChatMessage.fromJson(_msgJson()).toJson()['timestamp'],
          isA<String>());
    });

    test('replyToMessageId absent from toJson when null', () {
      expect(
          GroupChatMessage.fromJson(_msgJson()).toJson().containsKey(
              'replyToMessageId'),
          isFalse);
    });

    test('replyToMessageId present when set', () {
      final msg = GroupChatMessage.fromJson(
          _msgJson(replyToMessageId: 'ref_msg'));
      expect(msg.toJson()['replyToMessageId'], 'ref_msg');
    });

    test('metadata absent from toJson when null', () {
      expect(
          GroupChatMessage.fromJson(_msgJson()).toJson().containsKey('metadata'),
          isFalse);
    });

    test('round-trip preserves content', () {
      final original = GroupChatMessage.fromJson(_msgJson(content: 'Test msg'));
      final restored = GroupChatMessage.fromJson(original.toJson());
      expect(restored.content, 'Test msg');
    });
  });

  // -------------------------------------------------------------------------
  // GroupChatMessage.system factory
  // -------------------------------------------------------------------------

  group('GroupChatMessage.system factory', () {
    test('creates system message with correct fields', () {
      final msg = GroupChatMessage.system(
        groupId: 'grp_x',
        content: 'Alice joined the group',
      );
      expect(msg.groupId, 'grp_x');
      expect(msg.content, 'Alice joined the group');
      expect(msg.isSystemMessage, isTrue);
      expect(msg.senderId, 'system');
      expect(msg.senderName, 'System');
    });

    test('id starts with "sys_"', () {
      final msg = GroupChatMessage.system(
        groupId: 'g1',
        content: 'Test',
      );
      expect(msg.id.startsWith('sys_'), isTrue);
    });

    test('includes metadata when provided', () {
      final msg = GroupChatMessage.system(
        groupId: 'g1',
        content: 'Test',
        metadata: {'event': 'join'},
      );
      expect(msg.metadata!['event'], 'join');
    });
  });
}
