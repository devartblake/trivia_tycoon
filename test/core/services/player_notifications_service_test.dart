import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/notifications/player_inbox_item.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/notifications/player_notifications_service.dart';

void main() {
  test('getInbox loads paginated inbox items from backend contract', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    late String capturedPath;
    Map<String, dynamic>? capturedQuery;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedQuery = Map<String, dynamic>.from(options.queryParameters);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [
                  {
                    'id': 'notif-1',
                    'type': 'friend',
                    'title': 'Friend request',
                    'body': 'Sarah sent you a friend request.',
                    'createdAtUtc': '2026-04-20T12:00:00Z',
                    'unread': true,
                    'actionRoute': '/friends',
                    'payload': {'friendId': 'player-2'},
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
    final service = PlayerNotificationsService(apiService);

    final inbox = await service.getInbox(unreadOnly: true, type: 'friend');

    expect(capturedPath, '/notifications/inbox');
    expect(capturedQuery, {
      'page': 1,
      'pageSize': 50,
      'unreadOnly': true,
      'type': 'friend',
    });
    expect(inbox, hasLength(1));
    expect(inbox.first.type, InboxType.friend);
    expect(inbox.first.actionRoute, '/friends');
  });

  test('getUnreadCount reads backend unread count endpoint', () async {
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
              data: {'unreadCount': 7},
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
    final service = PlayerNotificationsService(apiService);

    final count = await service.getUnreadCount();

    expect(capturedPath, '/notifications/unread-count');
    expect(count, 7);
  });

  test('markAsRead posts expected route', () async {
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
              data: {'success': true},
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
    final service = PlayerNotificationsService(apiService);

    await service.markAsRead('notif-1');

    expect(capturedPath, '/notifications/notif-1/read');
    expect(capturedBody, isEmpty);
  });

  test('dismiss issues delete against notification route', () async {
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
              data: {'dismissed': true},
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
    final service = PlayerNotificationsService(apiService);

    await service.dismiss('notif-1');

    expect(capturedPath, '/notifications/notif-1');
  });
}
