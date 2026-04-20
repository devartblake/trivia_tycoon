import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/auth_api_client.dart';
import 'package:trivia_tycoon/core/services/auth_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeDeviceIdService extends DeviceIdService {
  _FakeDeviceIdService() : super(SecureStorage());

  @override
  Future<String> getOrCreate() async => 'test-device-id';

  @override
  String getDeviceType() => 'test';

  @override
  Future<Map<String, String>> getDeviceIdentityPayload() async =>
      {'deviceId': 'test-device-id', 'deviceType': 'test'};
}

class _StubHttpClient extends http.BaseClient {
  // FIX: was `Map<String, http.Response> Function(http.Request)`.
  // The handler returns a single http.Response, not a Map.
  // This one wrong type annotation caused every lambda and every property
  // access on `resp` (bodyBytes, statusCode, headers) to fail — 9 errors total.
  final http.Response Function(http.Request) handler;

  _StubHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final baseReq = request as http.Request;
    final resp = handler(baseReq);
    return http.StreamedResponse(
      Stream.value(resp.bodyBytes),
      resp.statusCode,
      headers: resp.headers,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuthApiClient _makeApiClient(
  _StubHttpClient httpClient,
  _FakeDeviceIdService deviceId,
) =>
    AuthApiClient(
      httpClient,
      apiBaseUrl: 'https://example.test',
      deviceId: deviceId,
    );

BackendAuthService _makeAuthService({
  required AuthTokenStore store,
  required _StubHttpClient httpClient,
}) {
  final deviceId = _FakeDeviceIdService();
  return BackendAuthService(
    deviceId: deviceId,
    tokenStore: store,
    api: _makeApiClient(httpClient, deviceId),
  );
}

http.Response _jsonResp(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late Box authBox;
  late AuthTokenStore tokenStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auth_service_test');
    Hive.init(tempDir.path);
    authBox = await Hive.openBox('auth_tokens');
    tokenStore = AuthTokenStore(authBox);
  });

  tearDown(() async {
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
    await tempDir.delete(recursive: true);
  });

  group('AuthService.login', () {
    test('saves tokens on success', () async {
      final client = _StubHttpClient((_) => _jsonResp({
            'access_token': 'access-123',
            'refresh_token': 'refresh-456',
            'expires_in': 3600,
            'user_id': 'user-1',
          }));

      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      final session = await svc.login(email: 'a@b.com', password: 'pass');

      expect(session.accessToken, 'access-123');
      expect(session.refreshToken, 'refresh-456');
      expect(tokenStore.load().accessToken, 'access-123');
      expect(svc.isLoggedIn, isTrue);
    });

    test('throws on 401', () async {
      final client = _StubHttpClient(
          (_) => _jsonResp({'message': 'Invalid credentials'}, status: 401));

      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      await expectLater(
        () => svc.login(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
      expect(tokenStore.load().hasTokens, isFalse);
    });

    test('throws on server error', () async {
      final client =
          _StubHttpClient((_) => _jsonResp({'message': 'oops'}, status: 500));

      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      await expectLater(
        () => svc.login(email: 'a@b.com', password: 'pass'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService.refresh', () {
    test('stores refreshed tokens', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'old-access',
        refreshToken: 'valid-refresh',
      ));

      final client = _StubHttpClient((_) => _jsonResp({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          }));

      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      final session = await svc.refresh();

      expect(session.accessToken, 'new-access');
      expect(tokenStore.load().accessToken, 'new-access');
      expect(tokenStore.load().refreshToken, 'new-refresh');
    });

    test('throws when no refresh token present', () async {
      // Empty store → no refresh token
      final client = _StubHttpClient((_) => _jsonResp({}));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await expectLater(svc.refresh, throwsA(isA<Exception>()));
    });
  });

  group('AuthService.logout', () {
    test('clears tokens when backend succeeds', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
      ));

      final client = _StubHttpClient((_) => http.Response('', 200));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await svc.logout();

      expect(tokenStore.load().hasTokens, isFalse);
      expect(svc.isLoggedIn, isFalse);
    });

    test('clears tokens even when backend call fails (offline)', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
      ));

      final client =
          _StubHttpClient((_) => _jsonResp({'message': 'error'}, status: 500));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await svc.logout();

      expect(tokenStore.load().hasTokens, isFalse);
    });
  });

  group('AuthService.isLoggedIn', () {
    test('false when store is empty', () async {
      final client = _StubHttpClient((_) => http.Response('', 200));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      expect(svc.isLoggedIn, isFalse);
    });

    test('true after successful login', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
      ));

      final client = _StubHttpClient((_) => http.Response('', 200));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);
      expect(svc.isLoggedIn, isTrue);
    });
  });
}
