import 'dart:convert';

import '../services/storage/secure_storage.dart';
import 'secure_channel_models.dart';

class SecureSessionStore {
  static const _sessionKey = 'syn_secure_session';

  final SecureStorage _secureStorage;
  SecureSessionStore(this._secureStorage);

  Future<SecureSession?> load() async {
    final raw = await _secureStorage.getSecret(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return SecureSession.fromJson(decoded);
  }

  Future<void> save(SecureSession session) async {
    await _secureStorage.setSecret(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() => _secureStorage.removeSecret(_sessionKey);
}
