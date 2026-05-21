import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/social/challenge_message_bridge.dart';
import 'package:trivia_tycoon/core/services/social/conversation_storage_service.dart';
import 'package:trivia_tycoon/core/services/storage/message_storage_service.dart';
import 'package:trivia_tycoon/game/models/message_models.dart';
import 'package:trivia_tycoon/game/models/pvp_challenge_models.dart';

void main() {
  late MessageStorageService msgStorage;
  late ConversationStorageService convStorage;
  late ChallengeMessageBridge bridge;

  setUp(() {
    msgStorage = MessageStorageService();
    convStorage = ConversationStorageService();
    bridge = ChallengeMessageBridge(
      messageStorage: msgStorage,
      conversationStorage: convStorage,
    );
  });

  PVPChallenge _challenge({
    String id = 'challenge_1',
    String challengerId = 'user_a',
    String challengerName = 'Alice',
    String opponentId = 'user_b',
    String opponentName = 'Bob',
    String category = 'science',
    int questionCount = 5,
    String difficulty = 'medium',
    int wager = 0,
    PVPChallengeStatus status = PVPChallengeStatus.pending,
    String? challengerScore,
    String? opponentScore,
    String? winnerId,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    final now = DateTime.now();
    return PVPChallenge(
      id: id,
      challengerId: challengerId,
      challengerName: challengerName,
      opponentId: opponentId,
      opponentName: opponentName,
      category: category,
      questionCount: questionCount,
      difficulty: difficulty,
      wager: wager,
      status: status,
      createdAt: now,
      acceptedAt: acceptedAt,
      completedAt: completedAt,
      expiresAt: now.add(const Duration(hours: 24)),
      challengerScore: challengerScore,
      opponentScore: opponentScore,
      winnerId: winnerId,
    );
  }

  // -------------------------------------------------------------------------
  // _getConversationId — deterministic, sorted
  // -------------------------------------------------------------------------

  group('conversation ID generation', () {
    test('onChallengeCreated creates conversation with sorted-ID key', () async {
      final challenge = _challenge(challengerId: 'user_b', opponentId: 'user_a');
      await bridge.onChallengeCreated(challenge);
      // sorted: user_a < user_b → conv_user_a_user_b
      final conv = convStorage.getConversationById('conv_user_a_user_b');
      expect(conv, isNotNull);
    });

    test('conversation ID is the same regardless of challenger/opponent order', () async {
      final c1 = _challenge(challengerId: 'user_x', opponentId: 'user_z');
      final c2 = _challenge(challengerId: 'user_z', opponentId: 'user_x');
      await bridge.onChallengeCreated(c1);
      await bridge.onChallengeCreated(c2);
      // Both use same conversation ID since sorted IDs are identical
      final conv = convStorage.getConversationById('conv_user_x_user_z');
      expect(conv, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // onChallengeCreated
  // -------------------------------------------------------------------------

  group('onChallengeCreated', () {
    test('saves a message of type challengeRequest', () async {
      final challenge = _challenge();
      await bridge.onChallengeCreated(challenge);
      final convId = 'conv_user_a_user_b';
      final messages = msgStorage.getMessagesByType(convId, MessageType.challengeRequest);
      expect(messages, hasLength(1));
    });

    test('message senderId matches challengerId', () async {
      final challenge = _challenge();
      await bridge.onChallengeCreated(challenge);
      final messages = msgStorage.getMessagesByType(
          'conv_user_a_user_b', MessageType.challengeRequest);
      expect(messages.first.senderId, 'user_a');
      expect(messages.first.senderName, 'Alice');
    });

    test('message content includes category', () async {
      final challenge = _challenge(category: 'history', wager: 0);
      await bridge.onChallengeCreated(challenge);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeRequest)
          .first;
      expect(msg.content, contains('history'));
    });

    test('message content includes wager when wager > 0', () async {
      final challenge = _challenge(wager: 100);
      await bridge.onChallengeCreated(challenge);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeRequest)
          .first;
      expect(msg.content, contains('100'));
    });

    test('message metadata contains challengeId', () async {
      final challenge = _challenge(id: 'chall_42');
      await bridge.onChallengeCreated(challenge);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeRequest)
          .first;
      expect(msg.metadata?['challengeId'], 'chall_42');
    });

    test('creates conversation automatically if it does not exist', () async {
      expect(convStorage.getConversationById('conv_user_a_user_b'), isNull);
      await bridge.onChallengeCreated(_challenge());
      expect(convStorage.getConversationById('conv_user_a_user_b'), isNotNull);
    });

    test('updates conversation last message after creating message', () async {
      await bridge.onChallengeCreated(_challenge());
      final conv = convStorage.getConversationById('conv_user_a_user_b')!;
      expect(conv.lastMessageId, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // onChallengeAccepted
  // -------------------------------------------------------------------------

  group('onChallengeAccepted', () {
    test('saves a message of type challengeAccepted', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeAccepted(_challenge(
        status: PVPChallengeStatus.accepted,
        acceptedAt: DateTime.now(),
      ));
      final msgs = msgStorage.getMessagesByType(
          'conv_user_a_user_b', MessageType.challengeAccepted);
      expect(msgs, hasLength(1));
    });

    test('accepted message senderId is opponentId', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeAccepted(_challenge(
        status: PVPChallengeStatus.accepted,
        acceptedAt: DateTime.now(),
      ));
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeAccepted)
          .first;
      expect(msg.senderId, 'user_b');
      expect(msg.senderName, 'Bob');
    });

    test('accepted message content is "Accepted your challenge!"', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeAccepted(_challenge(
        status: PVPChallengeStatus.accepted,
        acceptedAt: DateTime.now(),
      ));
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeAccepted)
          .first;
      expect(msg.content, 'Accepted your challenge!');
    });
  });

  // -------------------------------------------------------------------------
  // onChallengeCompleted
  // -------------------------------------------------------------------------

  group('onChallengeCompleted', () {
    test('saves a message of type challengeResult', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), 'user_a', 50);
      final msgs = msgStorage.getMessagesByType(
          'conv_user_a_user_b', MessageType.challengeResult);
      expect(msgs, hasLength(1));
    });

    test('result message is delivered status', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), 'user_a', 50);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.status, MessageStatus.delivered);
    });

    test('result content names challenger as winner when winnerId=challengerId', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), 'user_a', 75);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.content, contains('Alice'));
      expect(msg.content, contains('75'));
    });

    test('result content names opponent as winner when winnerId=opponentId', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), 'user_b', 30);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.content, contains('Bob'));
      expect(msg.content, contains('30'));
    });

    test('draw result when winnerId is empty', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), '', 0);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.content, 'Challenge ended in a draw!');
    });

    test('result metadata contains challengeId and winnerId', () async {
      await bridge.onChallengeCreated(_challenge(id: 'chal_99'));
      await bridge.onChallengeCompleted(_challenge(id: 'chal_99'), 'user_a', 100);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.metadata?['challengeId'], 'chal_99');
      expect(msg.metadata?['winnerId'], 'user_a');
      expect(msg.metadata?['coinsWon'], 100);
    });

    test('result message senderId is "system"', () async {
      await bridge.onChallengeCreated(_challenge());
      await bridge.onChallengeCompleted(_challenge(), 'user_a', 10);
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.challengeResult)
          .first;
      expect(msg.senderId, 'system');
    });
  });
}
