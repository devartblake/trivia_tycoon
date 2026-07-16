import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/api_service.dart';
import 'package:synaptix/core/services/social/backend_profile_social_service.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

ApiService _fakeApi<T>({
  required T response,
  String? capturePath,
  void Function(String path, dynamic body, Map<String, dynamic> query)?
      onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(
          options.path,
          options.data,
          Map<String, dynamic>.from(options.queryParameters),
        );
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: response,
        ));
      },
    ),
  );
  return ApiService(
      baseUrl: 'https://example.test', dio: dio, initializeCache: false);
}

Map<String, dynamic> _friendItem({
  String id = 'friend-1',
  bool isOnline = false,
}) =>
    {
      'friendPlayerId': id,
      'displayName': 'Test User',
      'username': 'testuser',
      'avatarUrl': null,
      'isOnline': isOnline,
    };

Map<String, dynamic> _requestItem({
  String requestId = 'req-1',
  String fromPlayerId = 'user-a',
  String toPlayerId = 'user-b',
  String status = 'Pending',
}) =>
    {
      'requestId': requestId,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'status': status,
    };

Map<String, dynamic> _pageResponse(List<Map<String, dynamic>> items) => {
      'items': items,
      'page': 1,
      'pageSize': 50,
      'total': items.length,
      'totalPages': 1,
    };

