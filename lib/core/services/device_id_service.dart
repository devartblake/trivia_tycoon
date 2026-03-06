import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'storage/secure_storage.dart';

/// Manages a persistent device identifier for authentication operations.
///
/// The device ID is:
/// - Generated once on first use
/// - Stored securely in device storage
/// - Persists across app restarts
/// - Required by backend for login/signup/refresh/logout
///
/// This allows the backend to:
/// - Track which devices a user is logged in on
/// - Support "logout from this device" vs "logout everywhere"
/// - Detect suspicious login patterns (e.g., login from 10 devices in 1 minute)
class DeviceIdService {
  static const _kDeviceId = 'device_id';
  final SecureStorage _storage;

  DeviceIdService(this._storage);

  /// Get existing device ID or create a new one if it doesn't exist.
  ///
  /// The device ID is a UUID v4 (random) that uniquely identifies this app
  /// installation. It's stored in secure storage and persists even after
  /// app updates.
  Future<String> getOrCreate() async {
    var id = await _storage.getSecret(_kDeviceId);

    if (id == null || id.isEmpty) {
      // Generate new UUID
      id = const Uuid().v4();
      await _storage.setSecret(_kDeviceId, id);
    }

    return id;
  }


  /// Returns a backend-friendly device type label for this runtime.
  String getDeviceType() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Returns a reusable payload with device identity fields
  /// in common backend casing variants.
  Future<Map<String, String>> getDeviceIdentityPayload() async {
    final id = await getOrCreate();
    final type = getDeviceType();

    return <String, String>{
      'device_id': id,
      'deviceId': id,
      'device_type': type,
      'deviceType': type,
    };
  }

  /// Clear the device ID.
  ///
  /// WARNING: This should only be used for testing or when the user explicitly
  /// wants to "reset" their device identity. After calling this, the next
  /// call to getOrCreate() will generate a new device ID.
  ///
  /// The backend will see the new device ID as a completely different device,
  /// and old refresh tokens tied to the old device ID will no longer work.
  Future<void> clear() async {
    await _storage.removeSecret(_kDeviceId);
  }

  /// Get the current device ID without creating a new one.
  /// Returns null if no device ID has been generated yet.
  Future<String?> get() async {
    return await _storage.getSecret(_kDeviceId);
  }
}