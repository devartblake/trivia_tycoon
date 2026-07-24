import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synaptix/core/security/secure_channel_models.dart';
import 'package:synaptix/core/security/secure_channel_service.dart';
import 'package:synaptix/core/services/auth_api_client.dart';
import 'package:synaptix/core/services/auth_service.dart';
import 'package:synaptix/core/services/auth_token_store.dart';
import 'package:synaptix/core/services/device_id_service.dart';
import 'package:synaptix/core/services/storage/secure_secret_store.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';

class _InMemorySecretStore implements SecretStore {
  final Map<String, String> _data = {};
  @override
  Future<void> set(String key, String value) async => _data[key] = value;
  @override
  Future<String?> get(String key) async => _data[key];
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> clear() async => _data.clear();
}

class _FakeDeviceIdService extends DeviceIdService {
  _FakeDeviceIdService() : super(SecureStorage());
  @override
  Future<String> getOrCreate() async => 'device-x';
  @override
  String getDeviceType() => 'test';
}

/// Records revokeSession calls; every other member is unused by logout.
class _RecordingChannel implements SecureChannelService {
  int revokeCalls = 0;
  String? lastAccessToken;
  String? lastReason;

  @override
  Future<void> revokeSession({
    required String accessToken,
    String reason = 'logout',
  }) async {
    revokeCalls++;
    lastAccessToken = accessToken;
    lastReason = reason;
  }

  @override
  Future<SecureSession> startSession({required String accessToken}) =>
      throw UnimplementedError();
  @override
  Future<EncryptedPayload> encryptJson({
    required Map<String, dynamic> body,
    required List<int> keyBytes,
    required SecureRequestContext context,
  }) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> decryptJsonResponse({
    required SecureRequestContext context,
    required Map<String, dynamic> encryptedBody,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> persistSequenceIncrement(SecureSession session) =>
      throw UnimplementedError();
  @override
  Future<void> clearSession() async {}
  @override
  Future<SecureSession?> loadSession() async => null;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auth_logout_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('logout revokes the server-side secure session, then clears tokens',
      () async {
    final box = await Hive.openBox('auth_tokens_test');
    final store = AuthTokenStore(box, secretStore: _InMemorySecretStore());
    await store.initialize();
    await store.save(AuthSession(
      accessToken: 'access-tok',
      refreshToken: 'refresh-tok',
    ));

    // Backend logout responds 204; no real network.
    final api = AuthApiClient(
      MockClient((_) async => http.Response('', 204)),
      apiBaseUrl: 'https://api.test',
      deviceId: _FakeDeviceIdService(),
    );

    final channel = _RecordingChannel();
    final svc = BackendAuthService(
      deviceId: _FakeDeviceIdService(),
      tokenStore: store,
      api: api,
    );
    svc.attachSecureChannel(channel);

    await svc.logout();

    expect(channel.revokeCalls, 1);
    expect(channel.lastAccessToken, 'access-tok');
    expect(channel.lastReason, 'logout');
    expect(store.hasTokens(), isFalse);
  });
}
