import 'package:hive/hive.dart';

/// ConfigStorageService is responsible for storing
/// and retrieving configuration files and dynamic JSON configs.
class ConfigStorageService {
  static const _configBox = 'config';

  /// Saves a named config object (typically Map or JSON).
  Future<void> saveConfig(String key, dynamic value) async {
    final box = await Hive.openBox(_configBox);
    await box.put(key, value);
  }

  /// Retrieves a named config object.
  Future<dynamic> getConfig(String key) async {
    final box = await Hive.openBox(_configBox);
    return box.get(key);
  }

  /// Removes a stored config value by key.
  Future<void> removeConfig(String key) async {
    final box = await Hive.openBox(_configBox);
    await box.delete(key);
  }

  /// Clears all config entries.
  Future<void> clearAllConfigs() async {
    final box = await Hive.openBox(_configBox);
    await box.clear();
  }

  /// Returns all stored config keys.
  Future<List<String>> getAllConfigKeys() async {
    final box = await Hive.openBox(_configBox);
    return box.keys.cast<String>().toList();
  }
}
