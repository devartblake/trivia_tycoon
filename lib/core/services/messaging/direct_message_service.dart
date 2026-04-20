import '../../../game/models/conversation_models.dart';
import '../../../game/models/message_models.dart';
import '../api_service.dart';

class DirectMessageService {
  final ApiService apiService;

  DirectMessageService(this.apiService);

  Future<List<Conversation>> getConversations({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await apiService.get(
      '/messages/conversations',
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      },
    );

    final envelope = apiService.parsePageEnvelope<Conversation>(
      response,
      Conversation.fromJson,
    );
    return envelope.items;
  }

  Future<Conversation> createDirectConversation({
    required String targetPlayerId,
  }) async {
    final response = await apiService.post(
      '/messages/conversations/direct',
      body: <String, dynamic>{
        'targetPlayerId': targetPlayerId,
      },
    );
    return Conversation.fromJson(response);
  }

  Future<List<Message>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await apiService.get(
      '/messages/conversations/$conversationId/messages',
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      },
    );

    final envelope = apiService.parsePageEnvelope<Message>(
      response,
      Message.fromJson,
    );
    return envelope.items;
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? clientMessageId,
  }) async {
    final response = await apiService.post(
      '/messages/conversations/$conversationId/messages',
      body: <String, dynamic>{
        'content': content,
        if (clientMessageId != null && clientMessageId.isNotEmpty)
          'clientMessageId': clientMessageId,
      },
    );

    return Message.fromJson(response);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await apiService.post(
      '/messages/conversations/$conversationId/read',
      body: const <String, dynamic>{},
    );
  }

  Future<int> getUnreadCount() async {
    final response = await apiService.get('/messages/unread-count');
    final count =
        response['unreadCount'] ?? response['count'] ?? response['total'];
    if (count is int) return count;
    if (count is String) return int.tryParse(count) ?? 0;
    return 0;
  }
}
