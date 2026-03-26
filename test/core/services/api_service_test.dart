import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

void main() {
  late Directory tempDir;
  late Box authBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('api_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    authBox = await Hive.openBox('auth_tokens');
  });

  tearDown(() async {
    await authBox.clear();
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('retries protected request after 401 when refresh succeeds', () async {
    await authBox.put('auth_access_token', 'expired-token');
    await authBox.put('auth_refresh_token', 'refresh-token');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var protectedAttempts = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/admin/users') {
            protectedAttempts++;
            if (protectedAttempts == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: {'message': 'expired'},
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'ok': true},
              ),
            );
            return;
          }

          if (options.path == '/admin/auth/refresh') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'new-access-token',
                  'refreshToken': 'new-refresh-token',
                  'expiresIn': 60,
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final service = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final response = await service.get('/admin/users');

    expect(response['ok'], isTrue);
    expect(authBox.get('auth_access_token'), 'new-access-token');
    expect(authBox.get('auth_refresh_token'), 'new-refresh-token');
    expect(protectedAttempts, 2);
  });

  test('falls back to /auth/refresh when /admin/auth/refresh is unavailable', () async {
    await authBox.put('auth_access_token', 'expired-token');
    await authBox.put('auth_refresh_token', 'refresh-token');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var refreshAttempts = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/admin/users') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'expired'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          if (options.path == '/admin/auth/refresh') {
            refreshAttempts++;
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'not found'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          if (options.path == '/auth/refresh') {
            refreshAttempts++;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'access_token': 'fallback-access-token',
                  'refresh_token': 'fallback-refresh-token',
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final service = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    await expectLater(
      () => service.get('/admin/users'),
      throwsA(isA<ApiRequestException>()),
    );

    expect(authBox.get('auth_access_token'), 'fallback-access-token');
    expect(authBox.get('auth_refresh_token'), 'fallback-refresh-token');
    expect(refreshAttempts, 2);
  });

  test('clears tokens when refresh endpoint returns unauthorized', () async {
    await authBox.put('auth_access_token', 'expired-token');
    await authBox.put('auth_refresh_token', 'invalid-refresh-token');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/admin/users') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'expired'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          if (options.path == '/admin/auth/refresh') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'refresh expired'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final service = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    await expectLater(
      () => service.get('/admin/users'),
      throwsA(isA<ApiRequestException>()),
    );

    expect(authBox.get('auth_access_token'), isNull);
    expect(authBox.get('auth_refresh_token'), isNull);
    expect(authBox.get('auth_expires_at_utc'), isNull);
  });

  test('parsePageEnvelope supports alternate envelope shapes', () {
    final service = ApiService(baseUrl: 'https://example.test', initializeCache: false);

    final envelope = service.parsePageEnvelope<String>(
      {
        'data': [
          {'id': 1, 'name': 'A'},
          {'id': 2, 'name': 'B'},
        ],
        'meta': {'page': '2', 'limit': '2', 'count': '6', 'pages': '3'},
      },
      (item) => item['name'].toString(),
    );

    expect(envelope.items, ['A', 'B']);
    expect(envelope.page, 2);
    expect(envelope.pageSize, 2);
    expect(envelope.total, 6);
    expect(envelope.totalPages, 3);
  });

  test('treats /profile as protected and retries after refresh', () async {
    await authBox.put('auth_access_token', 'expired-token');
    await authBox.put('auth_refresh_token', 'refresh-token');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var profileAttempts = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/profile') {
            profileAttempts++;

            if (profileAttempts == 1) {
              expect(options.headers['Authorization'], 'Bearer expired-token');
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: {'message': 'expired'},
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }

            expect(options.headers['Authorization'], 'Bearer profile-new-token');
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'ok': true},
              ),
            );
            return;
          }

          if (options.path == '/admin/auth/refresh') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'profile-new-token',
                  'refreshToken': 'profile-new-refresh',
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final service = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final response = await service.get('/profile');

    expect(response['ok'], isTrue);
    expect(profileAttempts, 2);
    expect(authBox.get('auth_access_token'), 'profile-new-token');
    expect(authBox.get('auth_refresh_token'), 'profile-new-refresh');
  });
}
