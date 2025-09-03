import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' hide Fernet;
import 'package:fernet/fernet.dart' as f;
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';

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
    final box = await secureStorage.getSecretBox();
    if (!box.containsKey(_fernetSecretKey)) {
      final newKey = _generateBase64Key();
      await box.put(_fernetSecretKey, newKey);
      return newKey;
    }
    return box.get(_fernetSecretKey);
  }

  /// Generate a 32-byte random key as Base64 string
  String _generateBase64Key() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Export the current Fernet key for backup or sync
  Future<String> exportKey() async {
    final box = await secureStorage.getSecretBox();
    return box.get(_fernetSecretKey);
  }

  /// Import and override Fernet key (use with caution)
  Future<void> importKey(String base64Key) async {
    final box = await secureStorage.getSecretBox();
    await box.put(_fernetSecretKey, base64Key);
  }

  /// Rotate Fernet key (generates a new one)
  Future<void> rotateKey() async {
    final box = await secureStorage.getSecretBox();
    final newKey = _generateBase64Key();
    await box.put(_fernetSecretKey, newKey);
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
      return '❌ Fernet decryption failed: ${e.toString()}';
    }
  }

  /// Remove the Fernet key (e.g., on logout)
  Future<void> clearKey() async {
    final box = await secureStorage.getSecretBox();
    await box.delete(_fernetSecretKey);
  }
}
