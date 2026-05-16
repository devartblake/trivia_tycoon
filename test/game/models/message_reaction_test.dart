import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/message_reaction.dart';

MessageReaction _reaction({
  String id = 'r1',
  String messageId = 'msg1',
  String userId = 'uid_a',
  String userDisplayName = 'Alice',
  ReactionType type = ReactionType.thumbsUp,
  String? customEmoji,
  DateTime? timestamp,
  bool isPremium = false,
}) =>
    MessageReaction(
      id: id,
      messageId: messageId,
      userId: userId,
      userDisplayName: userDisplayName,
      type: type,
      customEmoji: customEmoji,
      timestamp: timestamp ?? DateTime(2025, 6, 1),
      isPremium: isPremium,
    );

void main() {
  // -------------------------------------------------------------------------
  // ReactionType — fromCode
  // -------------------------------------------------------------------------

  group('ReactionType — fromCode', () {
    test('returns correct type for each code', () {
      for (final t in ReactionType.values) {
        expect(ReactionType.fromCode(t.code), t,
            reason: 'code ${t.code} should return $t');
      }
    });

    test('returns null for unknown code', () {
      expect(ReactionType.fromCode('nonexistent'), isNull);
    });
  });

  group('ReactionType — fromEmoji', () {
    test('returns correct type for thumbsUp emoji', () {
      expect(ReactionType.fromEmoji('👍'), ReactionType.thumbsUp);
    });

    test('returns correct type for heart emoji', () {
      expect(ReactionType.fromEmoji('❤️'), ReactionType.heart);
    });

    test('returns null for unknown emoji', () {
      expect(ReactionType.fromEmoji('🐶'), isNull);
    });
  });

  group('ReactionType — isCustom', () {
    test('true only for custom', () {
      expect(ReactionType.custom.isCustom, isTrue);
      for (final t in ReactionType.values) {
        if (t != ReactionType.custom) {
          expect(t.isCustom, isFalse, reason: '${t.name} should not be custom');
        }
      }
    });
  });

  group('ReactionType — isGamingSpecific', () {
    test('true for trophy, brain, target, lightning, gem', () {
      expect(ReactionType.trophy.isGamingSpecific, isTrue);
      expect(ReactionType.brain.isGamingSpecific, isTrue);
      expect(ReactionType.target.isGamingSpecific, isTrue);
      expect(ReactionType.lightning.isGamingSpecific, isTrue);
      expect(ReactionType.gem.isGamingSpecific, isTrue);
    });

    test('false for standard emoji reactions', () {
      expect(ReactionType.thumbsUp.isGamingSpecific, isFalse);
      expect(ReactionType.heart.isGamingSpecific, isFalse);
      expect(ReactionType.laugh.isGamingSpecific, isFalse);
      expect(ReactionType.fire.isGamingSpecific, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // MessageReaction.fromJson
  // -------------------------------------------------------------------------

  group('MessageReaction.fromJson', () {
    Map<String, dynamic> _json({
      String id = 'r1',
      String messageId = 'msg1',
      String userId = 'uid_a',
      String userDisplayName = 'Alice',
      String type = 'thumbs_up',
      String? customEmoji,
      String timestamp = '2025-06-01T10:00:00.000Z',
      bool isPremium = false,
    }) =>
        {
          'id': id,
          'messageId': messageId,
          'userId': userId,
          'userDisplayName': userDisplayName,
          'type': type,
          if (customEmoji != null) 'customEmoji': customEmoji,
          'timestamp': timestamp,
          'isPremium': isPremium,
        };

    test('parses id', () {
      expect(MessageReaction.fromJson(_json(id: 'rxyz')).id, 'rxyz');
    });

    test('parses messageId', () {
      expect(MessageReaction.fromJson(_json(messageId: 'msg99')).messageId,
          'msg99');
    });

    test('parses userId', () {
      expect(MessageReaction.fromJson(_json(userId: 'u123')).userId, 'u123');
    });

    test('parses userDisplayName', () {
      expect(
          MessageReaction.fromJson(_json(userDisplayName: 'Bob'))
              .userDisplayName,
          'Bob');
    });

    test('parses type by code for each ReactionType', () {
      for (final t in ReactionType.values) {
        final r = MessageReaction.fromJson(_json(type: t.code));
        expect(r.type, t);
      }
    });

    test('unknown type falls back to thumbsUp', () {
      final r = MessageReaction.fromJson(_json(type: 'unknown_reaction'));
      expect(r.type, ReactionType.thumbsUp);
    });

    test('parses customEmoji', () {
      final r =
          MessageReaction.fromJson(_json(customEmoji: '🦊', type: 'custom'));
      expect(r.customEmoji, '🦊');
    });

    test('customEmoji is null when absent', () {
      expect(MessageReaction.fromJson(_json()).customEmoji, isNull);
    });

    test('parses timestamp', () {
      final r = MessageReaction.fromJson(
          _json(timestamp: '2025-09-15T14:30:00.000Z'));
      expect(r.timestamp.month, 9);
    });

    test('parses isPremium', () {
      expect(
          MessageReaction.fromJson(_json(isPremium: true)).isPremium, isTrue);
    });

    test('isPremium defaults to false when absent', () {
      final json = _json();
      json.remove('isPremium');
      expect(MessageReaction.fromJson(json).isPremium, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // MessageReaction — displayEmoji
  // -------------------------------------------------------------------------

  group('MessageReaction — displayEmoji', () {
    test('returns type emoji for non-custom type', () {
      final r = _reaction(type: ReactionType.heart);
      expect(r.displayEmoji, ReactionType.heart.emoji);
    });

    test('returns customEmoji for custom type', () {
      final r = _reaction(type: ReactionType.custom, customEmoji: '🦄');
      expect(r.displayEmoji, '🦄');
    });

    test('returns empty string for custom type with no customEmoji', () {
      final r = _reaction(type: ReactionType.custom);
      expect(r.displayEmoji, '');
    });
  });

  // -------------------------------------------------------------------------
  // MessageReaction.toJson
  // -------------------------------------------------------------------------

  group('MessageReaction.toJson', () {
    test('serializes type as code string', () {
      final r = _reaction(type: ReactionType.fire);
      expect(r.toJson()['type'], 'fire');
    });

    test('serializes timestamp as ISO string', () {
      final r = _reaction();
      expect(r.toJson()['timestamp'], isA<String>());
    });

    test('customEmoji absent when null', () {
      expect(_reaction().toJson().containsKey('customEmoji'), isFalse);
    });

    test('customEmoji present when set', () {
      final r = _reaction(customEmoji: '🎉');
      expect(r.toJson()['customEmoji'], '🎉');
    });

    test('round-trip preserves type', () {
      final r = _reaction(type: ReactionType.clap);
      final restored = MessageReaction.fromJson(r.toJson());
      expect(restored.type, ReactionType.clap);
    });
  });

  // -------------------------------------------------------------------------
  // MessageReaction.copyWith
  // -------------------------------------------------------------------------

  group('MessageReaction.copyWith', () {
    test('copies type', () {
      final updated = _reaction().copyWith(type: ReactionType.wow);
      expect(updated.type, ReactionType.wow);
    });

    test('copies userId', () {
      final updated = _reaction().copyWith(userId: 'uid_new');
      expect(updated.userId, 'uid_new');
    });

    test('copies isPremium', () {
      final updated = _reaction().copyWith(isPremium: true);
      expect(updated.isPremium, isTrue);
    });

    test('preserves unchanged fields', () {
      final original = _reaction(id: 'orig', messageId: 'msg_orig');
      final updated = original.copyWith(type: ReactionType.sad);
      expect(updated.id, 'orig');
      expect(updated.messageId, 'msg_orig');
    });
  });

  // -------------------------------------------------------------------------
  // MessageReactionSummary
  // -------------------------------------------------------------------------

  group('MessageReactionSummary', () {
    final ts = DateTime(2025, 6, 1);

    MessageReaction _r(String userId, ReactionType type) => _reaction(
          userId: userId,
          userDisplayName: userId,
          type: type,
          timestamp: ts,
        );

    MessageReactionSummary _summary(
            Map<ReactionType, List<MessageReaction>> reactions,
            {int? totalCount}) =>
        MessageReactionSummary(
          messageId: 'msg1',
          reactions: reactions,
          totalCount:
              totalCount ?? reactions.values.fold(0, (a, b) => a + b.length),
          lastUpdated: ts,
        );

    test('hasReactions false when totalCount is 0', () {
      expect(_summary({}, totalCount: 0).hasReactions, isFalse);
    });

    test('hasReactions true when totalCount > 0', () {
      expect(
          _summary({
            ReactionType.heart: [_r('u1', ReactionType.heart)]
          }).hasReactions,
          isTrue);
    });

    test('reactionTypes returns all present types', () {
      final s = _summary({
        ReactionType.thumbsUp: [_r('u1', ReactionType.thumbsUp)],
        ReactionType.fire: [_r('u2', ReactionType.fire)],
      });
      expect(s.reactionTypes,
          containsAll([ReactionType.thumbsUp, ReactionType.fire]));
    });

    test('getCountForType returns correct count', () {
      final s = _summary({
        ReactionType.heart: [
          _r('u1', ReactionType.heart),
          _r('u2', ReactionType.heart),
        ],
      });
      expect(s.getCountForType(ReactionType.heart), 2);
    });

    test('getCountForType returns 0 for absent type', () {
      expect(_summary({}).getCountForType(ReactionType.thumbsUp), 0);
    });

    test('getReactionsForType returns list', () {
      final r1 = _r('u1', ReactionType.laugh);
      final s = _summary({
        ReactionType.laugh: [r1]
      });
      expect(s.getReactionsForType(ReactionType.laugh), contains(r1));
    });

    test('getReactionsForType returns empty for absent type', () {
      expect(_summary({}).getReactionsForType(ReactionType.wow), isEmpty);
    });

    test('hasUserReacted true when user has reaction', () {
      final s = _summary({
        ReactionType.thumbsUp: [_r('uid_x', ReactionType.thumbsUp)],
      });
      expect(s.hasUserReacted('uid_x'), isTrue);
    });

    test('hasUserReacted false for user with no reaction', () {
      final s = _summary({
        ReactionType.thumbsUp: [_r('uid_x', ReactionType.thumbsUp)],
      });
      expect(s.hasUserReacted('uid_z'), isFalse);
    });

    test('getUserReactionType returns correct type', () {
      final s = _summary({
        ReactionType.fire: [_r('uid_a', ReactionType.fire)],
      });
      expect(s.getUserReactionType('uid_a'), ReactionType.fire);
    });

    test('getUserReactionType returns null for absent user', () {
      expect(_summary({}).getUserReactionType('nobody'), isNull);
    });

    test('getUserReaction returns the specific reaction', () {
      final r1 = _r('uid_b', ReactionType.clap);
      final s = _summary({
        ReactionType.clap: [r1]
      });
      expect(s.getUserReaction('uid_b'), r1);
    });

    test('getTopReactions respects limit', () {
      final s = _summary({
        ReactionType.heart: [
          _r('u1', ReactionType.heart),
          _r('u2', ReactionType.heart),
        ],
        ReactionType.fire: [_r('u3', ReactionType.fire)],
        ReactionType.thumbsUp: [
          _r('u4', ReactionType.thumbsUp),
          _r('u5', ReactionType.thumbsUp),
          _r('u6', ReactionType.thumbsUp),
        ],
        ReactionType.wow: [_r('u7', ReactionType.wow)],
      });
      final top = s.getTopReactions(limit: 2);
      expect(top.length, 2);
    });

    test('getTopReactions sorted descending by count', () {
      final s = _summary({
        ReactionType.heart: [
          _r('u1', ReactionType.heart),
          _r('u2', ReactionType.heart),
          _r('u3', ReactionType.heart),
        ],
        ReactionType.fire: [_r('u4', ReactionType.fire)],
      });
      final top = s.getTopReactions();
      expect(top.first.key, ReactionType.heart);
      expect(top.first.value, 3);
    });

    test('getFormattedSummary returns empty when no reactions', () {
      expect(_summary({}, totalCount: 0).getFormattedSummary(), '');
    });

    test('getFormattedSummary returns non-empty when reactions present', () {
      final s = _summary({
        ReactionType.thumbsUp: [_r('u1', ReactionType.thumbsUp)],
      });
      expect(s.getFormattedSummary(), isNotEmpty);
    });

    test('getUsersForReaction returns display names', () {
      final s = _summary({
        ReactionType.party: [
          _reaction(
              userId: 'uid_a',
              userDisplayName: 'Alice',
              type: ReactionType.party),
          _reaction(
              userId: 'uid_b',
              userDisplayName: 'Bob',
              type: ReactionType.party),
        ],
      });
      final users = s.getUsersForReaction(ReactionType.party);
      expect(users, containsAll(['Alice', 'Bob']));
    });

    test('getUsersForReaction returns empty for absent type', () {
      expect(_summary({}).getUsersForReaction(ReactionType.gem), isEmpty);
    });
  });
}
