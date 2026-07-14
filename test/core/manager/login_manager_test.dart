import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/login_manager.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/core/services/auth_api_client.dart';
import 'package:synaptix/core/services/auth_service.dart';
import 'package:synaptix/core/services/auth_token_store.dart';
import 'package:synaptix/core/services/device_id_service.dart';
import 'package:synaptix/core/services/settings/onboarding_settings_service.dart';
import 'package:synaptix/core/services/settings/player_profile_service.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';
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
  final http.Response Function(http.Request) handler;

  _StubHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(resp.bodyBytes),
      resp.statusCode,
      headers: resp.headers,
    );
  }
}

/// Builds a 200 login/signup response with the given metadata fields merged in.
http.Response _loginResponse(Map<String, dynamic> extra) {
  final body = jsonEncode({
    'accessToken': 'access-token',
    'refreshToken': 'refresh-token',
    'userId': 'user-123',
    ...extra,
  });
  return http.Response(body, 200,
      headers: {'content-type': 'application/json'});
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

LoginManager _makeManager({
  required _StubHttpClient httpClient,
  required AuthTokenStore tokenStore,
  required SecureStorage secureStorage,
  required PlayerProfileService profileService,
  required OnboardingSettingsService onboardingService,
}) {
  final deviceId = _FakeDeviceIdService();
  final api = AuthApiClient(
    httpClient,
    apiBaseUrl: 'https://example.test',
    deviceId: deviceId,
  );
  final authService = BackendAuthService(
    deviceId: deviceId,
    tokenStore: tokenStore,
    api: api,
  );

  return LoginManager(
    authService: authService,
    tokenStore: tokenStore,
    deviceIdService: deviceId,
    onboardingService: onboardingService,
    secureStorage: secureStorage,
    profileService: profileService,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late AuthTokenStore tokenStore;
  late SecureStorage secureStorage;
  late PlayerProfileService profileService;
  late OnboardingSettingsService onboardingService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('login_manager_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('auth_tokens');
    tokenStore = AuthTokenStore(box);
    secureStorage = SecureStorage();
    profileService = PlayerProfileService();
    onboardingService = OnboardingSettingsService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // Role extraction
  // -------------------------------------------------------------------------

  group('LoginManager — role extraction from metadata', () {
    test('role from top-level "role" field', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({'role': 'admin'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('admin@example.test', 'password');
      expect(await manager.getUserRole(), 'admin');
    });

    test('role from top-level "roles" list (first element)', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({
              'roles': ['moderator', 'player']
            })),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('mod@example.test', 'password');
      expect(await manager.getUserRole(), 'moderator');
    });

    test('role defaults to player when no role metadata', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      expect(await manager.getUserRole(), 'player');
    });

    test('tier admin maps to admin role', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({'tier': 'admin'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('admin@example.test', 'password');
      expect(await manager.getUserRole(), 'admin');
    });

    test('tier moderator maps to moderator role', () async {
      final manager = _makeManager(
        httpClient:
            _StubHttpClient((_) => _loginResponse({'tier': 'moderator'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('mod@example.test', 'password');
      expect(await manager.getUserRole(), 'moderator');
    });

    test('isAdminUser returns true after admin login', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({'role': 'admin'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('admin@example.test', 'password');
      expect(await manager.isAdminUser(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Premium extraction
  // -------------------------------------------------------------------------

  group('LoginManager — premium status extraction', () {
    test('isPremium=true from top-level field', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({'isPremium': true})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('premium@example.test', 'password');
      expect(await manager.isPremiumUser(), isTrue);
    });

    test('subscriptionStatus active → premium', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient(
            (_) => _loginResponse({'subscriptionStatus': 'active'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('premium@example.test', 'password');
      expect(await manager.isPremiumUser(), isTrue);
    });

    test('tier premium → isPremium true', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({'tier': 'premium'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('premium@example.test', 'password');
      expect(await manager.isPremiumUser(), isTrue);
    });

    test('no premium metadata → isPremium false', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      expect(await manager.isPremiumUser(), isFalse);
    });

    test('isPremium=false explicitly → not premium', () async {
      final manager = _makeManager(
        httpClient:
            _StubHttpClient((_) => _loginResponse({'isPremium': false})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      expect(await manager.isPremiumUser(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getNextRoute routing logic
  // -------------------------------------------------------------------------

  group('LoginManager — getNextRoute routing', () {
    test('no session tokens → /login', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      // No login performed — tokenStore is empty
      expect(await manager.getNextRoute(), canonicalLoginRoute);
    });

    test('completed guest session routes to home', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await onboardingService.setHasCompletedOnboarding(true);

      expect(await manager.getNextRoute(), canonicalHomeRoute);
    });

    test('logged in + onboarding not complete → /onboarding', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      // login sets hasCompletedOnboarding=false for new sessions
      expect(await manager.getNextRoute(), canonicalOnboardingRoute);
    });

    test('logged in + onboarding complete → /home', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      await onboardingService.setHasCompletedOnboarding(true);

      expect(await manager.getNextRoute(), canonicalHomeRoute);
    });
  });

  // -------------------------------------------------------------------------
  // isLoggedIn
  // -------------------------------------------------------------------------

  group('LoginManager — isLoggedIn', () {
    test('false before any login', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      expect(await manager.isLoggedIn(), isFalse);
    });

    test('true after successful login', () async {
      final manager = _makeManager(
        httpClient: _StubHttpClient((_) => _loginResponse({})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      expect(await manager.isLoggedIn(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // userId saved
  // -------------------------------------------------------------------------

  group('LoginManager — userId persistence', () {
    test('userId from auth response saved to profileService', () async {
      final manager = _makeManager(
        httpClient:
            _StubHttpClient((_) => _loginResponse({'userId': 'uid-abc'})),
        tokenStore: tokenStore,
        secureStorage: secureStorage,
        profileService: profileService,
        onboardingService: onboardingService,
      );

      await manager.login('user@example.test', 'password');
      expect(await profileService.getUserId(), 'user-123');
    });
  });
}
