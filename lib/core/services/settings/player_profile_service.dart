import 'package:flutter/material.dart';
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
  static const _sessionDataKey = 'currentSession';
  static const _lastActiveKey = 'lastActive';

  /// Gets the settings box, opening it if necessary
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  // ------------------------- EXISTING METHODS ----------------

  /// Saves the player's name.
  Future<void> savePlayerName(String name) async {
    final box = await _getBox();
    await box.put(_playerNameKey, name);
  }

  /// Retrieves the player's name (defaults to 'Player').
  Future<String> getPlayerName() async {
    final box = await _getBox();
    return box.get(_playerNameKey, defaultValue: 'Player');
  }

  /// Saves the player's role.
  Future<void> saveUserRole(String role) async {
    final box = await _getBox();
    await box.put(_userRoleKey, role);
  }

  /// Retrieves the player's role.
  Future<String?> getUserRole() async {
    final box = await _getBox();
    return box.get(_userRoleKey);
  }

  /// Saves multiple user roles.
  Future<void> saveUserRoles(List<String> roles) async {
    final box = await _getBox();
    await box.put(_userRolesKey, roles);
  }

  /// Retrieves the list of user roles.
  Future<List<String>> getUserRoles() async {
    final box = await _getBox();
    return List<String>.from(box.get(_userRolesKey, defaultValue: <String>[]));
  }

  /// Saves premium user flag.
  Future<void> setPremiumStatus(bool value) async {
    final box = await _getBox();
    await box.put(_isPremiumKey, value);
  }

  /// Checks if the user is a premium user.
  Future<bool> isPremiumUser() async {
    final box = await _getBox();
    return box.get(_isPremiumKey, defaultValue: false);
  }

  /// Saves country selection.
  Future<void> saveCountry(String? country) async {
    if (country == null) return;
    final box = await _getBox();
    await box.put(_countryKey, country);
  }

  /// Retrieves saved country.
  Future<String?> getCountry() async {
    final box = await _getBox();
    return box.get(_countryKey);
  }

  /// Saves age group.
  Future<void> saveAgeGroup(String? ageGroup) async {
    if (ageGroup == null) return;
    final box = await _getBox();
    await box.put(_ageGroupKey, ageGroup);
  }

  /// Retrieves age group.
  Future<String?> getAgeGroup() async {
    final box = await _getBox();
    return box.get(_ageGroupKey);
  }

  /// Saves avatar path.
  Future<void> saveAvatar(String? avatarPath) async {
    if (avatarPath == null) return;
    final box = await _getBox();
    await box.put(_avatarKey, avatarPath);
  }

  /// Retrieves saved avatar path.
  Future<String?> getAvatar() async {
    final box = await _getBox();
    return box.get(_avatarKey);
  }

  /// Checks if player is admin based on legacy role or role list.
  Future<bool> isAdminUser() async {
    final legacy = await getUserRole();
    final roles = await getUserRoles();
    return legacy == 'admin' || roles.contains('admin');
  }

  /// Returns true if the user has one of the given roles
  Future<bool> hasRole(String role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  /// Clears all profile-related fields
  Future<void> clearProfile() async {
    final box = await _getBox();
    await box.delete(_playerNameKey);
    await box.delete(_userRoleKey);
    await box.delete(_isPremiumKey);
    await box.delete(_countryKey);
    await box.delete(_ageGroupKey);
    await box.delete(_avatarKey);
    await box.delete(_sessionDataKey);
    await box.delete(_lastActiveKey);
  }

  // ------------------------- LIFECYCLE METHODS ---------------

  /// Save current session data (called by AppLifecycleObserver)
  Future<void> saveCurrentSession() async {
    try {
      final sessionData = {
        'timestamp': DateTime.now().toIso8601String(),
        'player_name': await getPlayerName(),
        'user_role': await getUserRole(),
        'is_premium': await isPremiumUser(),
        'country': await getCountry(),
        'age_group': await getAgeGroup(),
        'avatar': await getAvatar(),
        'save_reason': 'lifecycle_event',
      };

      final box = await _getBox();
      await box.put(_sessionDataKey, sessionData);
      await box.put(_lastActiveKey, DateTime.now().toIso8601String());

      debugPrint('[PlayerProfile] Current session saved');
    } catch (e) {
      debugPrint('[PlayerProfile] Error saving current session: $e');
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    try {
      final box = await _getBox();
      await box.put(_lastActiveKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[PlayerProfile] Error updating last active: $e');
    }
  }

  /// Get last active time
  Future<DateTime?> getLastActiveTime() async {
    try {
      final box = await _getBox();
      final timestamp = box.get(_lastActiveKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('[PlayerProfile] Error getting last active time: $e');
      return null;
    }
  }

  /// Load complete user profile
  Future<Map<String, dynamic>> loadCompleteProfile() async {
    try {
      return {
        'player_name': await getPlayerName(),
        'user_role': await getUserRole(),
        'user_roles': await getUserRoles(),
        'is_premium': await isPremiumUser(),
        'country': await getCountry(),
        'age_group': await getAgeGroup(),
        'avatar': await getAvatar(),
        'is_admin': await isAdminUser(),
        'last_active': await getLastActiveTime(),
      };
    } catch (e) {
      debugPrint('[PlayerProfile] Error loading complete profile: $e');
      return {};
    }
  }

  /// Save profile batch update
  Future<void> saveProfileBatch(Map<String, dynamic> profileData) async {
    try {
      final box = await _getBox();

      if (profileData.containsKey('player_name')) {
        await box.put(_playerNameKey, profileData['player_name']);
      }
      if (profileData.containsKey('user_role')) {
        await box.put(_userRoleKey, profileData['user_role']);
      }
      if (profileData.containsKey('user_roles')) {
        await box.put(_userRolesKey, profileData['user_roles']);
      }
      if (profileData.containsKey('is_premium')) {
        await box.put(_isPremiumKey, profileData['is_premium']);
      }
      if (profileData.containsKey('country')) {
        await box.put(_countryKey, profileData['country']);
      }
      if (profileData.containsKey('age_group')) {
        await box.put(_ageGroupKey, profileData['age_group']);
      }
      if (profileData.containsKey('avatar')) {
        await box.put(_avatarKey, profileData['avatar']);
      }

      await updateLastActive();
      debugPrint('[PlayerProfile] Profile batch update completed');
    } catch (e) {
      debugPrint('[PlayerProfile] Error in profile batch update: $e');
    }
  }

  /// Get profile statistics
  Map<String, dynamic> getProfileStats() {
    try {
      final box = Hive.box(_boxName);
      final sessionData = box.get(_sessionDataKey);
      final lastActive = box.get(_lastActiveKey);

      return {
        'has_profile_data': getPlayerName() != 'Player',
        'has_session_data': sessionData != null,
        'last_active': lastActive,
        'total_profile_keys': box.keys.where((key) => [
          _playerNameKey, _userRoleKey, _userRolesKey, _isPremiumKey,
          _countryKey, _ageGroupKey, _avatarKey
        ].contains(key)).length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Validate profile completeness
  Future<Map<String, bool>> validateProfile() async {
    try {
      return {
        'has_name': (await getPlayerName()) != 'Player',
        'has_role': (await getUserRole()) != null,
        'has_avatar': (await getAvatar()) != null,
        'has_country': (await getCountry()) != null,
        'has_age_group': (await getAgeGroup()) != null,
      };
    } catch (e) {
      debugPrint('[PlayerProfile] Error validating profile: $e');
      return {};
    }
  }

  /// Get complete profile for UI display (synchronous version)
  Map<String, dynamic> getProfile() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        // Return defaults if box isn't open yet
        return {
          'name': 'Player',
          'rank': 'Trivia Master',
          'level': 0,
          'currentXP': 0,
          'maxXP': 500,
          'role': null,
          'isPremium': false,
          'country': null,
          'ageGroup': 'teens',
          'avatar': null,
        };
      }

      final box = Hive.box(_boxName);
      return {
        'name': box.get(_playerNameKey, defaultValue: 'Player'),
        'rank': _calculateRank(box.get('level', defaultValue: 0)),
        'level': box.get('level', defaultValue: 0),
        'currentXP': box.get('currentXP', defaultValue: 0),
        'maxXP': box.get('maxXP', defaultValue: 500),
        'role': box.get(_userRoleKey),
        'isPremium': box.get(_isPremiumKey, defaultValue: false),
        'country': box.get(_countryKey),
        'ageGroup': box.get(_ageGroupKey, defaultValue: 'teens'),
        'avatar': box.get(_avatarKey),
      };
    } catch (e) {
      debugPrint('[PlayerProfile] Error getting profile: $e');
      return {
        'name': 'Player',
        'rank': 'Trivia Master',
        'level': 12,
        'currentXP': 340,
        'maxXP': 500,
        'role': null,
        'isPremium': false,
        'country': null,
        'ageGroup': 'teens',
        'avatar': null,
      };
    }
  }

  /// Calculate rank based on level
  String _calculateRank(int level) {
    if (level >= 50) return 'Trivia Legend';
    if (level >= 40) return 'Quiz Master';
    if (level >= 30) return 'Knowledge Expert';
    if (level >= 20) return 'Trivia Veteran';
    if (level >= 10) return 'Trivia Master';
    if (level >= 5) return 'Quiz Enthusiast';
    return 'Trivia Novice';
  }

  /// Save level and XP data
  Future<void> saveLevelData({int? level, int? currentXP, int? maxXP}) async {
    final box = await _getBox();
    if (level != null) await box.put('level', level);
    if (currentXP != null) await box.put('currentXP', currentXP);
    if (maxXP != null) await box.put('maxXP', maxXP);
  }

  /// Add XP and handle level ups
  Future<Map<String, dynamic>> addXP(int xpToAdd) async {
    try {
      final box = await _getBox();
      final currentXP = box.get('currentXP', defaultValue: 340);
      final maxXP = box.get('maxXP', defaultValue: 500);
      final currentLevel = box.get('level', defaultValue: 12);

      int newXP = currentXP + xpToAdd;
      int newLevel = currentLevel;
      int newMaxXP = maxXP;
      bool leveledUp = false;

      // Check for level up
      while (newXP >= newMaxXP) {
        newXP -= newMaxXP;
        newLevel++;
        newMaxXP = _calculateMaxXPForLevel(newLevel);
        leveledUp = true;
      }

      await saveLevelData(level: newLevel, currentXP: newXP, maxXP: newMaxXP);

      return {
        'leveledUp': leveledUp,
        'newLevel': newLevel,
        'newXP': newXP,
        'newMaxXP': newMaxXP,
        'xpGained': xpToAdd,
      };
    } catch (e) {
      debugPrint('[PlayerProfile] Error adding XP: $e');
      return {'leveledUp': false, 'error': e.toString()};
    }
  }

  /// Calculate max XP needed for a given level
  int _calculateMaxXPForLevel(int level) {
    return 500 + (level * 50); // Increases by 50 XP per level
  }
}
