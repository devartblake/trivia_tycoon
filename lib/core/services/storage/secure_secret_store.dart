import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/native_platform_service.dart';

abstract class SecretStore {
  Future<void> set(String key, String value);
  Future<String?> get(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class SecureSecretStore implements SecretStore {
  static const _legacyBoxName = 'secrets';

  final NativePlatformService _native;
  final FlutterSecureStorage _pluginStorage;
  final bool _useAndroidNative;

  SecureSecretStore({
    NativePlatformService? native,
    FlutterSecureStorage? pluginStorage,
    bool? useAndroidNative,
  })  : _native = native ?? NativePlatformService.instance,
        _pluginStorage = pluginStorage ?? const FlutterSecureStorage(),
        _useAndroidNative = useAndroidNative ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> set(String key, String value) async {
    if (_useAndroidNative) {
      try {
        await _native.secureSet(key, value);
        await _deleteLegacy(key);
        return;
      } catch (e) {
        LogManager.debug('[SecureSecretStore] Native set failed: $e');
      }
    }

    try {
      await _pluginStorage.write(key: key, value: value);
      await _deleteLegacy(key);
    } catch (e) {
      LogManager.debug('[SecureSecretStore] Plugin set failed: $e');
      await _writeLegacy(key, value);
    }
  }

  @override
  Future<String?> get(String key) async {
    String? value;

    if (_useAndroidNative) {
      try {
        value = await _native.secureGet(key);
      } on MissingPluginException catch (e) {
        LogManager.debug('[SecureSecretStore] Native get unavailable: $e');
      } catch (e) {
        LogManager.debug('[SecureSecretStore] Native get failed: $e');
      }
    }

    if (value == null) {
      try {
        value = await _pluginStorage.read(key: key);
      } catch (e) {
        LogManager.debug('[SecureSecretStore] Plugin get failed: $e');
      }
    }

    if (value != null) return value;

    final legacyValue = await _readLegacy(key);
    if (legacyValue == null) return null;

    await set(key, legacyValue);
    return legacyValue;
  }

  @override
  Future<void> delete(String key) async {
    if (_useAndroidNative) {
      try {
        await _native.secureDelete(key);
      } catch (e) {
        LogManager.debug('[SecureSecretStore] Native delete failed: $e');
      }
    }

    try {
      await _pluginStorage.delete(key: key);
    } catch (e) {
      LogManager.debug('[SecureSecretStore] Plugin delete failed: $e');
    }

    await _deleteLegacy(key);
  }

  @override
  Future<void> clear() async {
    if (_useAndroidNative) {
      try {
        await _native.secureClear();
      } catch (e) {
        LogManager.debug('[SecureSecretStore] Native clear failed: $e');
      }
    }

    try {
      await _pluginStorage.deleteAll();
    } catch (e) {
      LogManager.debug('[SecureSecretStore] Plugin clear failed: $e');
    }

    await _clearLegacy();
  }

  Future<String?> _readLegacy(String key) async {
    final box = await Hive.openBox(_legacyBoxName);
    final value = box.get(key);
    return value is String ? value : null;
  }

  Future<void> _writeLegacy(String key, String value) async {
    final box = await Hive.openBox(_legacyBoxName);
    await box.put(key, value);
  }

  Future<void> _deleteLegacy(String key) async {
    final box = await Hive.openBox(_legacyBoxName);
    await box.delete(key);
  }

  Future<void> _clearLegacy() async {
    final box = await Hive.openBox(_legacyBoxName);
    await box.clear();
  }
}