void main() {
  // ---------------------------------------------------------------------------
  // Existing coverage
  // ---------------------------------------------------------------------------

  test('searchUsers hits handle query and unwraps list payload', () async {
    String? path;
    Map<String, dynamic>? query;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: {
          'items': [
            {
              'id': 'user-123',
              'handle': 'alexj',
              'displayName': 'Alex Johnson'
            },
          ],
        },
        onRequest: (p, _, q) {
          path = p;
          query = q;
        },
      ),
    );

    final results = await service.searchUsers('alexj');

    expect(path, '/users/search');
    expect(query, {'handle': 'alexj'});
    expect(results, hasLength(1));
    expect(results.first['displayName'], 'Alex Johnson');
  });

  test('getCareerSummary requests the expected user route', () async {
    String? path;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: {'level': 42},
        onRequest: (p, _, __) => path = p,
      ),
    );

    final summary = await service.getCareerSummary('user-123');
    expect(path, '/users/user-123/career-summary');
    expect(summary['level'], 42);
  });

  test('saveLoadout puts the provided payload', () async {
    String? path;
    dynamic body;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: {'saved': true},
        onRequest: (p, b, _) {
          path = p;
          body = b;
        },
      ),
    );

    await service
        .saveLoadout({'username': 'alexj', 'favoriteSubject': 'Science'});
    expect(path, '/users/me/preferences/loadout');
    expect((body as Map)['username'], 'alexj');
  });

  test('removeFriend sends compatibility body to delete route', () async {
    String? path;
    dynamic body;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: {'removed': true},
        onRequest: (p, b, _) {
          path = p;
          body = b;
        },
      ),
    );

    await service.removeFriend('friend-456');
    expect(path, '/friends');
    expect((body as Map)['friendId'], 'friend-456');
    expect((body as Map)['targetUserId'], 'friend-456');
  });

  // ---------------------------------------------------------------------------
  // Friends list + requests
  // ---------------------------------------------------------------------------

  test('getFriends parses paginated FriendListItemDto list', () async {
    final service = BackendProfileSocialService(
      _fakeApi(
          response:
              _pageResponse([_friendItem(id: 'f1'), _friendItem(id: 'f2')])),
    );

    final result = await service.getFriends();
    expect(result.items, hasLength(2));
    expect(result.total, 2);
    expect(result.items.first.friendPlayerId, 'f1');
  });

  test('getIncomingFriendRequests parses isPending getter', () async {
    final service = BackendProfileSocialService(
      _fakeApi(response: _pageResponse([_requestItem(status: 'Pending')])),
    );

    final result = await service.getIncomingFriendRequests();
    expect(result.items.first.isPending, isTrue);
    expect(result.items.first.status, 'Pending');
  });

  test('getSentFriendRequests parses null respondedAtUtc', () async {
    final service = BackendProfileSocialService(
      _fakeApi(response: _pageResponse([_requestItem()])),
    );

    final result = await service.getSentFriendRequests();
    expect(result.items.first.respondedAtUtc, isNull);
  });

  test('sendFriendRequest POSTs targetUserId to correct path', () async {
    String? path;
    dynamic body;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: _requestItem(toPlayerId: 'target-99'),
        onRequest: (p, b, _) {
          path = p;
          body = b;
        },
      ),
    );

    final dto = await service.sendFriendRequest('target-99');
    expect(path, '/users/me/friends/request');
    expect((body as Map)['targetUserId'], 'target-99');
    expect(dto.toPlayerId, 'target-99');
  });

  test('acceptFriendRequest POSTs to correct path', () async {
    String? path;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: _requestItem(requestId: 'req-77', status: 'Accepted'),
        onRequest: (p, _, __) => path = p,
      ),
    );

    final dto = await service.acceptFriendRequest('req-77');
    expect(path, '/users/me/friends/requests/req-77/accept');
    expect(dto.requestId, 'req-77');
  });

  test('declineFriendRequest POSTs to correct path', () async {
    String? path;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: _requestItem(requestId: 'req-55', status: 'Declined'),
        onRequest: (p, _, __) => path = p,
      ),
    );

    await service.declineFriendRequest('req-55');
    expect(path, '/users/me/friends/requests/req-55/decline');
  });

  test('cancelFriendRequest DELETEs the correct path', () async {
    String? path;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: <String, dynamic>{},
        onRequest: (p, _, __) => path = p,
      ),
    );

    await service.cancelFriendRequest('req-33');
    expect(path, '/users/me/friends/requests/req-33');
  });

  test('getFriendSuggestions parses hasMutualFriends getter', () async {
    final service = BackendProfileSocialService(
      _fakeApi(response: [
        {
          'id': 's1',
          'displayName': 'Sugg',
          'mutualFriendCount': 3,
          'reason': 'mutual'
        },
      ]),
    );

    final suggestions = await service.getFriendSuggestions();
    expect(suggestions.first.hasMutualFriends, isTrue);
    expect(suggestions.first.mutualFriendCount, 3);
  });

  test('blockUser POSTs targetUserId to /users/me/block', () async {
    String? path;
    dynamic body;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: <String, dynamic>{},
        onRequest: (p, b, _) {
          path = p;
          body = b;
        },
      ),
    );

    await service.blockUser('bad-user');
    expect(path, '/users/me/block');
    expect((body as Map)['targetUserId'], 'bad-user');
  });

  test('unblockUser DELETEs correct path', () async {
    String? path;
    final service = BackendProfileSocialService(
      _fakeApi(
        response: <String, dynamic>{},
        onRequest: (p, _, __) => path = p,
      ),
    );

    await service.unblockUser('bad-user');
    expect(path, '/users/me/block/bad-user');
  });

  // ---------------------------------------------------------------------------
  // Local preference methods (in-memory)
  // ---------------------------------------------------------------------------

  test('getFriendshipStatus returns friends when in friends list', () async {
    // getFriends, getSentFriendRequests, getIncomingFriendRequests all called
    // We stub them via multiple sequential responses using a counter.
    int call = 0;
    final responses = [
      _pageResponse([_friendItem(id: 'target-abc')]), // getFriends
    ];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: responses[call++ % responses.length],
        ));
      },
    ));
    final service = BackendProfileSocialService(
      ApiService(
          baseUrl: 'https://example.test', dio: dio, initializeCache: false),
    );

    final status = await service.getFriendshipStatus('target-abc');
    expect(status, FriendshipStatus.friends);
  });

  test('getOnlineFriends filters by isOnline == true', () async {
    final service = BackendProfileSocialService(
      _fakeApi(
          response: _pageResponse([
        _friendItem(id: 'online-1', isOnline: true),
        _friendItem(id: 'offline-1', isOnline: false),
        _friendItem(id: 'online-2', isOnline: true),
      ])),
    );

    final online = await service.getOnlineFriends();
    expect(online, hasLength(2));
    expect(online.every((f) => f.isOnline), isTrue);
  });

  test('toggleFavourite and isFavourite round-trip correctly', () {
    final service = BackendProfileSocialService(
      _fakeApi(response: <String, dynamic>{}),
    );

    expect(service.isFavourite('u1'), isFalse);
    service.toggleFavourite('u1');
    expect(service.isFavourite('u1'), isTrue);
    service.toggleFavourite('u1');
    expect(service.isFavourite('u1'), isFalse);
  });

  test('getFavouriteFriendIds returns only favourited ids', () {
    final service = BackendProfileSocialService(
      _fakeApi(response: <String, dynamic>{}),
    );

    service.toggleFavourite('u1');
    service.toggleFavourite('u2');
    final ids = service.getFavouriteFriendIds();
    expect(ids, containsAll(['u1', 'u2']));
    expect(ids, hasLength(2));
  });

  test('setFriendNickname and getFriendNickname round-trip', () {
    final service = BackendProfileSocialService(
      _fakeApi(response: <String, dynamic>{}),
    );

    service.setFriendNickname('u1', 'Buddy');
    expect(service.getFriendNickname('u1'), 'Buddy');
    expect(service.getFriendNickname('u2'), isNull);
  });
}
