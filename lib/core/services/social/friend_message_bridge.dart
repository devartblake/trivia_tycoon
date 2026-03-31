import 'package:flutter/foundation.dart';
import '../../../game/models/conversation_models.dart';
import '../../../game/models/message_models.dart';
import '../storage/message_storage_service.dart';
import 'conversation_storage_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Lightweight bridge between Friend system and Message system
class FriendMessageBridge {
  final MessageStorageService _messageStorage;
  final ConversationStorageService _conversationStorage;

  FriendMessageBridge({
    required MessageStorageService messageStorage,
    required ConversationStorageService conversationStorage,
  })  : _messageStorage = messageStorage,
        _conversationStorage = conversationStorage;

  /// Called when a friend request is sent
  Future<void> onFriendRequestSent({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String requestId,
    String? message,
  }) async {
    final conversationId = _getConversationId(senderId, recipientId);

    await _ensureConversationExists(conversationId, senderId, recipientId);

    final friendRequestMessage = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: message ?? 'Sent you a friend request',
      type: MessageType.friendRequest,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      metadata: {
        'requestId': requestId,
      },
    );

    await _messageStorage.saveMessage(friendRequestMessage);
    await _conversationStorage.updateLastMessage(
      conversationId,
      friendRequestMessage.id,
      friendRequestMessage.timestamp,
    );

    LogManager.debug('Friend request message created');
  }

  /// Called when a friend request is accepted
  Future<void> onFriendRequestAccepted({
    required String accepterId,
    required String accepterName,
    required String requesterId,
  }) async {
    final conversationId = _getConversationId(accepterId, requesterId);

    final message = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: accepterId,
      senderName: accepterName,
      content: 'You are now friends!',
      type: MessageType.friendAccepted,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    await _messageStorage.saveMessage(message);
    await _conversationStorage.updateLastMessage(
      conversationId,
      message.id,
      message.timestamp,
    );
  }

  // ============ Helper Methods ============

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
