import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('player_profile_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  PlayerProfileService _make() => PlayerProfileService();

  Future<void> _openBox() async => Hive.openBox('settings');

  // -------------------------------------------------------------------------
  // player name
  // -------------------------------------------------------------------------

  group('savePlayerName / getPlayerName', () {
    test('defaults to "Player"', () async {
      final svc = _make();
      expect(await svc.getPlayerName(), 'Player');
    });

    test('saves and retrieves name', () async {
      final svc = _make();
      await svc.savePlayerName('Alice');
      expect(await svc.getPlayerName(), 'Alice');
    });

    test('overwrites previous name', () async {
      final svc = _make();
      await svc.savePlayerName('Alice');
      await svc.savePlayerName('Bob');
      expect(await svc.getPlayerName(), 'Bob');
    });
  });

  // -------------------------------------------------------------------------
  // username
  // -------------------------------------------------------------------------

  group('saveUsername / getUsername', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getUsername(), isNull);
    });

    test('saves and retrieves username', () async {
      final svc = _make();
      await svc.saveUsername('alice99');
      expect(await svc.getUsername(), 'alice99');
    });
  });

  // -------------------------------------------------------------------------
  // userId
  // -------------------------------------------------------------------------

  group('saveUserId / getUserId', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getUserId(), isNull);
    });

    test('saves and retrieves userId', () async {
      final svc = _make();
      await svc.saveUserId('backend-uid-123');
      expect(await svc.getUserId(), 'backend-uid-123');
    });
  });

  // -------------------------------------------------------------------------
  // user role
  // -------------------------------------------------------------------------

  group('saveUserRole / getUserRole', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getUserRole(), isNull);
    });

    test('saves and retrieves role', () async {
      final svc = _make();
      await svc.saveUserRole('admin');
      expect(await svc.getUserRole(), 'admin');
    });
  });

  // -------------------------------------------------------------------------
  // user roles list
  // -------------------------------------------------------------------------

  group('saveUserRoles / getUserRoles', () {
    test('empty list when not set', () async {
      final svc = _make();
      expect(await svc.getUserRoles(), isEmpty);
    });

    test('saves and retrieves roles list', () async {
      final svc = _make();
      await svc.saveUserRoles(['admin', 'player']);
      expect(await svc.getUserRoles(), ['admin', 'player']);
    });
  });

  // -------------------------------------------------------------------------
  // premium status
  // -------------------------------------------------------------------------

  group('setPremiumStatus / isPremiumUser', () {
    test('defaults to false', () async {
      final svc = _make();
      expect(await svc.isPremiumUser(), isFalse);
    });

    test('true after setting', () async {
      final svc = _make();
      await svc.setPremiumStatus(true);
      expect(await svc.isPremiumUser(), isTrue);
    });

    test('false after unsetting', () async {
      final svc = _make();
      await svc.setPremiumStatus(true);
      await svc.setPremiumStatus(false);
      expect(await svc.isPremiumUser(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // country
  // -------------------------------------------------------------------------

  group('saveCountry / getCountry', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getCountry(), isNull);
    });

    test('saves and retrieves country', () async {
      final svc = _make();
      await svc.saveCountry('CA');
      expect(await svc.getCountry(), 'CA');
    });

    test('null country is no-op', () async {
      final svc = _make();
      await svc.saveCountry(null);
      expect(await svc.getCountry(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // age group
  // -------------------------------------------------------------------------

  group('saveAgeGroup / getAgeGroup', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getAgeGroup(), isNull);
    });

    test('saves and retrieves age group', () async {
      final svc = _make();
      await svc.saveAgeGroup('teen');
      expect(await svc.getAgeGroup(), 'teen');
    });
  });

  // -------------------------------------------------------------------------
  // avatar
  // -------------------------------------------------------------------------

  group('saveAvatar / getAvatar', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getAvatar(), isNull);
    });

    test('saves and retrieves avatar path', () async {
      final svc = _make();
      await svc.saveAvatar('assets/avatars/cat.png');
      expect(await svc.getAvatar(), 'assets/avatars/cat.png');
    });

    test('null avatar is no-op', () async {
      final svc = _make();
      await svc.saveAvatar(null);
      expect(await svc.getAvatar(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // isAdminUser / hasRole
  // -------------------------------------------------------------------------

  group('isAdminUser / hasRole', () {
    test('isAdminUser false when no role set', () async {
      final svc = _make();
      expect(await svc.isAdminUser(), isFalse);
    });

    test('isAdminUser true when legacy role is admin', () async {
      final svc = _make();
      await svc.saveUserRole('admin');
      expect(await svc.isAdminUser(), isTrue);
    });

    test('isAdminUser true when roles list contains admin', () async {
      final svc = _make();
      await svc.saveUserRoles(['mod', 'admin']);
      expect(await svc.isAdminUser(), isTrue);
    });

    test('isAdminUser false when role is player', () async {
      final svc = _make();
      await svc.saveUserRole('player');
      expect(await svc.isAdminUser(), isFalse);
    });

    test('hasRole true when exact match', () async {
      final svc = _make();
      await svc.saveUserRole('mod');
      expect(await svc.hasRole('mod'), isTrue);
    });

    test('hasRole false when no match', () async {
      final svc = _make();
      await svc.saveUserRole('player');
      expect(await svc.hasRole('admin'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Synaptix mode
  // -------------------------------------------------------------------------

  group('saveSynaptixMode / getSynaptixMode', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getSynaptixMode(), isNull);
    });

    test('saves and retrieves mode', () async {
      final svc = _make();
      await svc.saveSynaptixMode('teen');
      expect(await svc.getSynaptixMode(), 'teen');
    });
  });

  // -------------------------------------------------------------------------
  // preferred home surface
  // -------------------------------------------------------------------------

  group('savePreferredHomeSurface / getPreferredHomeSurface', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getPreferredHomeSurface(), isNull);
    });

    test('saves and retrieves surface', () async {
      final svc = _make();
      await svc.savePreferredHomeSurface('hub');
      expect(await svc.getPreferredHomeSurface(), 'hub');
    });
  });

  // -------------------------------------------------------------------------
  // reduced motion
  // -------------------------------------------------------------------------

  group('saveReducedMotion / getReducedMotion', () {
    test('false by default', () async {
      final svc = _make();
      expect(await svc.getReducedMotion(), isFalse);
    });

    test('saves and retrieves true', () async {
      final svc = _make();
      await svc.saveReducedMotion(true);
      expect(await svc.getReducedMotion(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // tone preference
  // -------------------------------------------------------------------------

  group('saveTonePreference / getTonePreference', () {
    test('null when not set', () async {
      final svc = _make();
      expect(await svc.getTonePreference(), isNull);
    });

    test('saves and retrieves tone', () async {
      final svc = _make();
      await svc.saveTonePreference('casual');
      expect(await svc.getTonePreference(), 'casual');
    });
  });

  // -------------------------------------------------------------------------
  // preferred categories
  // -------------------------------------------------------------------------

  group('savePreferredCategories / getPreferredCategories', () {
    test('empty list when not set', () async {
      final svc = _make();
      expect(await svc.getPreferredCategories(), isEmpty);
    });

    test('saves and retrieves categories', () async {
      final svc = _make();
      await svc.savePreferredCategories(['science', 'history']);
      expect(await svc.getPreferredCategories(), ['science', 'history']);
    });
  });

  // -------------------------------------------------------------------------
  // clearProfile
  // -------------------------------------------------------------------------

  group('clearProfile', () {
    test('clears all profile fields', () async {
      final svc = _make();
      await svc.savePlayerName('Alice');
      await svc.saveUserId('uid1');
      await svc.saveUserRole('admin');
      await svc.setPremiumStatus(true);
      await svc.saveCountry('US');
      await svc.saveAgeGroup('adult');
      await svc.saveAvatar('avatar.png');
      await svc.saveSynaptixMode('adult');
      await svc.clearProfile();
      expect(await svc.getPlayerName(), 'Player');
      expect(await svc.getUserId(), isNull);
      expect(await svc.getUserRole(), isNull);
      expect(await svc.isPremiumUser(), isFalse);
      expect(await svc.getCountry(), isNull);
      expect(await svc.getAgeGroup(), isNull);
      expect(await svc.getAvatar(), isNull);
      expect(await svc.getSynaptixMode(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // loadCompleteProfile
  // -------------------------------------------------------------------------

  group('loadCompleteProfile', () {
    test('returns map with all expected keys', () async {
      final svc = _make();
      final profile = await svc.loadCompleteProfile();
      expect(profile.containsKey('player_name'), isTrue);
      expect(profile.containsKey('user_id'), isTrue);
      expect(profile.containsKey('is_premium'), isTrue);
      expect(profile.containsKey('user_role'), isTrue);
      expect(profile.containsKey('synaptix_mode'), isTrue);
    });

    test('reflects saved values', () async {
      final svc = _make();
      await svc.savePlayerName('Carol');
      await svc.setPremiumStatus(true);
      final profile = await svc.loadCompleteProfile();
      expect(profile['player_name'], 'Carol');
      expect(profile['is_premium'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // saveProfileBatch
  // -------------------------------------------------------------------------

  group('saveProfileBatch', () {
    test('saves player_name, user_id, is_premium fields', () async {
      final svc = _make();
      await svc.saveProfileBatch({
        'player_name': 'Dave',
        'user_id': 'uid-99',
        'is_premium': true,
        'user_role': 'mod',
        'country': 'UK',
        'age_group': 'adult',
        'synaptix_mode': 'adult',
        'reduced_motion': true,
        'tone_preference': 'formal',
      });
      expect(await svc.getPlayerName(), 'Dave');
      expect(await svc.getUserId(), 'uid-99');
      expect(await svc.isPremiumUser(), isTrue);
      expect(await svc.getUserRole(), 'mod');
      expect(await svc.getCountry(), 'UK');
      expect(await svc.getAgeGroup(), 'adult');
      expect(await svc.getSynaptixMode(), 'adult');
      expect(await svc.getReducedMotion(), isTrue);
      expect(await svc.getTonePreference(), 'formal');
    });

    test('ignores missing keys', () async {
      final svc = _make();
      await svc.savePlayerName('Eve');
      await svc.saveProfileBatch({'country': 'AU'});
      expect(await svc.getPlayerName(), 'Eve');
    });
  });

  // -------------------------------------------------------------------------
  // updateLastActive / getLastActiveTime
  // -------------------------------------------------------------------------

  group('updateLastActive / getLastActiveTime', () {
    test('null before any update', () async {
      final svc = _make();
      expect(await svc.getLastActiveTime(), isNull);
    });

    test('set after updateLastActive', () async {
      final svc = _make();
      final before = DateTime.now();
      await svc.updateLastActive();
      final ts = await svc.getLastActiveTime();
      expect(ts, isNotNull);
      expect(ts!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // validateProfile
  // -------------------------------------------------------------------------

  group('validateProfile', () {
    test('has_name false when name is default', () async {
      final svc = _make();
      final v = await svc.validateProfile();
      expect(v['has_name'], isFalse);
    });

    test('has_name true when name is set', () async {
      final svc = _make();
      await svc.savePlayerName('Alice');
      final v = await svc.validateProfile();
      expect(v['has_name'], isTrue);
    });

    test('has_user_id false when not set', () async {
      final svc = _make();
      final v = await svc.validateProfile();
      expect(v['has_user_id'], isFalse);
    });

    test('has_user_id true when set', () async {
      final svc = _make();
      await svc.saveUserId('uid1');
      final v = await svc.validateProfile();
      expect(v['has_user_id'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getProfile (synchronous)
  // -------------------------------------------------------------------------

  group('getProfile', () {
    test('returns defaults when box not open', () {
      final svc = _make();
      final profile = svc.getProfile();
      expect(profile['name'], 'Player');
      expect(profile['isPremium'], isFalse);
    });

    test('returns saved values when box is open', () async {
      await _openBox();
      final svc = _make();
      await svc.savePlayerName('Frank');
      await svc.setPremiumStatus(true);
      final profile = svc.getProfile();
      expect(profile['name'], 'Frank');
      expect(profile['isPremium'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // _calculateRank via addXP / getProfile level
  // -------------------------------------------------------------------------

  group('_calculateRank via level', () {
    Future<String> _rankForLevel(int level) async {
      await _openBox();
      final svc = _make();
      await svc.saveLevelData(level: level);
      return svc.getProfile()['rank'] as String;
    }

    test('level 0 → Trivia Novice', () async {
      expect(await _rankForLevel(0), 'Trivia Novice');
    });

    test('level 5 → Quiz Enthusiast', () async {
      expect(await _rankForLevel(5), 'Quiz Enthusiast');
    });

    test('level 10 → Trivia Master', () async {
      expect(await _rankForLevel(10), 'Trivia Master');
    });

    test('level 20 → Trivia Veteran', () async {
      expect(await _rankForLevel(20), 'Trivia Veteran');
    });

    test('level 30 → Knowledge Expert', () async {
      expect(await _rankForLevel(30), 'Knowledge Expert');
    });

    test('level 40 → Quiz Master', () async {
      expect(await _rankForLevel(40), 'Quiz Master');
    });

    test('level 50 → Trivia Legend', () async {
      expect(await _rankForLevel(50), 'Trivia Legend');
    });
  });

  // -------------------------------------------------------------------------
  // addXP / level up
  // -------------------------------------------------------------------------

  group('addXP', () {
    test('increments XP without level up', () async {
      final svc = _make();
      await svc.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
      final result = await svc.addXP(100);
      expect(result['leveledUp'], isFalse);
      expect(result['newXP'], 100);
    });

    test('levels up when XP reaches maxXP', () async {
      final svc = _make();
      await svc.saveLevelData(level: 0, currentXP: 490, maxXP: 500);
      final result = await svc.addXP(20);
      expect(result['leveledUp'], isTrue);
      expect(result['newLevel'], 1);
    });

    test('XP wraps around on level up', () async {
      final svc = _make();
      await svc.saveLevelData(level: 0, currentXP: 490, maxXP: 500);
      final result = await svc.addXP(20);
      expect(result['newXP'], 10);
    });

    test('maxXP increases per level', () async {
      final svc = _make();
      await svc.saveLevelData(level: 0, currentXP: 490, maxXP: 500);
      final result = await svc.addXP(20);
      expect(result['newMaxXP'], 550); // 500 + 1 * 50
    });

    test('multiple level ups in one XP gain', () async {
      final svc = _make();
      await svc.saveLevelData(level: 0, currentXP: 0, maxXP: 500);
      final result = await svc.addXP(2000);
      expect(result['newLevel'], greaterThan(1));
    });
  });
}
