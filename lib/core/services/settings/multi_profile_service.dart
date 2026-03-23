import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/profile_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// ProfileData model for individual profiles
class ProfileData {
  final String id;
  final String name;
  final String? avatar;
  final String? country;
  final String? ageGroup;
  final String? userRole;
  final List<String> userRoles;
  final bool isPremium;
  final int level;
  final int currentXP;
  final int maxXP;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> gameStats;
  final Map<String, dynamic> preferences;

  ProfileData({
    required this.id,
    required this.name,
    this.avatar,
    this.country,
    this.ageGroup,
    this.userRole,
    this.userRoles = const [],
    this.isPremium = false,
    this.level = 1,
    this.currentXP = 0,
    this.maxXP = 500,
    required this.createdAt,
    required this.lastActive,
    this.gameStats = const {},
    this.preferences = const {},
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      country: json['country'],
      ageGroup: json['ageGroup'],
      userRole: json['userRole'],
      userRoles: List<String>.from(json['userRoles'] ?? []),
      isPremium: json['isPremium'] ?? false,
      level: json['level'] ?? 1,
      currentXP: json['currentXP'] ?? 0,
      maxXP: json['maxXP'] ?? 500,
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
      gameStats: Map<String, dynamic>.from(json['gameStats'] ?? {}),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'country': country,
      'ageGroup': ageGroup,
      'userRole': userRole,
      'userRoles': userRoles,
      'isPremium': isPremium,
      'level': level,
      'currentXP': currentXP,
      'maxXP': maxXP,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'gameStats': gameStats,
      'preferences': preferences,
    };
  }

  ProfileData copyWith({
    String? name,
    String? avatar,
    String? country,
    String? ageGroup,
    String? userRole,
    List<String>? userRoles,
    bool? isPremium,
    int? level,
    int? currentXP,
    int? maxXP,
    DateTime? lastActive,
    Map<String, dynamic>? gameStats,
    Map<String, dynamic>? preferences,
  }) {
    return ProfileData(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      country: country ?? this.country,
      ageGroup: ageGroup ?? this.ageGroup,
      userRole: userRole ?? this.userRole,
      userRoles: userRoles ?? this.userRoles,
      isPremium: isPremium ?? this.isPremium,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      maxXP: maxXP ?? this.maxXP,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      gameStats: gameStats ?? this.gameStats,
      preferences: preferences ?? this.preferences,
    );
  }

  String get rank {
    if (level >= 50) return 'Trivia Legend';
    if (level >= 40) return 'Quiz Master';
    if (level >= 30) return 'Knowledge Expert';
    if (level >= 20) return 'Trivia Veteran';
    if (level >= 10) return 'Trivia Master';
    if (level >= 5) return 'Quiz Enthusiast';
    return 'Trivia Novice';
  }
}

/// MultiProfileService manages multiple user profiles under one account
class MultiProfileService {
  static const _boxName = 'multi_profiles';
  static const _profilesKey = 'profiles';
  static const _activeProfileKey = 'active_profile_id';
  static const _accountDataKey = 'account_data';
  static const _maxProfiles = 5; // Netflix-style limit

  final Uuid _uuid = const Uuid();
  final ProfileSyncService? _profileSyncService;

  MultiProfileService({ProfileSyncService? profileSyncService})
      : _profileSyncService = profileSyncService;

  String _generateUsernameFromDisplayName(String displayName) {
    final normalized = displayName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    if (normalized.isEmpty) return 'player';
    return normalized;
  }

  Future<void> _syncActiveProfileToLegacySettings(ProfileData profile) async {
    try {
      final legacyService = PlayerProfileService();
      final existingUsername = (profile.preferences['username'] as String?)?.trim();
      final generatedUsername = _generateUsernameFromDisplayName(profile.name);

      await legacyService.savePlayerName(profile.name);
      await legacyService.saveUsername(
        (existingUsername != null && existingUsername.isNotEmpty)
            ? existingUsername.toLowerCase()
            : generatedUsername,
      );

      await legacyService.saveProfileBatch({
        'player_name': profile.name,
        'username': (existingUsername != null && existingUsername.isNotEmpty)
            ? existingUsername.toLowerCase()
            : generatedUsername,
        'country': profile.country,
        'age_group': profile.ageGroup,
        'user_role': profile.userRole,
        'user_roles': profile.userRoles,
        'is_premium': profile.isPremium,
        'avatar': profile.avatar,
      });
    } catch (e) {
      LogManager.debug('[MultiProfile] Failed syncing active profile to legacy settings: $e');
    }
  }

