import 'package:flutter/foundation.dart';
import '../../../game/models/conversation_models.dart';
import '../../../game/models/message_models.dart';
import '../../../game/models/pvp_challenge_models.dart';
import '../storage/message_storage_service.dart';
import 'conversation_storage_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Lightweight bridge between Challenge system and Message system
/// Listens to challenge events and creates appropriate messages
class ChallengeMessageBridge {
  final MessageStorageService _messageStorage;
  final ConversationStorageService _conversationStorage;

  ChallengeMessageBridge({
    required MessageStorageService messageStorage,
    required ConversationStorageService conversationStorage,
  })  : _messageStorage = messageStorage,
        _conversationStorage = conversationStorage;

  /// Called when a challenge is created
  Future<void> onChallengeCreated(PVPChallenge challenge) async {
    final conversationId = _getConversationId(
      challenge.challengerId,
      challenge.opponentId,
    );

    // Ensure conversation exists
    await _ensureConversationExists(
      conversationId,
      challenge.challengerId,
      challenge.opponentId,
    );

    final message = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: challenge.challengerId,
      senderName: challenge.challengerName,
      content: _getChallengeCreatedContent(challenge),
      type: MessageType.challengeRequest,
      status: MessageStatus.sent,
      timestamp: challenge.createdAt,
      metadata: {
        'challengeId': challenge.id,
        'category': challenge.category,
        'questionCount': challenge.questionCount,
        'difficulty': challenge.difficulty,
        'wager': challenge.wager,
      },
    );

    await _messageStorage.saveMessage(message);
    await _conversationStorage.updateLastMessage(
      conversationId,
      message.id,
      message.timestamp,
    );

    LogManager.debug('Challenge message created for challenge: ${challenge.id}');
  }

  /// Called when a challenge is accepted
  Future<void> onChallengeAccepted(PVPChallenge challenge) async {
    final conversationId = _getConversationId(
      challenge.challengerId,
      challenge.opponentId,
    );

    final message = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: challenge.opponentId,
      senderName: challenge.opponentName,
      content: 'Accepted your challenge!',
      type: MessageType.challengeAccepted,
      status: MessageStatus.sent,
      timestamp: challenge.acceptedAt ?? DateTime.now(),
      metadata: {
        'challengeId': challenge.id,
        'category': challenge.category,
      },
    );

    await _messageStorage.saveMessage(message);
    await _conversationStorage.updateLastMessage(
      conversationId,
      message.id,
      message.timestamp,
    );
  }

  /// Called when a challenge is completed
  Future<void> onChallengeCompleted(
      PVPChallenge challenge,
      String winnerId,
      int coinsWon,
      ) async {
    final conversationId = _getConversationId(
      challenge.challengerId,
      challenge.opponentId,
    );

    // Send result message to both participants
    final resultMessage = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: 'system',
      senderName: 'Synaptix',
      content: _getChallengeResultContent(challenge, winnerId, coinsWon),
      type: MessageType.challengeResult,
      status: MessageStatus.delivered,
      timestamp: challenge.completedAt ?? DateTime.now(),
      metadata: {
        'challengeId': challenge.id,
        'winnerId': winnerId,
        'challengerScore': challenge.challengerScore,
        'opponentScore': challenge.opponentScore,
        'coinsWon': coinsWon,
      },
    );

    await _messageStorage.saveMessage(resultMessage);
    await _conversationStorage.updateLastMessage(
      conversationId,
      resultMessage.id,
      resultMessage.timestamp,
    );
  }

  // ============ Helper Methods ============

  String _getChallengeCreatedContent(PVPChallenge challenge) {
    final wagerText = challenge.wager > 0
        ? ' for ${challenge.wager} coins'
        : '';
    return 'Challenged you to a ${challenge.category} quiz$wagerText!';
  }

  String _getChallengeResultContent(
      PVPChallenge challenge,
      String winnerId,
      int coinsWon,
      ) {
    if (winnerId.isEmpty) {
      return 'Challenge ended in a draw!';
    }

    final winnerName = winnerId == challenge.challengerId
        ? challenge.challengerName
        : challenge.opponentName;

    return '$winnerName won the challenge! (+$coinsWon coins)';
  }

  Future<void> _ensureConversationExists(
      String conversationId,
      String userId1,
      String userId2,
      ) async {
    var conversation = _conversationStorage.getConversationById(conversationId);

    if (conversation == null) {
      conversation = Conversation(
        id: conversationId,
        type: ConversationType.direct,
        participantIds: [userId1, userId2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _conversationStorage.saveConversation(conversation);
    }
  }

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
