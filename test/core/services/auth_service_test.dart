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

class _ThrowingHttpClient extends http.BaseClient {
  final Object error;
  _ThrowingHttpClient(this.error);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(error);
}

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
}) =>
    _makeAuthServiceWithClient(store: store, httpClient: httpClient);

BackendAuthService _makeAuthServiceWithClient({
  required AuthTokenStore store,
  required http.Client httpClient,
}) {
  final deviceId = _FakeDeviceIdService();
  return BackendAuthService(
    deviceId: deviceId,
    tokenStore: store,
    api: AuthApiClient(httpClient,
        apiBaseUrl: 'https://example.test', deviceId: deviceId),
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

  // ---------------------------------------------------------------------------
  // Edge cases — offline / network failures
  // ---------------------------------------------------------------------------

  group('AuthService.login — offline', () {
    test('throws AuthApiException on SocketException (network down)', () async {
      final svc = _makeAuthServiceWithClient(
        store: tokenStore,
        httpClient: _ThrowingHttpClient(
          const SocketException('Network unreachable'),
        ),
      );
      await expectLater(
        () => svc.login(email: 'a@b.com', password: 'pass'),
        throwsA(isA<Exception>()),
      );
      expect(tokenStore.load().hasTokens, isFalse,
          reason: 'no tokens saved on network failure');
    });

    test('does not save partial tokens when login fails', () async {
      final client = _StubHttpClient(
          (_) => _jsonResp({'message': 'Unauthorized'}, status: 401));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      try {
        await svc.login(email: 'x@y.com', password: 'bad');
      } catch (_) {}

      expect(tokenStore.load().hasTokens, isFalse);
    });
  });

  group('AuthService.signup — edge cases', () {
    test('throws on 409 duplicate email', () async {
      final client = _StubHttpClient(
          (_) => _jsonResp({'message': 'Email already registered'}, status: 409));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await expectLater(
        () => svc.signup(email: 'dup@test.com', password: 'pass123'),
        throwsA(isA<Exception>()),
      );
      expect(tokenStore.load().hasTokens, isFalse);
    });

    test('throws on 400 validation error', () async {
      final client = _StubHttpClient(
          (_) => _jsonResp({'message': 'Password too short'}, status: 400));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await expectLater(
        () => svc.signup(email: 'new@test.com', password: 'x'),
        throwsA(isA<Exception>()),
      );
    });

    test('saves userId from signup response', () async {
      final client = _StubHttpClient((_) => _jsonResp({
            'access_token': 'acc',
            'refresh_token': 'ref',
            'user_id': 'player-789',
          }));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      final session = await svc.signup(
          email: 'new@test.com', password: 'pass123', username: 'newuser');

      expect(session.userId, 'player-789');
      expect(tokenStore.load().userId, 'player-789');
    });
  });

  group('AuthService.logout — 401 best-effort', () {
    test('clears tokens when backend returns 401 (expired token)', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'expired-access',
        refreshToken: 'expired-refresh',
      ));

      final client =
          _StubHttpClient((_) => _jsonResp({'message': 'Unauthorized'}, status: 401));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await svc.logout();

      expect(tokenStore.load().hasTokens, isFalse,
          reason: '401 from backend is best-effort — tokens still cleared');
      expect(svc.isLoggedIn, isFalse);
    });

    test('clears metadata on logout', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'user-1',
        metadata: {'role': 'admin'},
      ));

      final client = _StubHttpClient((_) => http.Response('', 200));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await svc.logout();

      final stored = tokenStore.load();
      expect(stored.metadata, isNull);
      expect(stored.userId, isNull);
    });
  });

  group('AuthService.refresh — concurrent calls', () {
    test('two simultaneous refresh calls both complete without error', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'old-access',
        refreshToken: 'valid-refresh',
      ));

      int callCount = 0;
      final client = _StubHttpClient((_) {
        callCount++;
        return _jsonResp({
          'access_token': 'new-access-$callCount',
          'refresh_token': 'new-refresh-$callCount',
          'expires_in': 3600,
        });
      });

      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      final results = await Future.wait([svc.refresh(), svc.refresh()]);

      expect(results[0].accessToken, isNotEmpty);
      expect(results[1].accessToken, isNotEmpty);
      expect(callCount, 2,
          reason: 'both concurrent requests must have reached the backend');
    });

    test('refresh throws when backend returns 401 (rotated token)', () async {
      await tokenStore.save(AuthSession(
        accessToken: 'old-access',
        refreshToken: 'rotated-refresh',
      ));

      final client =
          _StubHttpClient((_) => _jsonResp({'message': 'Token rotated'}, status: 401));
      final svc = _makeAuthService(store: tokenStore, httpClient: client);

      await expectLater(svc.refresh, throwsA(isA<Exception>()));
    });
  });

  // ---------------------------------------------------------------------------
  // AuthSession model edge cases
  // ---------------------------------------------------------------------------

  group('AuthSession — expiry detection', () {
    test('isExpired returns false when no expiry set', () {
      final s = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(s.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final s = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      expect(s.isExpired, isTrue);
    });

    test('isExpired returns false for future expiry', () {
      final s = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(s.isExpired, isFalse);
    });
  });

  group('AuthSession — metadata extraction', () {
    test('role returns value from metadata', () {
      final s = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'role': 'admin'},
      );
      expect(s.role, 'admin');
    });

    test('isPremium true when metadata isPremium=true', () {
      final s = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'isPremium': true},
      );
      expect(s.isPremium, isTrue);
    });

    test('isPremium false when no metadata', () {
      final s = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(s.isPremium, isFalse);
    });

    test('isPremium true from subscriptionStatus=active', () {
      final s = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'subscriptionStatus': 'active'},
      );
      expect(s.isPremium, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // AuthApiClient — OAuth / social login URL
  // ---------------------------------------------------------------------------

  group('AuthApiClient.getOAuthUrl — social login', () {
    test('returns URL string on success', () async {
      final client = _StubHttpClient((_) => _jsonResp(
          {'url': 'https://accounts.google.com/o/oauth2/auth?client_id=x'}));

      final deviceId = _FakeDeviceIdService();
      final api = AuthApiClient(client,
          apiBaseUrl: 'https://api.test', deviceId: deviceId);

      final url = await api.getOAuthUrl('google');
      expect(url, contains('accounts.google.com'));
    });

    test('returns null on empty response body', () async {
      final client = _StubHttpClient((_) => http.Response('{}', 200,
          headers: {'content-type': 'application/json'}));

      final deviceId = _FakeDeviceIdService();
      final api = AuthApiClient(client,
          apiBaseUrl: 'https://api.test', deviceId: deviceId);

      final url = await api.getOAuthUrl('google');
      expect(url, isNull);
    });

    test('throws on non-2xx response', () async {
      final client = _StubHttpClient(
          (_) => _jsonResp({'message': 'Provider not configured'}, status: 404));

      final deviceId = _FakeDeviceIdService();
      final api = AuthApiClient(client,
          apiBaseUrl: 'https://api.test', deviceId: deviceId);

      await expectLater(
        () => api.getOAuthUrl('unknown-provider'),
        throwsA(isA<AuthApiException>()),
      );
    });
  });
}
