import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/services/messaging/direct_message_service.dart';
import '../../core/repositories/message_repository.dart';
import '../../core/services/storage/message_storage_service.dart';
import '../../core/services/social/challenge_message_bridge.dart';
import '../../core/services/social/conversation_storage_service.dart';
import '../../core/services/social/friend_message_bridge.dart';
import '../../core/dto/hub_event_dto.dart';
import '../models/conversation_models.dart';
import '../models/message_models.dart';
import '../models/typing_status_model.dart';
import 'core_providers.dart';
import 'hub_providers.dart';

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

final conversationStorageServiceProvider =
    Provider<ConversationStorageService>((ref) {
  return ConversationStorageService();
});

// ============ Repository ============

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    messageStorage: ref.watch(messageStorageServiceProvider),
    conversationStorage: ref.watch(conversationStorageServiceProvider),
  );
});

final directMessageServiceProvider = Provider<DirectMessageService>((ref) {
  return DirectMessageService(ref.watch(apiServiceProvider));
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

final userConversationsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, userId) async {
  final service = ref.watch(directMessageServiceProvider);
  return service.getConversations();
});

final conversationProvider =
    Provider.family<Conversation?, String>((ref, conversationId) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final conversations = ref.watch(userConversationsProvider(currentUserId));
  return conversations.maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.id == conversationId) return item;
      }
      return null;
    },
    orElse: () => null,
  );
});

final conversationMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final service = ref.watch(directMessageServiceProvider);
  return service.getConversationMessages(conversationId);
});

// ============ Unread Count ============

final unreadMessagesProvider = Provider.family<int, String>((ref, userId) {
  final unreadCountAsync = ref.watch(directMessageUnreadCountProvider(userId));
  return unreadCountAsync.maybeWhen(
    data: (value) => value,
    orElse: () => 0,
  );
});

final directMessageUnreadCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(directMessageServiceProvider);
  return service.getUnreadCount();
});

final conversationUnreadCountProvider =
    Provider.family<int, String>((ref, conversationId) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final conversations = ref.watch(userConversationsProvider(currentUserId));
  return conversations.maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.id == conversationId) return item.unreadCount;
      }
      return 0;
    },
    orElse: () => 0,
  );
});

// ============ Real-time sync (WebSocket push → REST invalidation) ============

/// Watches the SignalR `DirectMessagesUpdated` push event and invalidates
/// conversation/unread providers so the UI reflects new messages immediately.
/// Must be watched by any screen that shows conversation lists or badges.
final messageRealtimeSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<DirectMessagesUpdatedDto>>(
      directMessagesUpdatedStreamProvider, (_, next) {
    next.whenData((event) {
      final userId = ref.read(currentUserIdProvider);
      ref.invalidate(userConversationsProvider(userId));
      ref.invalidate(directMessageUnreadCountProvider(userId));
      if (event.conversationId.isNotEmpty) {
        ref.invalidate(conversationMessagesProvider(event.conversationId));
      }
    });
  });
});

// ============ Streams (for real-time updates) ============

final conversationMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchConversationMessages(conversationId);
});

final userConversationsStreamProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchUserConversations(userId);
});

final unreadCountStreamProvider =
    StreamProvider.family<int, String>((ref, userId) {
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
  final service = ref.read(directMessageServiceProvider);
  await service.sendMessage(
    conversationId: conversationId,
    content: content,
  );
  ref.invalidate(conversationMessagesProvider(conversationId));
  ref.invalidate(userConversationsProvider(senderId));
  ref.invalidate(directMessageUnreadCountProvider(senderId));
}

// Mark conversation as read
Future<void> markConversationAsRead(
    WidgetRef ref, String conversationId) async {
  final service = ref.read(directMessageServiceProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  await service.markConversationAsRead(conversationId);
  ref.invalidate(conversationMessagesProvider(conversationId));
  ref.invalidate(userConversationsProvider(currentUserId));
  ref.invalidate(directMessageUnreadCountProvider(currentUserId));
}

// Delete conversation
Future<void> deleteConversation(WidgetRef ref, String conversationId) async {
  final repository = ref.read(messageRepositoryProvider);
  await repository.deleteConversation(conversationId);
}

// Find or create direct conversation
Future<Conversation?> findOrCreateDirectConversation(
  WidgetRef ref,
  String userId1,
  String userId2,
) {
  final service = ref.read(directMessageServiceProvider);
  return service.createDirectConversation(targetPlayerId: userId2);
}

// Typing Status
final conversationTypingStatusProvider =
    StreamProvider.family<List<TypingStatus>, String>(
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
