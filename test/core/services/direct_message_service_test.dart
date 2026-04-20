import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/messaging/direct_message_service.dart';

void main() {
  test('getConversations loads direct message summaries from backend',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [
                  {
                    'id': 'conv-1',
                    'type': 'direct',
                    'participantIds': ['player-1', 'player-2'],
                    'displayTitle': 'Sarah Chen',
                    'avatarUrl': 'https://example.test/avatar.png',
                    'lastMessagePreview': 'See you soon!',
                    'lastMessageTimestamp': '2026-04-20T13:00:00Z',
                    'unreadCount': 2,
                    'createdAtUtc': '2026-04-20T10:00:00Z',
                    'updatedAtUtc': '2026-04-20T13:00:00Z',
                  },
                ],
                'page': 1,
                'pageSize': 50,
                'total': 1,
                'totalPages': 1,
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );
    final service = DirectMessageService(apiService);

    final conversations = await service.getConversations();

    expect(capturedPath, '/messages/conversations');
    expect(conversations, hasLength(1));
    expect(conversations.first.displayTitle, 'Sarah Chen');
    expect(conversations.first.lastMessagePreview, 'See you soon!');
    expect(conversations.first.unreadCount, 2);
  });

  test('createDirectConversation posts target player id', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'conv-2',
                'type': 'direct',
                'participantIds': ['player-1', 'player-3'],
                'displayTitle': 'Mike Johnson',
                'createdAtUtc': '2026-04-20T14:00:00Z',
                'updatedAtUtc': '2026-04-20T14:00:00Z',
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );
    final service = DirectMessageService(apiService);

    final conversation = await service.createDirectConversation(
      targetPlayerId: 'player-3',
    );

    expect(capturedPath, '/messages/conversations/direct');
    expect(capturedBody, {'targetPlayerId': 'player-3'});
    expect(conversation.id, 'conv-2');
  });

  test('getConversationMessages loads paginated thread history', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [
                  {
                    'id': 'msg-1',
                    'conversationId': 'conv-1',
                    'senderId': 'player-2',
                    'senderDisplayName': 'Sarah Chen',
                    'content': 'Hey there',
                    'type': 'text',
                    'status': 'delivered',
                    'createdAtUtc': '2026-04-20T13:05:00Z',
                  },
                ],
                'page': 1,
                'pageSize': 100,
                'total': 1,
                'totalPages': 1,
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );
    final service = DirectMessageService(apiService);

    final messages = await service.getConversationMessages('conv-1');

    expect(capturedPath, '/messages/conversations/conv-1/messages');
    expect(messages, hasLength(1));
    expect(messages.first.senderName, 'Sarah Chen');
    expect(messages.first.content, 'Hey there');
  });

  test('sendMessage posts message body and optional client id', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'msg-2',
                'conversationId': 'conv-1',
                'senderId': 'player-1',
                'senderDisplayName': 'You',
                'content': 'Hello!',
                'type': 'text',
                'status': 'sent',
                'createdAtUtc': '2026-04-20T13:06:00Z',
              },
            ),
          );
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );
    final service = DirectMessageService(apiService);

    final message = await service.sendMessage(
      conversationId: 'conv-1',
      content: 'Hello!',
      clientMessageId: 'client-123',
    );

    expect(capturedPath, '/messages/conversations/conv-1/messages');
    expect(
        capturedBody, {'content': 'Hello!', 'clientMessageId': 'client-123'});
    expect(message.id, 'msg-2');
  });
}
