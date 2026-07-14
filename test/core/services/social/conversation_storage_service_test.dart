import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/social/conversation_storage_service.dart';
import 'package:synaptix/game/models/conversation_models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _t0 = DateTime(2026, 1, 1, 12);
final _t1 = DateTime(2026, 1, 1, 13);
final _t2 = DateTime(2026, 1, 1, 14);

Conversation _conv({
  String id = 'c1',
  ConversationType type = ConversationType.direct,
  List<String> participants = const ['u1', 'u2'],
  int unreadCount = 0,
  DateTime? lastMessageTime,
}) =>
    Conversation(
      id: id,
      type: type,
      participantIds: participants,
      unreadCount: unreadCount,
      lastMessageTime: lastMessageTime,
      createdAt: _t0,
      updatedAt: _t0,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ConversationStorageService svc;

  setUp(() {
    svc = ConversationStorageService();
  });

  // -------------------------------------------------------------------------
  // saveConversation
  // -------------------------------------------------------------------------

  group('saveConversation', () {
    test('returns the saved conversation', () async {
      final conv = _conv();
      final saved = await svc.saveConversation(conv);
      expect(saved.id, conv.id);
    });

    test('makes conversation retrievable by id', () async {
      final conv = _conv(id: 'c42');
      await svc.saveConversation(conv);
      expect(svc.getConversationById('c42'), isNotNull);
    });

    test('indexes conversation under all participants', () async {
      final conv = _conv(id: 'c1', participants: ['alice', 'bob']);
      await svc.saveConversation(conv);
      expect(
          svc.getUserConversations('alice').map((c) => c.id), contains('c1'));
      expect(svc.getUserConversations('bob').map((c) => c.id), contains('c1'));
    });
  });

  // -------------------------------------------------------------------------
  // getConversationById
  // -------------------------------------------------------------------------

  group('getConversationById', () {
    test('returns null for unknown id', () {
      expect(svc.getConversationById('unknown'), isNull);
    });

    test('returns the correct conversation', () async {
      await svc.saveConversation(_conv(id: 'c1'));
      expect(svc.getConversationById('c1')?.id, 'c1');
    });
  });

  // -------------------------------------------------------------------------
  // getUserConversations
  // -------------------------------------------------------------------------

  group('getUserConversations', () {
    test('returns empty list for unknown user', () {
      expect(svc.getUserConversations('nobody'), isEmpty);
    });

    test('returns all conversations for a user', () async {
      await svc.saveConversation(_conv(id: 'c1', participants: ['u1', 'u2']));
      await svc.saveConversation(_conv(id: 'c2', participants: ['u1', 'u3']));
      expect(svc.getUserConversations('u1').length, 2);
    });

    test('sorted by lastMessageTime descending', () async {
      await svc.saveConversation(
          _conv(id: 'c1', participants: ['u1'], lastMessageTime: _t0));
      await svc.saveConversation(
          _conv(id: 'c2', participants: ['u1'], lastMessageTime: _t2));
      await svc.saveConversation(
          _conv(id: 'c3', participants: ['u1'], lastMessageTime: _t1));
      final ids = svc.getUserConversations('u1').map((c) => c.id).toList();
      expect(ids, ['c2', 'c3', 'c1']);
    });
  });

  // -------------------------------------------------------------------------
  // getDirectConversations / getGroupConversations
  // -------------------------------------------------------------------------

  group('getDirectConversations', () {
    test('returns only direct-type conversations', () async {
      await svc.saveConversation(_conv(
          id: 'direct', type: ConversationType.direct, participants: ['u1']));
      await svc.saveConversation(_conv(
          id: 'group', type: ConversationType.group, participants: ['u1']));
      final directs = svc.getDirectConversations('u1');
      expect(directs.length, 1);
      expect(directs.first.id, 'direct');
    });
  });

  group('getGroupConversations', () {
    test('returns only group-type conversations', () async {
      await svc.saveConversation(_conv(
          id: 'direct', type: ConversationType.direct, participants: ['u1']));
      await svc.saveConversation(_conv(
          id: 'group', type: ConversationType.group, participants: ['u1']));
      final groups = svc.getGroupConversations('u1');
      expect(groups.length, 1);
      expect(groups.first.id, 'group');
    });
  });

  // -------------------------------------------------------------------------
  // findDirectConversation
  // -------------------------------------------------------------------------

  group('findDirectConversation', () {
    test('finds an existing direct conversation between two users', () async {
      await svc.saveConversation(
        _conv(
            id: 'dm',
            type: ConversationType.direct,
            participants: ['u1', 'u2']),
      );
      final result = svc.findDirectConversation('u1', 'u2');
      expect(result?.id, 'dm');
    });

    test('returns null when no direct conversation exists', () {
      expect(svc.findDirectConversation('u1', 'u99'), isNull);
    });

    test('does not return a group conversation', () async {
      await svc.saveConversation(
        _conv(
            id: 'grp',
            type: ConversationType.group,
            participants: ['u1', 'u2']),
      );
      expect(svc.findDirectConversation('u1', 'u2'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // updateConversation
  // -------------------------------------------------------------------------

  group('updateConversation', () {
    test('updates an existing conversation and returns it', () async {
      await svc.saveConversation(_conv(id: 'c1'));
      final updated = _conv(id: 'c1', unreadCount: 5);
      final result = await svc.updateConversation('c1', updated);
      expect(result?.unreadCount, 5);
      expect(svc.getConversationById('c1')?.unreadCount, 5);
    });

    test('returns null for an unknown conversation id', () async {
      final result = await svc.updateConversation('nope', _conv(id: 'nope'));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // updateLastMessage
  // -------------------------------------------------------------------------

  group('updateLastMessage', () {
    test('sets lastMessageId and lastMessageTime', () async {
      await svc.saveConversation(_conv(id: 'c1'));
      await svc.updateLastMessage('c1', 'msg-42', _t2);
      final conv = svc.getConversationById('c1')!;
      expect(conv.lastMessageId, 'msg-42');
      expect(conv.lastMessageTime, _t2);
    });

    test('is a no-op for unknown conversation id', () async {
      await expectLater(
          svc.updateLastMessage('unknown', 'msg', _t0), completes);
    });
  });

  // -------------------------------------------------------------------------
  // incrementUnreadCount / resetUnreadCount
  // -------------------------------------------------------------------------

  group('incrementUnreadCount', () {
    test('increments count by 1 each call', () async {
      await svc.saveConversation(_conv(id: 'c1', unreadCount: 2));
      await svc.incrementUnreadCount('c1');
      await svc.incrementUnreadCount('c1');
      expect(svc.getConversationById('c1')?.unreadCount, 4);
    });
  });

  group('resetUnreadCount', () {
    test('sets unreadCount to 0', () async {
      await svc.saveConversation(_conv(id: 'c1', unreadCount: 7));
      await svc.resetUnreadCount('c1');
      expect(svc.getConversationById('c1')?.unreadCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // deleteConversation
  // -------------------------------------------------------------------------

  group('deleteConversation', () {
    test('returns true and removes conversation', () async {
      await svc.saveConversation(_conv(id: 'c1', participants: ['u1', 'u2']));
      final result = await svc.deleteConversation('c1');
      expect(result, isTrue);
      expect(svc.getConversationById('c1'), isNull);
    });

    test('removes conversation from participant index', () async {
      await svc.saveConversation(_conv(id: 'c1', participants: ['u1', 'u2']));
      await svc.deleteConversation('c1');
      expect(svc.getUserConversations('u1'), isEmpty);
      expect(svc.getUserConversations('u2'), isEmpty);
    });

    test('returns false for unknown id', () async {
      expect(await svc.deleteConversation('nope'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getTotalUnreadCount
  // -------------------------------------------------------------------------

  group('getTotalUnreadCount', () {
    test('returns 0 for user with no conversations', () {
      expect(svc.getTotalUnreadCount('nobody'), 0);
    });

    test('sums unreadCounts across all user conversations', () async {
      await svc.saveConversation(
          _conv(id: 'c1', participants: ['u1'], unreadCount: 3));
      await svc.saveConversation(
          _conv(id: 'c2', participants: ['u1'], unreadCount: 5));
      expect(svc.getTotalUnreadCount('u1'), 8);
    });
  });

  // -------------------------------------------------------------------------
  // getStats
  // -------------------------------------------------------------------------

  group('getStats', () {
    test('reports correct totalConversations count', () async {
      await svc.saveConversation(_conv(id: 'c1'));
      await svc.saveConversation(_conv(id: 'c2'));
      expect(svc.getStats()['totalConversations'], 2);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear', () {
    test('removes all conversations and user indexes', () async {
      await svc.saveConversation(_conv(id: 'c1', participants: ['u1']));
      svc.clear();
      expect(svc.getConversationById('c1'), isNull);
      expect(svc.getUserConversations('u1'), isEmpty);
      expect(svc.getStats()['totalConversations'], 0);
    });
  });
}
