import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' hide Fernet;
import 'package:fernet/fernet.dart' as f;
import 'package:synaptix/core/services/storage/secure_storage.dart';

class FernetService {
  static const _fernetSecretKey = 'fernet_secret';

  final SecureStorage secureStorage;
  FernetService(this.secureStorage);

  static Future<FernetService> initialize(SecureStorage storage) async {
    // Load or generate Fernet key, validate, etc.
    final service = FernetService(storage);
    await service._ensureFernetSecret();
    return service;
  }

  /// Ensure Fernet key exists and return it
  Future<String> _ensureFernetSecret() async {
    final existing = await secureStorage.getSecret(_fernetSecretKey);
    if (existing == null || existing.isEmpty) {
      final newKey = _generateBase64Key();
      await secureStorage.setSecret(_fernetSecretKey, newKey);
      return newKey;
    }
    return existing;
  }

  /// Generate a 32-byte random key as Base64 string
  String _generateBase64Key() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Export the current Fernet key for backup or sync
  Future<String> exportKey() async {
    return await _ensureFernetSecret();
  }

  /// Import and override Fernet key (use with caution)
  Future<void> importKey(String base64Key) async {
    await secureStorage.setSecret(_fernetSecretKey, base64Key);
  }

  /// Rotate Fernet key (generates a new one)
  Future<void> rotateKey() async {
    final newKey = _generateBase64Key();
    await secureStorage.setSecret(_fernetSecretKey, newKey);
  }

  /// Encrypt string using current Fernet key
  Future<String> encrypt(String plainText) async {
    final keyStr = await _ensureFernetSecret();
    final key = Key.fromBase64(keyStr);
    final fernet = f.Fernet(key);
    final encrypted = fernet.encrypt(utf8.encode(plainText));
    return base64.encode(encrypted); // store as base64
  }

  /// Decrypt Fernet token
  Future<String> decrypt(String token) async {
    try {
      final keyStr = await _ensureFernetSecret();
      final key = Key.fromBase64(keyStr);
      final fernet = f.Fernet(key);
      final decrypted = fernet.decrypt(base64.decode(token));
      return utf8.decode(decrypted);
    } catch (e) {
      return 'Fernet decryption failed: ${e.toString()}';
    }
  }

  /// Remove the Fernet key (e.g., on logout)
  Future<void> clearKey() async {
    await secureStorage.removeSecret(_fernetSecretKey);
  }
}
