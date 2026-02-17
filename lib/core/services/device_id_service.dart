import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists a stable deviceId for login/refresh/logout device-bound sessions.
/// Uses Hive (no shared_preferences).
class DeviceIdService {
  static const String _key = 'device_id';

  final Box _settingsBox;

  DeviceIdService(this._settingsBox);

  /// Returns an existing deviceId or creates + persists a new one.
  Future<String> getOrCreate() async {
    final existing = _settingsBox.get(_key) as String?;
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final created = _generateUuidV4();
    await _settingsBox.put(_key, created);
    return created;
  }

  /// Returns deviceId if already stored; otherwise null.
  String? get current => _settingsBox.get(_key) as String?;

  Future<void> reset() async => _settingsBox.delete(_key);

  // UUIDv4 without external deps.
  String _generateUuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));

    // Set version to 4 => xxxx0100
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Set variant to 10xxxxxx
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int v) => v.toRadixString(16).padLeft(2, '0');

    final b = bytes.map(hex).join();
    return '${b.substring(0, 8)}-'
        '${b.substring(8, 12)}-'
        '${b.substring(12, 16)}-'
        '${b.substring(16, 20)}-'
        '${b.substring(20, 32)}';
  }
}
