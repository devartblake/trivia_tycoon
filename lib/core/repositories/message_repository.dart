import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../game/models/conversation_models.dart';
import '../../game/models/message_models.dart';
import '../../game/models/typing_status_model.dart';
import '../services/social/conversation_storage_service.dart';
import '../services/storage/message_storage_service.dart';

/// Repository layer - coordinates storage services and provides unified API
/// Contains business logic but no UI concerns
class MessageRepository extends ChangeNotifier {
  final MessageStorageService _messageStorage;
  final ConversationStorageService _conversationStorage;

  // Streams for real-time updates
  final _messageStreamController = StreamController<Message>.broadcast();
  final _conversationStreamController =
      StreamController<Conversation>.broadcast();

  Stream<Message> get messageStream => _messageStreamController.stream;
  Stream<Conversation> get conversationStream =>
      _conversationStreamController.stream;

  MessageRepository({
    required MessageStorageService messageStorage,
    required ConversationStorageService conversationStorage,
  })  : _messageStorage = messageStorage,
        _conversationStorage = conversationStorage;

  @override
  void dispose() {
    _messageStreamController.close();
    _conversationStreamController.close();
    super.dispose();
  }

  // ============ SEND MESSAGE ============

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final message = Message(
      id: _generateMessageId(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _messageStorage.saveMessage(message);
    await _conversationStorage.updateLastMessage(
      conversationId,
      message.id,
      message.timestamp,
    );

    // Increment unread for other participants
    final conversation =
        _conversationStorage.getConversationById(conversationId);
    if (conversation != null) {
      await _conversationStorage.incrementUnreadCount(conversationId);
      _conversationStreamController.add(conversation);
    }

    _messageStreamController.add(message);
    notifyListeners();

    // Simulate delivery
    _simulateDelivery(message);

    return message;
  }

  Future<void> _simulateDelivery(Message message) async {
    await Future.delayed(const Duration(seconds: 1));
    await _messageStorage.updateMessageStatus(
        message.id, MessageStatus.delivered);
    notifyListeners();
  }

  // ============ GET MESSAGES ============

  List<Message> getConversationMessages(String conversationId) {
    return _messageStorage.getMessagesByConversation(conversationId);
  }

  Message? getMessage(String messageId) {
    return _messageStorage.getMessageById(messageId);
  }

  List<Message> getUnreadMessages(String conversationId) {
    return _messageStorage.getUnreadMessages(conversationId);
  }

  // ============ TYPING MESSAGE ============
  // Store typing statuses in memory
  final Map<String, List<TypingStatus>> _typingStatuses = {};
  final StreamController<Map<String, List<TypingStatus>>> _typingController =
      StreamController<Map<String, List<TypingStatus>>>.broadcast();

// Send typing status
  void sendTypingStatus({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    final statuses = _typingStatuses[conversationId] ?? [];

    // Remove old status for this user
    statuses.removeWhere((s) => s.userId == userId);

    // Add new status if typing
    if (isTyping) {
      statuses.add(TypingStatus(
        userId: userId,
        userName: userName,
        isTyping: true,
        timestamp: DateTime.now(),
      ));
    }

    _typingStatuses[conversationId] = statuses;
    _typingController.add(_typingStatuses);

    // Auto-clear after 5 seconds
    Timer(const Duration(seconds: 5), () {
      final currentStatuses = _typingStatuses[conversationId] ?? [];
      currentStatuses.removeWhere((s) =>
          s.userId == userId &&
          DateTime.now().difference(s.timestamp).inSeconds >= 5);
      _typingStatuses[conversationId] = currentStatuses;
      _typingController.add(_typingStatuses);
    });
  }

// Watch typing statuses for a conversation
  Stream<List<TypingStatus>> watchTypingStatus(String conversationId) {
    return _typingController.stream
        .map((statuses) => statuses[conversationId] ?? []);
  }

  List<TypingStatus> getTypingStatus(String conversationId) {
    return _typingStatuses[conversationId] ?? [];
  }

  // ============ GET CONVERSATIONS ============

  List<Conversation> getUserConversations(String userId) {
    return _conversationStorage.getUserConversations(userId);
  }

  List<Conversation> getDirectConversations(String userId) {
    return _conversationStorage.getDirectConversations(userId);
  }

  List<Conversation> getGroupConversations(String userId) {
    return _conversationStorage.getGroupConversations(userId);
  }

  Conversation? getConversation(String conversationId) {
    return _conversationStorage.getConversationById(conversationId);
  }

  Conversation? findOrCreateDirectConversation(String userId1, String userId2) {
    // Try to find existing conversation
    var conversation =
        _conversationStorage.findDirectConversation(userId1, userId2);

    // Create new conversation if none exists
    if (conversation == null) {
      final conversationId = _getConversationId(userId1, userId2);
      conversation = Conversation(
        id: conversationId,
        type: ConversationType.direct,
        participantIds: [userId1, userId2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _conversationStorage.saveConversation(conversation);
      _conversationStreamController.add(conversation); // Notify listeners
      notifyListeners();
    }

    return conversation;
  }

  // ============ MARK AS READ ============

  Future<void> markMessageAsRead(String messageId) async {
    await _messageStorage.markMessageAsRead(messageId);
    notifyListeners();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await _messageStorage.markConversationAsRead(conversationId);
    await _conversationStorage.resetUnreadCount(conversationId);

    final conversation =
        _conversationStorage.getConversationById(conversationId);
    if (conversation != null) {
      _conversationStreamController.add(conversation);
    }

    notifyListeners();
  }

  // ============ UNREAD COUNT ============

  int getConversationUnreadCount(String conversationId) {
    return _messageStorage.getUnreadCount(conversationId);
  }

  int getTotalUnreadCount(String userId) {
    return _conversationStorage.getTotalUnreadCount(userId);
  }

  List<Conversation> getConversationsWithUnread(String userId) {
    return _conversationStorage.getConversationsWithUnread(userId);
  }

  // ============ DELETE ============

  Future<void> deleteMessage(String messageId) async {
    await _messageStorage.deleteMessage(messageId);
    notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _messageStorage.deleteConversationMessages(conversationId);
    await _conversationStorage.deleteConversation(conversationId);
    notifyListeners();
  }

  // ============ STREAMS ============

  Stream<List<Message>> watchConversationMessages(String conversationId) {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return getConversationMessages(conversationId);
    }).distinct();
  }

  Stream<List<Conversation>> watchUserConversations(String userId) {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return getUserConversations(userId);
    }).distinct();
  }

  Stream<int> watchUnreadCount(String userId) {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return getTotalUnreadCount(userId);
    }).distinct();
  }

  // ============ HELPER METHODS ============

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // ============ STATS ============

  Map<String, dynamic> getStats(String userId) {
    final conversations = getUserConversations(userId);
    final totalMessages = conversations.fold<int>(
      0,
      (sum, conv) => sum + _messageStorage.getMessageCount(conv.id),
    );

    return {
      'totalConversations': conversations.length,
      'directConversations': getDirectConversations(userId).length,
      'groupConversations': getGroupConversations(userId).length,
      'totalMessages': totalMessages,
      'totalUnread': getTotalUnreadCount(userId),
    };
  }
}