  /// Gets the profiles box, opening it if necessary
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Get all profiles for the account
  Future<List<ProfileData>> getAllProfiles() async {
    try {
      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});

      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      return profilesMap.values
          .map((data) => ProfileData.fromJson(Map<String, dynamic>.from(data)))
          .toList()
        ..sort((a, b) => b.lastActive.compareTo(a.lastActive)); // Most recent first
    } catch (e) {
      LogManager.debug('[MultiProfile] Error getting profiles: $e');
      return [];
    }
  }

  /// Get the currently active profile
  Future<ProfileData?> getActiveProfile() async {
    try {
      final box = await _getBox();
      final activeProfileId = box.get(_activeProfileKey);

      if (activeProfileId == null) {
        // If no active profile set, return the first profile
        final profiles = await getAllProfiles();
        if (profiles.isNotEmpty) {
          await box.put(_activeProfileKey, profiles.first.id);
          return profiles.first;
        }
        return null;
      }

      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      if (!profilesMap.containsKey(activeProfileId)) {
        return null;
      }

      return ProfileData.fromJson(Map<String, dynamic>.from(profilesMap[activeProfileId]));
    } catch (e) {
      LogManager.debug('[MultiProfile] Error getting active profile: $e');
      return null;
    }
  }

  /// Set the active profile
  Future<bool> setActiveProfile(String profileId) async {
    try {
      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      if (!profilesMap.containsKey(profileId)) {
        LogManager.debug('[MultiProfile] Profile $profileId not found');
        return false;
      }

      await box.put(_activeProfileKey, profileId);

      // Update last active timestamp
      final profile = ProfileData.fromJson(Map<String, dynamic>.from(profilesMap[profileId]));
      final updatedProfile = profile.copyWith(lastActive: DateTime.now());
      profilesMap[profileId] = updatedProfile.toJson();
      await box.put(_profilesKey, profilesMap);

      await _syncActiveProfileToLegacySettings(updatedProfile);

      LogManager.debug('[MultiProfile] Switched to profile: ${profile.name}');
      return true;
    } catch (e) {
      LogManager.debug('[MultiProfile] Error setting active profile: $e');
      return false;
    }
  }

  /// Create a new profile
  Future<ProfileData?> createProfile({
    required String name,
    String? avatar,
    String? country,
    String? ageGroup,
    String? userRole,
    List<String>? userRoles,
    bool isPremium = false,
  }) async {
    try {
      final profiles = await getAllProfiles();

      if (profiles.length >= _maxProfiles) {
        LogManager.debug('[MultiProfile] Maximum number of profiles reached');
        return null;
      }

      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      final newProfile = ProfileData(
        id: _uuid.v4(),
        name: name,
        avatar: avatar,
        country: country,
        ageGroup: ageGroup,
        userRole: userRole,
        userRoles: userRoles ?? [],
        isPremium: isPremium,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      profilesMap[newProfile.id] = newProfile.toJson();
      await box.put(_profilesKey, profilesMap);

      // If this is the first profile, make it active
      if (profiles.isEmpty) {
        await box.put(_activeProfileKey, newProfile.id);
        await _syncActiveProfileToLegacySettings(newProfile);
      }

      LogManager.debug('[MultiProfile] Created new profile: ${newProfile.name}');
      return newProfile;
    } catch (e) {
      LogManager.debug('[MultiProfile] Error creating profile: $e');
      return null;
    }
  }

  /// Update an existing profile
  Future<bool> updateProfile(
      String profileId, {
        String? name,
        String? avatar,
        String? country,
        String? ageGroup,
        String? userRole,
        List<String>? userRoles,
        bool? isPremium,
        int? level,
        int? currentXP,
        int? maxXP,
        Map<String, dynamic>? gameStats,
        Map<String, dynamic>? preferences,
      }) async {
    try {
      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      if (!profilesMap.containsKey(profileId)) {
        LogManager.debug('[MultiProfile] Profile $profileId not found for update');
        return false;
      }

      final currentProfile = ProfileData.fromJson(Map<String, dynamic>.from(profilesMap[profileId]));
      final activeProfileId = box.get(_activeProfileKey);

      // Resolve display name and username with ProfileSyncService
      String resolvedName = name ?? currentProfile.name;
      Map<String, dynamic> mergedPreferences = preferences ?? currentProfile.preferences;

      if (_profileSyncService != null && name != null && name != currentProfile.name) {
        final syncResult = await _profileSyncService!.syncProfileData(
          displayName: name,
          existingUsername: (preferences?['username'] as String?) ??
              (currentProfile.preferences['username'] as String?),
        );

        if (syncResult.success) {
          if (syncResult.confirmedDisplayName != null &&
              syncResult.confirmedDisplayName!.isNotEmpty) {
            resolvedName = syncResult.confirmedDisplayName!;
          }

          if (syncResult.confirmedUsername != null &&
              syncResult.confirmedUsername!.isNotEmpty) {
            mergedPreferences = {
              ...(preferences ?? currentProfile.preferences),
              'username': syncResult.confirmedUsername,
            };
          }
        }
      }

      var mergedPreferences = preferences;
      var resolvedName = name;

      if (_profileSyncService != null && activeProfileId == profileId) {
        await _profileSyncService!.retryQueuedUpdates();

        final requestedUsername = (preferences?['username'] as String?)?.trim();
        final candidateDisplayName = (name ?? currentProfile.name).trim();

        if (requestedUsername != null && requestedUsername.isNotEmpty) {
          final syncResult = await _profileSyncService!.syncProfileUpdate(
            displayName: candidateDisplayName,
            username: requestedUsername,
          );

          if (syncResult.confirmedDisplayName != null &&
              syncResult.confirmedDisplayName!.isNotEmpty) {
            resolvedName = syncResult.confirmedDisplayName;
          }

          if (syncResult.confirmedUsername != null &&
              syncResult.confirmedUsername!.isNotEmpty) {
            mergedPreferences = {
              ...(preferences ?? currentProfile.preferences),
              'username': syncResult.confirmedUsername,
            };
          }
        }
      }

      final updatedProfile = currentProfile.copyWith(
        name: resolvedName,
        avatar: avatar,
        country: country,
        ageGroup: ageGroup,
        userRole: userRole,
        userRoles: userRoles,
        isPremium: isPremium,
        level: level,
        currentXP: currentXP,
        maxXP: maxXP,
        lastActive: DateTime.now(),
        gameStats: gameStats,
        preferences: mergedPreferences,
      );

      profilesMap[profileId] = updatedProfile.toJson();
      await box.put(_profilesKey, profilesMap);

      if (activeProfileId == profileId) {
        await _syncActiveProfileToLegacySettings(updatedProfile);
      }

      LogManager.debug('[MultiProfile] Updated profile: ${updatedProfile.name}');
      return true;
    } catch (e) {
      LogManager.debug('[MultiProfile] Error updating profile: $e');
      return false;
    }
  }

  /// Delete a profile
  Future<bool> deleteProfile(String profileId) async {
    try {
      final profiles = await getAllProfiles();

      if (profiles.length <= 1) {
        LogManager.debug('[MultiProfile] Cannot delete the last remaining profile');
        return false;
      }

      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      if (!profilesMap.containsKey(profileId)) {
        LogManager.debug('[MultiProfile] Profile $profileId not found for deletion');
        return false;
      }

      final profileToDelete = ProfileData.fromJson(Map<String, dynamic>.from(profilesMap[profileId]));
      profilesMap.remove(profileId);
      await box.put(_profilesKey, profilesMap);

      // If this was the active profile, switch to another one
      final activeProfileId = box.get(_activeProfileKey);
      if (activeProfileId == profileId) {
        final remainingProfiles = await getAllProfiles();
        if (remainingProfiles.isNotEmpty) {
          await box.put(_activeProfileKey, remainingProfiles.first.id);
        }
      }

      LogManager.debug('[MultiProfile] Deleted profile: ${profileToDelete.name}');
      return true;
    } catch (e) {
      LogManager.debug('[MultiProfile] Error deleting profile: $e');
      return false;
    }
  }

  /// Add XP to active profile
  Future<Map<String, dynamic>> addXPToActiveProfile(int xpToAdd) async {
    final activeProfile = await getActiveProfile();
    if (activeProfile == null) {
      return {'error': 'No active profile found'};
    }

    return await addXPToProfile(activeProfile.id, xpToAdd);
  }

  /// Add XP to specific profile
  Future<Map<String, dynamic>> addXPToProfile(String profileId, int xpToAdd) async {
    try {
      final box = await _getBox();
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final Map<String, dynamic> profilesMap = Map<String, dynamic>.from(profilesData);

      if (!profilesMap.containsKey(profileId)) {
        return {'error': 'Profile not found'};
      }

      final profile = ProfileData.fromJson(Map<String, dynamic>.from(profilesMap[profileId]));

      int newXP = profile.currentXP + xpToAdd;
      int newLevel = profile.level;
      int newMaxXP = profile.maxXP;
      bool leveledUp = false;

      // Check for level up
      while (newXP >= newMaxXP) {
        newXP -= newMaxXP;
        newLevel++;
        newMaxXP = _calculateMaxXPForLevel(newLevel);
        leveledUp = true;
      }

      final updatedProfile = profile.copyWith(
        level: newLevel,
        currentXP: newXP,
        maxXP: newMaxXP,
        lastActive: DateTime.now(),
      );

      profilesMap[profileId] = updatedProfile.toJson();
      await box.put(_profilesKey, profilesMap);

      return {
        'leveledUp': leveledUp,
        'newLevel': newLevel,
        'newXP': newXP,
        'newMaxXP': newMaxXP,
        'xpGained': xpToAdd,
        'profile': updatedProfile,
      };
    } catch (e) {
      LogManager.debug('[MultiProfile] Error adding XP to profile: $e');
      return {'error': e.toString()};
    }
  }

  /// Calculate max XP needed for a given level
  int _calculateMaxXPForLevel(int level) {
    return 500 + (level * 50); // Increases by 50 XP per level
  }

  /// Update game stats for active profile
  Future<bool> updateActiveProfileGameStats(Map<String, dynamic> newStats) async {
    final activeProfile = await getActiveProfile();
    if (activeProfile == null) return false;

    final mergedStats = Map<String, dynamic>.from(activeProfile.gameStats);
    mergedStats.addAll(newStats);

    return await updateProfile(
      activeProfile.id,
      gameStats: mergedStats,
    );
  }

  /// Get account-level data (shared across all profiles)
  Future<Map<String, dynamic>> getAccountData() async {
    try {
      final box = await _getBox();
      return Map<String, dynamic>.from(box.get(_accountDataKey, defaultValue: {}));
    } catch (e) {
      LogManager.debug('[MultiProfile] Error getting account data: $e');
      return {};
    }
  }

  /// Save account-level data
  Future<void> saveAccountData(Map<String, dynamic> accountData) async {
    try {
      final box = await _getBox();
      await box.put(_accountDataKey, accountData);
    } catch (e) {
      LogManager.debug('[MultiProfile] Error saving account data: $e');
    }
  }

  /// Initialize service and migrate existing single profile if needed
  Future<void> initializeAndMigrate(PlayerProfileService legacyService) async {
    try {
      await retryQueuedProfileSyncUpdates();

      final profiles = await getAllProfiles();

      // If no profiles exist, migrate from legacy service
      if (profiles.isEmpty) {
        final legacyProfile = legacyService.getProfile();

        await createProfile(
          name: legacyProfile['name'] ?? 'Player',
          avatar: legacyProfile['avatar'],
          country: legacyProfile['country'],
          ageGroup: legacyProfile['ageGroup'],
          userRole: legacyProfile['role'],
          isPremium: legacyProfile['isPremium'] ?? false,
        );

        LogManager.debug('[MultiProfile] Migrated legacy profile to multi-profile system');
      }
    } catch (e) {
      LogManager.debug('[MultiProfile] Error during initialization/migration: $e');
    }
  }

  /// Retries pending backend profile sync updates, if sync service is enabled.
  Future<void> retryQueuedProfileSyncUpdates() async {
    if (_profileSyncService == null) return;

    try {
      await _profileSyncService!.retryQueuedUpdates();
    } catch (e) {
      debugPrint('[MultiProfile] Failed to retry queued profile sync updates: $e');
    }
  }

  /// Get statistics about profiles
  Map<String, dynamic> getProfileStats() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        return {'error': 'Box not initialized'};
      }

      final box = Hive.box(_boxName);
      final profilesData = box.get(_profilesKey, defaultValue: <String, dynamic>{});
      final profilesMap = Map<String, dynamic>.from(profilesData);

      return {
        'total_profiles': profilesMap.length,
        'max_profiles': _maxProfiles,
        'active_profile_id': box.get(_activeProfileKey),
        'has_account_data': box.containsKey(_accountDataKey),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all profile data (use with caution)
  Future<void> clearAllProfiles() async {
    try {
      final box = await _getBox();
      await box.clear();
      LogManager.debug('[MultiProfile] All profile data cleared');
    } catch (e) {
      LogManager.debug('[MultiProfile] Error clearing profiles: $e');
    }
  }
}