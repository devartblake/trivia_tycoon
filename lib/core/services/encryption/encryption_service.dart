import 'dart:typed_data';
import '../storage/secure_storage.dart';
import 'fernet_service.dart';
import 'package:trivia_tycoon/core/utils/encryption_utils.dart';

/// EncryptionService provides app-wide encryption capabilities
class EncryptionService {
  final FernetService fernetService;
  EncryptionService({required this.fernetService});

  /// Initialize with dependencies
  static Future<EncryptionService> initialize(SecureStorage secureStorage) async {
    final fernet = await FernetService.initialize(secureStorage);
    return EncryptionService(fernetService: fernet);
  }

  /// Encrypt using AES (default app key)
  String encryptAES(String text) => EncryptionUtils.encryptAES(text);

  String decryptAES(String text) => EncryptionUtils.decryptAES(text);

  /// Encrypt/decrypt files
  Uint8List encryptFile(Uint8List data) => EncryptionUtils.encryptFileBytes(data);

  Uint8List decryptFile(Uint8List data) => EncryptionUtils.decryptFileBytes(data);

  /// Fernet support
  Future<String> encryptFernet(String plain) async => await fernetService.encrypt(plain);

  Future<String> decryptFernet(String token) async => await fernetService.decrypt(token);

  /// AES using passphrase-derived key
  String encryptWithPassphrase(String text, String passphrase, String salt) {
    final key = EncryptionUtils.deriveKeyFromPassword(passphrase, salt);
    return EncryptionUtils.encryptAES(text, customKey: key);
  }

  String decryptWithPassphrase(String encryptedText, String passphrase, String salt) {
    final key = EncryptionUtils.deriveKeyFromPassword(passphrase, salt);
    return EncryptionUtils.decryptAES(encryptedText, customKey: key);
  }

  /// Wipe any saved Fernet key (for logout or reset)
  Future<void> clearFernetKey() async => await fernetService.clearKey();
}
