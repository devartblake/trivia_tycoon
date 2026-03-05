import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

void main() {
  late Directory tempDir;
  late Box authBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('api_service_test');
    Hive.init(tempDir.path);
    authBox = await Hive.openBox('auth_tokens');
  });

  tearDown(() async {
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
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
}
