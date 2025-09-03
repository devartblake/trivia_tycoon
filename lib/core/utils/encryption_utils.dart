import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' hide Fernet;
import '../services/analytics/config_service.dart';
import '../services/encryption/fernet_service.dart';

class EncryptionUtils {
  /// AES Config from ConfigService (pad to 32 chars for AES-256)
  static final String _rawKey = ConfigService.getEncryptionKey();
  static final Key _aesKey = Key.fromUtf8(
    _rawKey.padRight(32, '0').substring(0, 32),
  );
  static final Encrypter _aesEncrypter = Encrypter(
    AES(_aesKey, mode: AESMode.cbc),
  );

  /// Encrypt using AES with random IV, returns base64
  static String encryptAES(String plainText, {Key? customKey}) {
    final key = customKey ?? _aesKey;
    final aes = Encrypter(AES(key, mode: AESMode.cbc));
    final iv = IV.fromSecureRandom(16);
    final encrypted = aes.encrypt(plainText, iv: iv);
    final combined = base64.encode(iv.bytes + encrypted.bytes);
    return combined;
  }

  /// Decrypt AES using embedded IV
  static String decryptAES(String encryptedText, {Key? customKey}) {
    try {
      final key = customKey ?? _aesKey;
      final aes = Encrypter(AES(key, mode: AESMode.cbc));
      final combined = base64.decode(encryptedText);
      final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = combined.sublist(16);
      final encrypted = Encrypted(Uint8List.fromList(cipherBytes));
      return aes.decrypt(encrypted, iv: iv);
    } catch (e) {
      return '❌ AES Decryption failed: ${e.toString()}';
    }
  }

  /// AES encrypt file
  static Uint8List encryptFileBytes(Uint8List data) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _aesEncrypter.encryptBytes(data, iv: iv);
    return Uint8List.fromList(iv.bytes + encrypted.bytes);
  }

  /// AES decrypt file bytes — fixed return type!
  static Uint8List decryptFileBytes(Uint8List encryptedData) {
    final iv = IV(encryptedData.sublist(0, 16));
    final cipherBytes = encryptedData.sublist(16);
    final encrypted = Encrypted(Uint8List.fromList(cipherBytes));
    final decrypted = _aesEncrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decrypted);
  }

  // ---------------------- Optional: Password Derived Key -------------------- //

  /// Derive AES key from password (PBKDF2)
  static Key deriveKeyFromPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes).bytes;
    return Key(Uint8List.fromList(digest));
  }
}
