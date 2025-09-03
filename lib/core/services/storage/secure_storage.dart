import 'package:hive/hive.dart';

class SecureStorage {
  static const _boxName = 'secrets';

  Future<void> setLoggedIn(bool value) async {
    final box = await Hive.openBox('app');
    await box.put(_boxName, value);
  }

  Future<bool> isLoggedIn() async {
    final box = await Hive.openBox('app');
    return box.get(_boxName, defaultValue: false);
  }

  Future<void> setUserEmail(String email) async {
    final box = await Hive.openBox('app');
    await box.put(_boxName, email);
  }

  Future<void> removeUserEmail() async {
    final box = await Hive.openBox('app');
    await box.delete(_boxName);
  }

  Future<String?> getUserEmail() async {
    final box = await Hive.openBox('app');
    return box.get(_boxName);
  }

  Future<void> setSecret(String key, String value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  Future<String?> getSecret(String key) async {
    final box = await Hive.openBox(_boxName);
    return box.get(key);
  }

  Future<void> removeSecret(String key) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(key);
  }

  Future<void> clearSecrets() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  Future<Box> getSecretBox() async {
    return await Hive.openBox('secrets');
  }

  /// ** Retrieve, load and clear encryption cache
  Future<void> saveEncryptedCache(
      String boxName,
      String key,
      String encrypted,
      ) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, encrypted);
  }

  Future<String?> loadEncryptedCache(String boxName, String key) async {
    final box = await Hive.openBox(boxName);
    return box.get(key);
  }

  Future<void> clearEncryptedCache(String boxName, String key) async {
    final box = await Hive.openBox(boxName);
    await box.delete(key);
  }
}
