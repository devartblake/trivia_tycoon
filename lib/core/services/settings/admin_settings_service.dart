import 'package:hive/hive.dart';

/// A service for storing and retrieving admin-related app settings.
class AdminSettingsService {
  static const String _adminBox = 'settings';
  static const String _adminModeKey = 'admin_mode';
  static const String _isAdminUserKey = 'is_admin';

  /// Initializes the settings box if not already opened.
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_adminBox)) {
      await Hive.openBox(_adminBox);
    }
  }

  /// Enables or disables Admin Mode
  Future<void> setAdminMode(bool enabled) async {
    await _initBox();
    final box = Hive.box(_adminBox);
    await box.put(_adminModeKey, enabled);
  }

  /// Checks whether Admin Mode is enabled
  Future<bool> isAdminMode() async {
    await _initBox();
    final box = Hive.box(_adminBox);
    return box.get(_adminModeKey, defaultValue: false);
  }

  /// Sets whether the current user is an admin
  Future<void> setAdminUser(bool value) async {
    await _initBox();
    final box = Hive.box(_adminBox);
    await box.put(_isAdminUserKey, value);
  }

  /// Checks if current user has admin role
  Future<bool> isAdminUser() async {
    await _initBox();
    final box = Hive.box(_adminBox);
    return box.get(_isAdminUserKey, defaultValue: false);
  }
}
