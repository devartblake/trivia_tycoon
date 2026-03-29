import 'package:flutter/foundation.dart';
import '../../../game/models/conversation_models.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Simple storage service for conversations - no business logic
class ConversationStorageService {
  final Map<String, Conversation> _conversations = {};
  final Map<String, Set<String>> _userConversations = {}; // userId -> conversationIds

  // ============ CREATE ============

  Future<Conversation> saveConversation(Conversation conversation) async {
    _conversations[conversation.id] = conversation;

    // Index by participants
    for (final participantId in conversation.participantIds) {
      _userConversations[participantId] ??= {};
      _userConversations[participantId]!.add(conversation.id);
    }

    LogManager.debug('Conversation saved: ${conversation.id}');
    return conversation;
  }

  // ============ READ ============

  Conversation? getConversationById(String conversationId) {
    return _conversations[conversationId];
  }

  List<Conversation> getUserConversations(String userId) {
    final conversationIds = _userConversations[userId] ?? {};
    return conversationIds
        .map((id) => _conversations[id])
        .whereType<Conversation>()
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageTime ?? a.updatedAt;
        final bTime = b.lastMessageTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  List<Conversation> getDirectConversations(String userId) {
    return getUserConversations(userId)
        .where((conv) => conv.type == ConversationType.direct)
        .toList();
  }

  List<Conversation> getGroupConversations(String userId) {
    return getUserConversations(userId)
        .where((conv) => conv.type == ConversationType.group)
        .toList();
  }

  Conversation? findDirectConversation(String userId1, String userId2) {
    final conversations = getUserConversations(userId1);
    return conversations.firstWhere(
          (conv) =>
      conv.type == ConversationType.direct &&
          conv.participantIds.contains(userId2),
      orElse: () => null as Conversation,
    );
  }

  // ============ UPDATE ============

  Future<Conversation?> updateConversation(
      String conversationId,
      Conversation updatedConversation,
      ) async {
    if (!_conversations.containsKey(conversationId)) return null;

    _conversations[conversationId] = updatedConversation;
    LogManager.debug('Conversation updated: $conversationId');
    return updatedConversation;
  }

  Future<void> updateLastMessage(
      String conversationId,
      String messageId,
      DateTime messageTime,
      ) async {
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _conversations[conversationId] = conversation.copyWith(
        lastMessageId: messageId,
        lastMessageTime: messageTime,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> incrementUnreadCount(String conversationId) async {
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _conversations[conversationId] = conversation.copyWith(
        unreadCount: conversation.unreadCount + 1,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> resetUnreadCount(String conversationId) async {
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _conversations[conversationId] = conversation.copyWith(
        unreadCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // ============ DELETE ============

  Future<bool> deleteConversation(String conversationId) async {
    final conversation = _conversations.remove(conversationId);
    if (conversation != null) {
      // Remove from user indexes
      for (final participantId in conversation.participantIds) {
        _userConversations[participantId]?.remove(conversationId);
      }
      LogManager.debug('Conversation deleted: $conversationId');
      return true;
    }
    return false;
  }

  // ============ QUERY ============

  int getTotalUnreadCount(String userId) {
    return getUserConversations(userId)
        .fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  List<Conversation> getConversationsWithUnread(String userId) {
    return getUserConversations(userId)
        .where((conv) => conv.unreadCount > 0)
        .toList();
  }

  // ============ UTILITY ============

  void clear() {
    _conversations.clear();
    _userConversations.clear();
    LogManager.debug('Conversation storage cleared');
  }

  Map<String, dynamic> getStats() {
    return {
      'totalConversations': _conversations.length,
      'totalUsers': _userConversations.length,
      'conversationsPerUser': _userConversations.map(
            (key, value) => MapEntry(key, value.length),
      ),
    };
  }
}
