import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';

/// Opens the `auth_tokens` box encrypted at rest with a per-install AES-256 key
/// held in the OS keychain (via [SecureStorage.getSecret]/[setSecret]).
///
/// The box carries bearer/refresh tokens (legacy `ApiService` path) and session
/// metadata; encrypting it means a rooted-device or backup-extraction attacker
/// can't read tokens straight off disk. First run migrates any existing
/// plaintext box in place, then deletes the plaintext file.
///
/// Fails safe: if key storage or encryption is unavailable, falls back to the
/// previous plaintext box so app startup is never blocked by this hardening.
class EncryptedBoxOpener {
  EncryptedBoxOpener(this._secureStorage);

  final SecureStorage _secureStorage;

  static const authTokensBoxName = 'auth_tokens';
  static const _authTokensKeyName = 'hive_auth_tokens_aes_key_v1';

  /// Returns the opened `auth_tokens` box, encrypted when possible.
  Future<Box> openAuthTokens() =>
      _openEncrypted(authTokensBoxName, _authTokensKeyName);

  Future<Box> _openEncrypted(String boxName, String keyName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);

    try {
      final existingKeyB64 = await _secureStorage.getSecret(keyName);
      if (existingKeyB64 != null && existingKeyB64.isNotEmpty) {
        final key = base64Decode(existingKeyB64);
        return await Hive.openBox(boxName,
            encryptionCipher: HiveAesCipher(key));
      }

      // First run with encryption enabled: drain any plaintext box, then
      // reopen the same box name encrypted.
      Map<dynamic, dynamic> carried = const {};
      if (await Hive.boxExists(boxName)) {
        final plain = await Hive.openBox(boxName);
        carried = Map<dynamic, dynamic>.from(plain.toMap());
        await plain.deleteFromDisk();
      }

      final newKey = Hive.generateSecureKey();
      await _secureStorage.setSecret(keyName, base64Encode(newKey));

      final box = await Hive.openBox(boxName,
          encryptionCipher: HiveAesCipher(newKey));
      if (carried.isNotEmpty) {
        await box.putAll(carried);
      }
      LogManager.debug(
          '[EncryptedBoxOpener] Opened "$boxName" encrypted (migrated ${carried.length} entr${carried.length == 1 ? 'y' : 'ies'}).');
      return box;
    } catch (e) {
      LogManager.debug(
          '[EncryptedBoxOpener] Encryption unavailable for "$boxName" ($e); falling back to plaintext box.');
      if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
      return Hive.openBox(boxName);
    }
  }
}
