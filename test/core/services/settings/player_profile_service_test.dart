import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';

void main() {
  late Directory tempDir;
  late PlayerProfileService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp
        .createTemp('player_profile_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() {
    service = PlayerProfileService();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').clear();
      await Hive.box('settings').close();
      await Hive.deleteBoxFromDisk('settings');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Player name
  // ---------------------------------------------------------------------------

  test('getPlayerName returns default when no value saved', () async {
    expect(await service.getPlayerName(), 'Player');
  });

  test('savePlayerName persists and getPlayerName returns it', () async {
    await service.savePlayerName('Alice');
    expect(await service.getPlayerName(), 'Alice');
  });

  // ---------------------------------------------------------------------------
  // Username
  // ---------------------------------------------------------------------------

  test('getUsername returns null before any save', () async {
    expect(await service.getUsername(), isNull);
  });

  test('saveUsername/getUsername round trip', () async {
    await service.saveUsername('alice_99');
    expect(await service.getUsername(), 'alice_99');
  });

  // ---------------------------------------------------------------------------
  // User ID
  // ---------------------------------------------------------------------------

  test('getUserId returns null before any save', () async {
    expect(await service.getUserId(), isNull);
  });

  test('saveUserId/getUserId round trip', () async {
    await service.saveUserId('uid-abc-123');
    expect(await service.getUserId(), 'uid-abc-123');
  });

  // ---------------------------------------------------------------------------
  // Roles
  // ---------------------------------------------------------------------------

  test('getUserRole returns null before any save', () async {
    expect(await service.getUserRole(), isNull);
  });

  test('saveUserRole/getUserRole round trip', () async {
    await service.saveUserRole('admin');
    expect(await service.getUserRole(), 'admin');
  });

  test('getUserRoles returns empty list by default', () async {
    expect(await service.getUserRoles(), isEmpty);
  });

  test('saveUserRoles/getUserRoles round trip', () async {
    await service.saveUserRoles(['admin', 'moderator']);
    expect(await service.getUserRoles(), ['admin', 'moderator']);
  });

  test('isAdminUser returns true when legacy role is admin', () async {
    await service.saveUserRole('admin');
    expect(await service.isAdminUser(), isTrue);
  });

  test('isAdminUser returns true when roles list contains admin', () async {
    await service.saveUserRoles(['moderator', 'admin']);
    expect(await service.isAdminUser(), isTrue);
  });

  test('isAdminUser returns false when not admin', () async {
    await service.saveUserRole('player');
    await service.saveUserRoles(['player']);
    expect(await service.isAdminUser(), isFalse);
  });

  test('hasRole returns true when role matches', () async {
    await service.saveUserRole('moderator');
    expect(await service.hasRole('moderator'), isTrue);
    expect(await service.hasRole('admin'), isFalse);
  });

  // ---------------------------------------------------------------------------
  // Premium status
  // ---------------------------------------------------------------------------

  test('isPremiumUser defaults to false', () async {
    expect(await service.isPremiumUser(), isFalse);
  });

  test('setPremiumStatus/isPremiumUser round trip', () async {
    await service.setPremiumStatus(true);
    expect(await service.isPremiumUser(), isTrue);
  });

  // ---------------------------------------------------------------------------
  // Country / age group / avatar
  // ---------------------------------------------------------------------------

  test('getCountry returns null by default', () async {
    expect(await service.getCountry(), isNull);
  });

  test('saveCountry/getCountry round trip', () async {
    await service.saveCountry('US');
    expect(await service.getCountry(), 'US');
  });

  test('saveCountry with null is a no-op', () async {
    await service.saveCountry(null);
    expect(await service.getCountry(), isNull);
  });

  test('getAgeGroup returns null by default', () async {
    expect(await service.getAgeGroup(), isNull);
  });

  test('saveAgeGroup/getAgeGroup round trip', () async {
    await service.saveAgeGroup('teens');
    expect(await service.getAgeGroup(), 'teens');
  });

  test('getAvatar returns null by default', () async {
    expect(await service.getAvatar(), isNull);
  });

  test('saveAvatar/getAvatar round trip', () async {
    await service.saveAvatar('/cache/avatar.jpg');
    expect(await service.getAvatar(), '/cache/avatar.jpg');
  });

  // ---------------------------------------------------------------------------
  // Preferred categories
  // ---------------------------------------------------------------------------

  test('getPreferredCategories returns empty list by default', () async {
    expect(await service.getPreferredCategories(), isEmpty);
  });

  test('savePreferredCategories/getPreferredCategories round trip', () async {
    await service.savePreferredCategories(['Science', 'History']);
    expect(await service.getPreferredCategories(), ['Science', 'History']);
  });

  // ---------------------------------------------------------------------------
  // Synaptix mode / home surface / reduced motion / tone
  // ---------------------------------------------------------------------------

  test('getSynaptixMode returns null by default', () async {
    expect(await service.getSynaptixMode(), isNull);
  });

  test('saveSynaptixMode/getSynaptixMode round trip', () async {
    await service.saveSynaptixMode('teen');
    expect(await service.getSynaptixMode(), 'teen');
  });

  test('getPreferredHomeSurface returns null by default', () async {
    expect(await service.getPreferredHomeSurface(), isNull);
  });

  test('savePreferredHomeSurface/getPreferredHomeSurface round trip', () async {
    await service.savePreferredHomeSurface('arcade');
    expect(await service.getPreferredHomeSurface(), 'arcade');
  });

  test('getReducedMotion defaults to false', () async {
    expect(await service.getReducedMotion(), isFalse);
  });

  test('saveReducedMotion/getReducedMotion round trip', () async {
    await service.saveReducedMotion(true);
    expect(await service.getReducedMotion(), isTrue);
  });

  test('getTonePreference returns null by default', () async {
    expect(await service.getTonePreference(), isNull);
  });

  test('saveTonePreference/getTonePreference round trip', () async {
    await service.saveTonePreference('friendly');
    expect(await service.getTonePreference(), 'friendly');
  });

  // ---------------------------------------------------------------------------
  // clearProfile
  // ---------------------------------------------------------------------------

  test('clearProfile removes all stored fields', () async {
    await service.savePlayerName('Alice');
    await service.saveUserId('uid-1');
    await service.saveUserRole('admin');
    await service.setPremiumStatus(true);
    await service.saveCountry('GB');
    await service.saveAgeGroup('adults');
    await service.saveAvatar('/tmp/av.jpg');
    await service.savePreferredCategories(['Sports']);

    await service.clearProfile();

    expect(await service.getPlayerName(), 'Player');
    expect(await service.getUserId(), isNull);
    expect(await service.getUserRole(), isNull);
    expect(await service.isPremiumUser(), isFalse);
    expect(await service.getCountry(), isNull);
    expect(await service.getAgeGroup(), isNull);
    expect(await service.getAvatar(), isNull);
    expect(await service.getPreferredCategories(), isEmpty);
  });

  // ---------------------------------------------------------------------------
  // Level / XP
  // ---------------------------------------------------------------------------

  test('addXP below threshold does not level up', () async {
    await service.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
    final result = await service.addXP(100);
    expect(result['leveledUp'], isFalse);
    expect(result['newXP'], 100);
    expect(result['newLevel'], 0);
  });

  test('addXP at threshold causes level up', () async {
    await service.saveLevelData(level: 0, currentXP: 400, maxXP: 500);
    final result = await service.addXP(100);
    expect(result['leveledUp'], isTrue);
    expect(result['newLevel'], 1);
    expect(result['newXP'], 0);
  });

  test('addXP with multiple level-ups', () async {
    // Level 0: maxXP=500; start at 0, add 1600 XP
    // Level 0→1 at 500 XP; Level 1 maxXP=550; Level 1→2 at 550 XP; etc.
    await service.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
    final result = await service.addXP(1200);
    expect(result['leveledUp'], isTrue);
    expect((result['newLevel'] as int) >= 2, isTrue);
  });

  test('_calculateMaxXPForLevel increases per level via addXP', () async {
    await service.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
    final result = await service.addXP(500); // Level 0→1, maxXP becomes 550
    expect(result['newMaxXP'], 550);
  });

  // ---------------------------------------------------------------------------
  // saveProfileBatch
  // ---------------------------------------------------------------------------

  test('saveProfileBatch saves multiple fields at once', () async {
    await service.saveProfileBatch({
      'player_name': 'Bob',
      'user_id': 'uid-2',
      'user_role': 'player',
      'is_premium': true,
      'country': 'AU',
      'age_group': 'adults',
    });

    expect(await service.getPlayerName(), 'Bob');
    expect(await service.getUserId(), 'uid-2');
    expect(await service.getUserRole(), 'player');
    expect(await service.isPremiumUser(), isTrue);
    expect(await service.getCountry(), 'AU');
    expect(await service.getAgeGroup(), 'adults');
  });

  test('saveProfileBatch ignores keys not present', () async {
    await service.savePlayerName('Existing');
    await service.saveProfileBatch({'country': 'NZ'});
    // player_name should be unchanged
    expect(await service.getPlayerName(), 'Existing');
    expect(await service.getCountry(), 'NZ');
  });

  // ---------------------------------------------------------------------------
  // validateProfile
  // ---------------------------------------------------------------------------

  test('validateProfile returns all false for empty profile', () async {
    final result = await service.validateProfile();
    expect(result['has_user_id'], isFalse);
    expect(result['has_name'], isFalse);
    expect(result['has_username'], isFalse);
    expect(result['has_role'], isFalse);
    expect(result['has_avatar'], isFalse);
    expect(result['has_country'], isFalse);
    expect(result['has_age_group'], isFalse);
  });

  test('validateProfile returns true after saving each field', () async {
    await service.saveUserId('uid-3');
    await service.savePlayerName('Carol');
    await service.saveUsername('carol');
    await service.saveUserRole('player');
    await service.saveAvatar('/tmp/av.png');
    await service.saveCountry('CA');
    await service.saveAgeGroup('teens');

    final result = await service.validateProfile();
    expect(result['has_user_id'], isTrue);
    expect(result['has_name'], isTrue);
    expect(result['has_username'], isTrue);
    expect(result['has_role'], isTrue);
    expect(result['has_avatar'], isTrue);
    expect(result['has_country'], isTrue);
    expect(result['has_age_group'], isTrue);
  });

  // ---------------------------------------------------------------------------
  // loadCompleteProfile
  // ---------------------------------------------------------------------------

  test('loadCompleteProfile returns map with all expected keys', () async {
    await service.savePlayerName('Dave');
    await service.saveUserId('uid-4');

    final profile = await service.loadCompleteProfile();
    expect(profile.containsKey('player_name'), isTrue);
    expect(profile['player_name'], 'Dave');
    expect(profile['user_id'], 'uid-4');
    expect(profile.containsKey('is_admin'), isTrue);
    expect(profile.containsKey('synaptix_mode'), isTrue);
  });

  // ---------------------------------------------------------------------------
  // getProfile (synchronous)
  // ---------------------------------------------------------------------------

  test('getProfile returns defaults when box is not open', () async {
    // Box is closed (tearDown already ran close + delete; box not yet re-opened)
    final profile = service.getProfile();
    expect(profile['name'], 'Player');
    expect(profile['level'], 0);
    expect(profile['currentXP'], 0);
    expect(profile['isPremium'], isFalse);
  });

  test('getProfile returns saved values when box is open', () async {
    // Open box first via an async call
    await service.savePlayerName('Eve');
    await service.saveLevelData(level: 5, currentXP: 200, maxXP: 750);

    final profile = service.getProfile();
    expect(profile['name'], 'Eve');
    expect(profile['level'], 5);
    expect(profile['currentXP'], 200);
    expect(profile['rank'], 'Quiz Enthusiast');
  });

  // ---------------------------------------------------------------------------
  // _calculateRank (via getProfile with open box)
  // ---------------------------------------------------------------------------

  test('rank is Trivia Novice for level 0–4', () async {
    await service.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
    final profile = service.getProfile();
    expect(profile['rank'], 'Trivia Novice');
  });

  test('rank is Trivia Legend at level 50+', () async {
    await service.saveLevelData(level: 50, currentXP: 0, maxXP: 3000);
    final profile = service.getProfile();
    expect(profile['rank'], 'Trivia Legend');
  });
}
