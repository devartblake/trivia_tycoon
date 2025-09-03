import 'package:hive/hive.dart';

/// PlayerProfileService handles saving and retrieving
/// player-specific information like name and role.
class PlayerProfileService {
  static const _boxName = 'settings';
  static const _playerNameKey = 'playerName';
  static const _userRoleKey = 'userRole';
  static const _userRolesKey = 'userRoles';
  static const _isPremiumKey = 'isPremiumUser';
  static const _countryKey = 'country';
  static const _ageGroupKey = 'ageGroup';
  static const _avatarKey = 'avatar';

  late final Box _box;

  /// Initializes the Hive box for settings.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Saves the player's name.
  Future<void> savePlayerName(String name) async {
    await _box.put(_playerNameKey, name);
  }

  /// Retrieves the player's name (defaults to 'Player').
  String getPlayerName() {
    return _box.get(_playerNameKey, defaultValue: 'Player');
  }

  /// Saves the player's role.
  Future<void> saveUserRole(String role) async {
    await _box.put(_userRoleKey, role);
  }

  /// Retrieves the player's role.
  String? getUserRole() {
    return _box.get(_userRoleKey);
  }

  /// Saves multiple user roles.
  Future<void> saveUserRoles(List<String> roles) async {
    await _box.put(_userRolesKey, roles);
  }

  /// Retrieves the list of user roles.
  List<String> getUserRoles() {
    return List<String>.from(_box.get(_userRolesKey, defaultValue: <String>[]));
  }

  /// Saves premium user flag.
  Future<void> setPremiumStatus(bool value) async {
    await _box.put(_isPremiumKey, value);
  }

  /// Checks if the user is a premium user.
  bool isPremiumUser() {
    return _box.get(_isPremiumKey, defaultValue: false);
  }

  /// Saves country selection.
  Future<void> saveCountry(String country) async {
    await _box.put(_countryKey, country);
  }

  /// Retrieves saved country.
  String? getCountry() {
    return _box.get(_countryKey);
  }

  /// Saves age group.
  Future<void> saveAgeGroup(String ageGroup) async {
    await _box.put(_ageGroupKey, ageGroup);
  }

  /// Retrieves age group.
  String? getAgeGroup() {
    return _box.get(_ageGroupKey);
  }

  /// Saves avatar path.
  Future<void> saveAvatar(String avatarPath) async {
    await _box.put(_avatarKey, avatarPath);
  }

  /// Retrieves saved avatar path.
  String? getAvatar() {
    return _box.get(_avatarKey);
  }

  /// Checks if player is admin based on legacy role or role list.
  bool isAdminUser() {
    final legacy = getUserRole();
    final roles = getUserRoles();
    return legacy == 'admin' || roles.contains('admin');
  }

  /// Returns true if the user has one of the given roles
  bool hasRole(String role) {
    return getUserRole() == role;
  }

  /// Clears all profile-related fields
  Future<void> clearProfile() async {
    await _box.delete(_playerNameKey);
    await _box.delete(_userRoleKey);
    await _box.delete(_isPremiumKey);
    await _box.delete(_countryKey);
    await _box.delete(_ageGroupKey);
    await _box.delete(_avatarKey);
  }
}