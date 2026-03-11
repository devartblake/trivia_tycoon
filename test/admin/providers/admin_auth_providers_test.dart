import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/admin/providers/admin_auth_providers.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

class _FakeDeviceIdService extends DeviceIdService {
  _FakeDeviceIdService() : super(SecureStorage());

  @override
  Future<Map<String, String>> getDeviceIdentityPayload() async {
    return {
      'deviceId': 'test-device',
      'deviceType': 'test',
      'device_id': 'test-device',
      'device_type': 'test',
    };
  }
}

void main() {
  late Directory tempDir;
  late Box authBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('admin_auth_provider_test');
    Hive.init(tempDir.path);
    authBox = await Hive.openBox('auth_tokens');
  });

  tearDown(() async {
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
    await tempDir.delete(recursive: true);
  });

  test('adminClaimsProvider retries /admin/auth/me after refresh fallback path', () async {
    final tokenStore = AuthTokenStore(authBox);
    await tokenStore.save(
      AuthSession(
        accessToken: 'expired-access-token',
        refreshToken: 'refresh-token',
      ),
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var meAttempts = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/admin/auth/me') {
            meAttempts++;
            if (meAttempts == 1) {
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
                data: {
                  'roles': ['admin'],
                  'permissions': ['notifications.read'],
                },
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
                  statusCode: 404,
                  data: {'message': 'not found'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          if (options.path == '/auth/refresh') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'access_token': 'fresh-access-token',
                  'refresh_token': 'fresh-refresh-token',
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(apiService),
        authTokenStoreProvider.overrideWithValue(tokenStore),
        deviceIdServiceProvider.overrideWithValue(_FakeDeviceIdService()),
      ],
    );
    addTearDown(container.dispose);

    final claims = await container.read(adminClaimsProvider.future);

    expect(claims['roles'], ['admin']);
    expect(meAttempts, 2);
    expect(tokenStore.load().accessToken, 'fresh-access-token');
    expect(tokenStore.load().refreshToken, 'fresh-refresh-token');
  });

  test('adminClaimsProvider uses token metadata fallback before local settings', () async {
    final tokenStore = AuthTokenStore(authBox);
    await tokenStore.save(
      AuthSession(
        accessToken: 'expired-access-token',
        refreshToken: 'refresh-token',
        metadata: {
          'roles': ['admin'],
          'permissions': ['users.read', 'users.write'],
        },
      ),
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/admin/auth/me') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: {'message': 'backend unavailable'},
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

    final apiService = ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    );

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(apiService),
        authTokenStoreProvider.overrideWithValue(tokenStore),
      ],
    );
    addTearDown(container.dispose);

    final claims = await container.read(adminClaimsProvider.future);
    expect(claims['roles'], ['admin']);
    expect(claims['permissions'], ['users.read', 'users.write']);

    final isAdmin = await container.read(unifiedIsAdminProvider.future);
    expect(isAdmin, isTrue);
  });
}
