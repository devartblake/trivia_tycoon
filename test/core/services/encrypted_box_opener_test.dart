import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/storage/encrypted_box_opener.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';

/// In-memory keychain stand-in (overrides the secret accessors the opener uses).
class _FakeSecureStorage extends SecureStorage {
  final Map<String, String> _secrets = {};
  @override
  Future<void> setSecret(String key, String value) async =>
      _secrets[key] = value;
  @override
  Future<String?> getSecret(String key) async => _secrets[key];
  @override
  Future<void> removeSecret(String key) async => _secrets.remove(key);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('enc_box_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('migrates an existing plaintext auth_tokens box to encrypted and persists a key',
      () async {
    // Seed a plaintext box the way the legacy path would have.
    final plain = await Hive.openBox(EncryptedBoxOpener.authTokensBoxName);
    await plain.put('auth_access_token', 'legacy-access');
    await plain.put('auth_refresh_token', 'legacy-refresh');
    await plain.close();

    final storage = _FakeSecureStorage();
    final box = await EncryptedBoxOpener(storage).openAuthTokens();

    expect(box.get('auth_access_token'), 'legacy-access');
    expect(box.get('auth_refresh_token'), 'legacy-refresh');
    expect(await storage.getSecret('hive_auth_tokens_aes_key_v1'),
        isNotNull,
        reason: 'an encryption key must be stored in the keychain');

    await box.close();
  });

  test('reopens the encrypted box with the stored key across runs', () async {
    final storage = _FakeSecureStorage();

    final first = await EncryptedBoxOpener(storage).openAuthTokens();
    await first.put('auth_access_token', 'round-trip');
    await first.close();

    // A fresh opener with the same keychain must read it back (encrypted).
    final second = await EncryptedBoxOpener(storage).openAuthTokens();
    expect(second.get('auth_access_token'), 'round-trip');
    await second.close();
  });
}
