import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/presence/message_reaction_service.dart';
import 'package:trivia_tycoon/game/models/message_reaction.dart';

void main() {
  late MessageReactionService svc;
  const msgId = 'msg_1';
  const userId = 'user_a';
  const userName = 'Alice';

  setUp(() {
    svc = MessageReactionService();
    svc.initialize();
    // Reset settings to defaults between tests
    svc.updateSettings(
      reactionsEnabled: true,
      customReactionsEnabled: false,
      maxReactionsPerMessage: 50,
      quickReactions: [
        ReactionType.thumbsUp,
        ReactionType.heart,
        ReactionType.laugh,
        ReactionType.wow,
        ReactionType.fire,
        ReactionType.clap,
      ],
    );
  });

  tearDown(() {
    svc.clearMessageReactions(msgId);
    svc.clearMessageReactions('msg_2');
    svc.clearMessageReactions('msg_3');
  });

  // -------------------------------------------------------------------------
  // addReaction
  // -------------------------------------------------------------------------

  group('addReaction', () {
    test('summary created with totalCount=1', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      expect(svc.getReactionSummary(msgId)!.totalCount, 1);
    });

    test('reactions disabled returns false', () async {
      svc.updateSettings(reactionsEnabled: false);
      final result = await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      expect(result, isFalse);
    });

    test('custom emoji with customReactionsEnabled=false returns false',
        () async {
      final result = await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp,
          customEmoji: '🎉');
      expect(result, isFalse);
    });

    test('custom emoji allowed when customReactionsEnabled=true', () async {
      svc.updateSettings(customReactionsEnabled: true);
      final result = await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp,
          customEmoji: '🎉');
      expect(result, isTrue);
    });

    test('max reactions limit returns false', () async {
      svc.updateSettings(maxReactionsPerMessage: 2);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u1',
          userDisplayName: 'U1',
          type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u2',
          userDisplayName: 'U2',
          type: ReactionType.heart);
      final result = await svc.addReaction(
          messageId: msgId,
          userId: 'u3',
          userDisplayName: 'U3',
          type: ReactionType.laugh);
      expect(result, isFalse);
    });

    test('same user reaction replaces old (one-per-user)', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.heart);
      // Still only 1 reaction total
      expect(svc.getReactionSummary(msgId)!.totalCount, 1);
    });

    test('getReactionSummary has correct count after multiple users', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: 'u1',
          userDisplayName: 'U1',
          type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u2',
          userDisplayName: 'U2',
          type: ReactionType.heart);
      expect(svc.getReactionSummary(msgId)!.totalCount, 2);
    });
  });

  // -------------------------------------------------------------------------
  // removeReaction
  // -------------------------------------------------------------------------

  group('removeReaction', () {
    test('returns false for unknown reaction id', () async {
      expect(await svc.removeReaction('nonexistent_id'), isFalse);
    });

    test('removes reaction by id', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      final reactions = svc.getMessageReactions(msgId);
      final reactionId = reactions.first.id;
      final result = await svc.removeReaction(reactionId);
      expect(result, isTrue);
      expect(svc.getMessageReactions(msgId), isEmpty);
    });

    test('totalCount decremented after remove', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: 'u1',
          userDisplayName: 'U1',
          type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u2',
          userDisplayName: 'U2',
          type: ReactionType.heart);
      final reactions = svc.getMessageReactions(msgId);
      await svc.removeReaction(reactions.first.id);
      expect(svc.getReactionSummary(msgId)!.totalCount, 1);
    });

    test('summary removed when count reaches 0', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      final reactions = svc.getMessageReactions(msgId);
      await svc.removeReaction(reactions.first.id);
      expect(svc.getReactionSummary(msgId), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // removeUserReaction
  // -------------------------------------------------------------------------

  group('removeUserReaction', () {
    test('removes user reaction', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.fire);
      final result = await svc.removeUserReaction(msgId, userId);
      expect(result, isTrue);
      expect(svc.getMessageReactions(msgId), isEmpty);
    });

    test('returns false when user has no reaction', () async {
      final result = await svc.removeUserReaction(msgId, 'nobody');
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // toggleReaction
  // -------------------------------------------------------------------------

  group('toggleReaction', () {
    test('adds reaction on first toggle', () async {
      await svc.toggleReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.clap);
      expect(svc.getReactionSummary(msgId)!.totalCount, 1);
    });

    test('removes reaction when same type toggled again', () async {
      await svc.toggleReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.clap);
      await svc.toggleReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.clap);
      expect(svc.getReactionSummary(msgId), isNull);
    });

    test('switches type when different type toggled', () async {
      await svc.toggleReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      await svc.toggleReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.heart);
      // Still 1 reaction but different type
      final reactions = svc.getMessageReactions(msgId);
      expect(reactions.length, 1);
      expect(reactions.first.type, ReactionType.heart);
    });
  });

  // -------------------------------------------------------------------------
  // getMessageReactions
  // -------------------------------------------------------------------------

  group('getMessageReactions', () {
    test('empty list for unknown messageId', () {
      expect(svc.getMessageReactions('unknown_msg'), isEmpty);
    });

    test('list after addReaction', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.wow);
      expect(svc.getMessageReactions(msgId).length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // updateSettings
  // -------------------------------------------------------------------------

  group('updateSettings', () {
    test('reactionsEnabled=false blocks addReaction', () async {
      svc.updateSettings(reactionsEnabled: false);
      expect(svc.reactionsEnabled, isFalse);
      final result = await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      expect(result, isFalse);
    });

    test('customReactionsEnabled=true allows custom emoji', () async {
      svc.updateSettings(customReactionsEnabled: true);
      expect(svc.customReactionsEnabled, isTrue);
    });

    test('maxReactionsPerMessage limit enforced', () async {
      svc.updateSettings(maxReactionsPerMessage: 1);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u1',
          userDisplayName: 'U1',
          type: ReactionType.thumbsUp);
      final result = await svc.addReaction(
          messageId: msgId,
          userId: 'u2',
          userDisplayName: 'U2',
          type: ReactionType.heart);
      expect(result, isFalse);
    });

    test('quickReactions list updated', () {
      svc.updateSettings(
          quickReactions: [ReactionType.fire, ReactionType.heart]);
      expect(svc.quickReactions, [ReactionType.fire, ReactionType.heart]);
    });
  });

  // -------------------------------------------------------------------------
  // clearMessageReactions
  // -------------------------------------------------------------------------

  group('clearMessageReactions', () {
    test('reactions and summary both gone after clear', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      svc.clearMessageReactions(msgId);
      expect(svc.getMessageReactions(msgId), isEmpty);
      expect(svc.getReactionSummary(msgId), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // getPopularReactions
  // -------------------------------------------------------------------------

  group('getPopularReactions', () {
    test('returns sorted descending by count', () async {
      await svc.addReaction(
          messageId: 'msg_2', userId: 'u1', userDisplayName: 'U1', type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: 'msg_2', userId: 'u2', userDisplayName: 'U2', type: ReactionType.thumbsUp);
      await svc.addReaction(
          messageId: 'msg_2', userId: 'u3', userDisplayName: 'U3', type: ReactionType.heart);
      final popular = svc.getPopularReactions(limit: 10);
      if (popular.length >= 2) {
        expect(popular.first.value, greaterThanOrEqualTo(popular[1].value));
      }
    });

    test('limit respected', () async {
      for (final type in ReactionType.values.take(4)) {
        await svc.addReaction(
            messageId: 'msg_3',
            userId: type.code,
            userDisplayName: type.code,
            type: type);
      }
      final popular = svc.getPopularReactions(limit: 2);
      expect(popular.length, lessThanOrEqualTo(2));
    });
  });

  // -------------------------------------------------------------------------
  // getReactionAnalytics
  // -------------------------------------------------------------------------

  group('getReactionAnalytics', () {
    test('returns expected keys', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.fire);
      final analytics = svc.getReactionAnalytics();
      expect(analytics.containsKey('totalMessages'), isTrue);
      expect(analytics.containsKey('totalReactions'), isTrue);
      expect(analytics.containsKey('averageReactionsPerMessage'), isTrue);
      expect(analytics.containsKey('reactionDistribution'), isTrue);
      expect(analytics.containsKey('settingsEnabled'), isTrue);
    });

    test('totalReactions increments', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: userName,
          type: ReactionType.thumbsUp);
      final analytics = svc.getReactionAnalytics();
      expect(analytics['totalReactions'], greaterThanOrEqualTo(1));
    });
  });

  // -------------------------------------------------------------------------
  // getReactionTooltip
  // -------------------------------------------------------------------------

  group('getReactionTooltip', () {
    test('empty string for unknown message', () {
      expect(svc.getReactionTooltip('unknown_msg', ReactionType.thumbsUp), '');
    });

    test('"X reacted with emoji" for 1 user', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: userId,
          userDisplayName: 'Alice',
          type: ReactionType.heart);
      final tooltip = svc.getReactionTooltip(msgId, ReactionType.heart);
      expect(tooltip.contains('Alice'), isTrue);
      expect(tooltip.contains('reacted'), isTrue);
    });

    test('"X, Y reacted" for 2 users', () async {
      await svc.addReaction(
          messageId: msgId,
          userId: 'u1',
          userDisplayName: 'Alice',
          type: ReactionType.clap);
      await svc.addReaction(
          messageId: msgId,
          userId: 'u2',
          userDisplayName: 'Bob',
          type: ReactionType.clap);
      final tooltip = svc.getReactionTooltip(msgId, ReactionType.clap);
      expect(tooltip.contains('Alice') || tooltip.contains('Bob'), isTrue);
    });

    test('"and N others" for 4+ users', () async {
      for (int i = 0; i < 4; i++) {
        await svc.addReaction(
            messageId: msgId,
            userId: 'u$i',
            userDisplayName: 'User$i',
            type: ReactionType.fire);
      }
      final tooltip = svc.getReactionTooltip(msgId, ReactionType.fire);
      expect(tooltip.contains('others'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // canUseCustomReactions
  // -------------------------------------------------------------------------

  group('canUseCustomReactions', () {
    test('false when customReactionsEnabled=false', () {
      expect(svc.canUseCustomReactions(true), isFalse);
    });

    test('false when not premium even if enabled', () {
      svc.updateSettings(customReactionsEnabled: true);
      expect(svc.canUseCustomReactions(false), isFalse);
    });

    test('true when enabled AND user is premium', () {
      svc.updateSettings(customReactionsEnabled: true);
      expect(svc.canUseCustomReactions(true), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getSuggestedReactions
  // -------------------------------------------------------------------------

  group('getSuggestedReactions', () {
    test('"congratulations" includes clap', () {
      final suggestions = svc.getSuggestedReactions('congratulations');
      expect(suggestions.contains(ReactionType.clap), isTrue);
    });

    test('"funny" includes laugh', () {
      final suggestions = svc.getSuggestedReactions('funny');
      expect(suggestions.contains(ReactionType.laugh), isTrue);
    });

    test('includes quickReactions', () {
      final suggestions = svc.getSuggestedReactions('hello');
      for (final qt in svc.quickReactions) {
        expect(suggestions.contains(qt), isTrue);
      }
    });

    test('no duplicates in suggestions', () {
      final suggestions = svc.getSuggestedReactions('amazing congratulations');
      final set = suggestions.toSet();
      expect(suggestions.length, set.length);
    });
  });
}
