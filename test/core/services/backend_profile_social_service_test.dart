import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/social/backend_profile_social_service.dart';

void main() {
  test('searchUsers hits handle query and unwraps list payload', () async {
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
                    'id': 'user-123',
                    'handle': 'alexj',
                    'displayName': 'Alex Johnson',
                  },
                ],
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
    final service = BackendProfileSocialService(apiService);

    final results = await service.searchUsers('alexj');

    expect(capturedPath, '/users/search');
    expect(capturedQuery, {'handle': 'alexj'});
    expect(results, hasLength(1));
    expect(results.first['displayName'], 'Alex Johnson');
  });

  test('getCareerSummary requests the expected user route', () async {
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
              data: {'level': 42},
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
    final service = BackendProfileSocialService(apiService);

    final summary = await service.getCareerSummary('user-123');

    expect(capturedPath, '/users/user-123/career-summary');
    expect(summary['level'], 42);
  });

  test('saveLoadout puts the provided payload', () async {
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
              data: {'saved': true},
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
    final service = BackendProfileSocialService(apiService);

    final response = await service.saveLoadout({
      'username': 'alexj',
      'favoriteSubject': 'Science',
    });

    expect(capturedPath, '/users/me/preferences/loadout');
    expect(
      capturedBody,
      {
        'username': 'alexj',
        'favoriteSubject': 'Science',
      },
    );
    expect(response['saved'], isTrue);
  });

  test('removeFriend sends compatibility body to delete route', () async {
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
              data: {'removed': true},
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
    final service = BackendProfileSocialService(apiService);

    final response = await service.removeFriend('friend-456');

    expect(capturedPath, '/friends');
    expect(
      capturedBody,
      {
        'friendId': 'friend-456',
        'targetUserId': 'friend-456',
      },
    );
    expect(response['removed'], isTrue);
  });
}
