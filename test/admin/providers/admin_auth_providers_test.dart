import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/admin/providers/admin_auth_providers.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

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
