import 'package:flutter/foundation.dart';
import '../../../game/models/message_models.dart';

/// Simple storage service for messages - no business logic
/// Just CRUD operations
class MessageStorageService {
  // In-memory storage (replace with database later)
  final Map<String, Message> _messages = {};
  final Map<String, List<String>> _conversationMessages = {}; // conversationId -> messageIds

  // ============ CREATE ============

  Future<Message> saveMessage(Message message) async {
    _messages[message.id] = message;

    // Index by conversation
    _conversationMessages[message.conversationId] ??= [];
    if (!_conversationMessages[message.conversationId]!.contains(message.id)) {
      _conversationMessages[message.conversationId]!.add(message.id);
    }

    debugPrint('Message saved: ${message.id}');
    return message;
  }

  Future<List<Message>> saveMessages(List<Message> messages) async {
    for (final message in messages) {
      await saveMessage(message);
    }
    return messages;
  }

  // ============ READ ============

  Message? getMessageById(String messageId) {
    return _messages[messageId];
  }

  List<Message> getMessagesByConversation(String conversationId) {
    final messageIds = _conversationMessages[conversationId] ?? [];
    return messageIds
        .map((id) => _messages[id])
        .whereType<Message>()
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<Message> getUnreadMessages(String conversationId) {
    return getMessagesByConversation(conversationId)
        .where((msg) => !msg.isRead)
        .toList();
  }

  List<Message> getMessagesByType(String conversationId, MessageType type) {
    return getMessagesByConversation(conversationId)
        .where((msg) => msg.type == type)
        .toList();
  }

  // ============ UPDATE ============

  Future<Message?> updateMessage(String messageId, Message updatedMessage) async {
    if (!_messages.containsKey(messageId)) return null;

    _messages[messageId] = updatedMessage;
    debugPrint('Message updated: $messageId');
    return updatedMessage;
  }

  Future<void> markMessageAsRead(String messageId) async {
    final message = _messages[messageId];
    if (message != null && !message.isRead) {
      _messages[messageId] = message.copyWith(
        isRead: true,
        status: MessageStatus.read,
      );
    }
  }

  Future<void> markMessagesAsRead(List<String> messageIds) async {
    for (final id in messageIds) {
      await markMessageAsRead(id);
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final messages = getMessagesByConversation(conversationId);
    for (final message in messages) {
      if (!message.isRead) {
        await markMessageAsRead(message.id);
      }
    }
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final message = _messages[messageId];
    if (message != null) {
      _messages[messageId] = message.copyWith(status: status);
    }
  }

  // ============ DELETE ============

  Future<bool> deleteMessage(String messageId) async {
    final message = _messages.remove(messageId);
    if (message != null) {
      // Remove from conversation index
      _conversationMessages[message.conversationId]?.remove(messageId);
      debugPrint('Message deleted: $messageId');
      return true;
    }
    return false;
  }

  Future<void> deleteMessages(List<String> messageIds) async {
    for (final id in messageIds) {
      await deleteMessage(id);
    }
  }

  Future<void> deleteConversationMessages(String conversationId) async {
    final messageIds = List<String>.from(_conversationMessages[conversationId] ?? []);
    await deleteMessages(messageIds);
    _conversationMessages.remove(conversationId);
  }

  // ============ QUERY ============

  int getMessageCount(String conversationId) {
    return _conversationMessages[conversationId]?.length ?? 0;
  }

  int getUnreadCount(String conversationId) {
    return getUnreadMessages(conversationId).length;
  }

  Message? getLastMessage(String conversationId) {
    final messages = getMessagesByConversation(conversationId);
    return messages.isEmpty ? null : messages.last;
  }

  // ============ UTILITY ============

  void clear() {
    _messages.clear();
    _conversationMessages.clear();
    debugPrint('Message storage cleared');
  }

  Map<String, dynamic> getStats() {
    return {
      'totalMessages': _messages.length,
      'totalConversations': _conversationMessages.length,
      'messagesPerConversation': _conversationMessages.map(
            (key, value) => MapEntry(key, value.length),
      ),
    };
  }
}
