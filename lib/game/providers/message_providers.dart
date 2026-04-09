import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/repositories/message_repository.dart';
import '../../../core/services/storage/message_storage_service.dart';
import '../../core/services/social/challenge_message_bridge.dart';
import '../../core/services/social/conversation_storage_service.dart';
import '../../core/services/social/friend_message_bridge.dart';
import '../models/conversation_models.dart';
import '../models/message_models.dart';
import '../models/typing_status_model.dart';

// ============ Auth Identity ============

/// Provides the current user's ID from the Hive settings box (opened by AppInit).
/// Falls back to 'local-guest' when no user is authenticated.
final currentUserIdProvider = Provider<String>((ref) {
  if (Hive.isBoxOpen('settings')) {
    final id = Hive.box('settings').get('userId') as String?;
    if (id != null && id.isNotEmpty) return id;
  }
  return 'local-guest';
});

// ============ Storage Services ============

final messageStorageServiceProvider = Provider<MessageStorageService>((ref) {
  return MessageStorageService();
});

final conversationStorageServiceProvider = Provider<ConversationStorageService>((ref) {
  return ConversationStorageService();
});

// ============ Repository ============

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    messageStorage: ref.watch(messageStorageServiceProvider),
    conversationStorage: ref.watch(conversationStorageServiceProvider),
  );
});

// ============ Bridges ============

final challengeMessageBridgeProvider = Provider<ChallengeMessageBridge>((ref) {
  return ChallengeMessageBridge(
    messageStorage: ref.watch(messageStorageServiceProvider),
    conversationStorage: ref.watch(conversationStorageServiceProvider),
  );
});

final friendMessageBridgeProvider = Provider<FriendMessageBridge>((ref) {
  return FriendMessageBridge(
    messageStorage: ref.watch(messageStorageServiceProvider),
    conversationStorage: ref.watch(conversationStorageServiceProvider),
  );
});

// ============ Conversations ============

final userConversationsProvider = Provider.family<List<Conversation>, String>((ref, userId) {
  final repository = ref.watch(messageRepositoryProvider);
  // Trigger rebuild when repository changes
  ref.watch(messageRepositoryProvider);
  return repository.getUserConversations(userId);
});

final conversationProvider = Provider.family<Conversation?, String>((ref, conversationId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getConversation(conversationId);
});

final conversationMessagesProvider = Provider.family<List<Message>, String>((ref, conversationId) {
  final repository = ref.watch(messageRepositoryProvider);
  ref.watch(messageRepositoryProvider);
  return repository.getConversationMessages(conversationId);
});

// ============ Unread Count ============

final unreadMessagesProvider = Provider.family<int, String>((ref, userId) {
  final repository = ref.watch(messageRepositoryProvider);
  ref.watch(messageRepositoryProvider);
  return repository.getTotalUnreadCount(userId);
});

final conversationUnreadCountProvider = Provider.family<int, String>((ref, conversationId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getConversationUnreadCount(conversationId);
});

// ============ Streams (for real-time updates) ============

final conversationMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchConversationMessages(conversationId);
});

final userConversationsStreamProvider = StreamProvider.family<List<Conversation>, String>((ref, userId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchUserConversations(userId);
});

final unreadCountStreamProvider = StreamProvider.family<int, String>((ref, userId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchUnreadCount(userId);
});

// ============ Actions ============

// Send a text message
Future<void> sendTextMessage(
    WidgetRef ref, {
      required String conversationId,
      required String senderId,
      required String senderName,
      required String content,
    }) async {
  final repository = ref.read(messageRepositoryProvider);
  await repository.sendMessage(
    conversationId: conversationId,
    senderId: senderId,
    senderName: senderName,
    content: content,
    type: MessageType.text,
  );
}

// Mark conversation as read
Future<void> markConversationAsRead(WidgetRef ref, String conversationId) async {
  final repository = ref.read(messageRepositoryProvider);
  await repository.markConversationAsRead(conversationId);
}

// Delete conversation
Future<void> deleteConversation(WidgetRef ref, String conversationId) async {
  final repository = ref.read(messageRepositoryProvider);
  await repository.deleteConversation(conversationId);
}

// Find or create direct conversation
Conversation? findOrCreateDirectConversation(
    WidgetRef ref,
    String userId1,
    String userId2,
    ) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.findOrCreateDirectConversation(userId1, userId2);
}

// Typing Status
final conversationTypingStatusProvider = StreamProvider.family<List<TypingStatus>, String>(
      (ref, conversationId) {
    final repository = ref.watch(messageRepositoryProvider);
    return repository.watchTypingStatus(conversationId);
  },
);

// Action to send typing status
void sendTypingStatus(
    WidgetRef ref, {
      required String conversationId,
      required String userId,
      required String userName,
      required bool isTyping,
    }) {
  final repository = ref.read(messageRepositoryProvider);
  repository.sendTypingStatus(
    conversationId: conversationId,
    userId: userId,
    userName: userName,
    isTyping: isTyping,
  );
}