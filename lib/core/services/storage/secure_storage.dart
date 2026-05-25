import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/storage/secure_secret_store.dart';

class SecureStorage {
  static const _boxName = 'secrets';

  final SecureSecretStore _secretStore;

  SecureStorage({SecureSecretStore? secretStore})
      : _secretStore = secretStore ?? SecureSecretStore();

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
    await _secretStore.set(key, value);
  }

  Future<String?> getSecret(String key) async {
    return _secretStore.get(key);
  }

  Future<void> removeSecret(String key) async {
    await _secretStore.delete(key);
  }

  Future<void> clearSecrets() async {
    await _secretStore.clear();
  }

  @Deprecated('Use setSecret/getSecret/removeSecret instead.')
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
