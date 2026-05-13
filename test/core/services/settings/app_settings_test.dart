import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/navigation/splash_type.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/models/spin_system_models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('app_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // Spin & Earn — daily spin
  // -------------------------------------------------------------------------

  group('AppSettings — daily spin limit', () {
    test('default daily spin limit is 5', () async {
      expect(await AppSettings.getDailySpinLimit(), 5);
    });

    test('set and get daily spin limit', () async {
      await AppSettings.setDailySpinLimit(10);
      expect(await AppSettings.getDailySpinLimit(), 10);
    });

    test('default today spin count is 0', () async {
      expect(await AppSettings.getTodaySpinCount(), 0);
    });

    test('set and get today spin count', () async {
      await AppSettings.setTodaySpinCount(3);
      expect(await AppSettings.getTodaySpinCount(), 3);
    });

    test('incrementTodaySpinCount increments by 1', () async {
      await AppSettings.setTodaySpinCount(2);
      final result = await AppSettings.incrementTodaySpinCount();
      expect(result, 3);
      expect(await AppSettings.getTodaySpinCount(), 3);
    });

    test('resetDailySpinCount resets to 0', () async {
      await AppSettings.setTodaySpinCount(5);
      await AppSettings.resetDailySpinCount();
      expect(await AppSettings.getTodaySpinCount(), 0);
    });

    test('canSpinToday true when count < limit', () async {
      await AppSettings.setDailySpinLimit(5);
      await AppSettings.setTodaySpinCount(3);
      expect(await AppSettings.canSpinToday(), isTrue);
    });

    test('canSpinToday false when count >= limit', () async {
      await AppSettings.setDailySpinLimit(3);
      await AppSettings.setTodaySpinCount(3);
      expect(await AppSettings.canSpinToday(), isFalse);
    });

    test('getRemainingSpinsToday returns limit - count', () async {
      await AppSettings.setDailySpinLimit(5);
      await AppSettings.setTodaySpinCount(2);
      expect(await AppSettings.getRemainingSpinsToday(), 3);
    });

    test('getRemainingSpinsToday clamped to 0 when over limit', () async {
      await AppSettings.setDailySpinLimit(3);
      await AppSettings.setTodaySpinCount(5);
      expect(await AppSettings.getRemainingSpinsToday(), 0);
    });
  });

  group('AppSettings — last spin date', () {
    test('getLastSpinDate returns null when not set', () async {
      expect(await AppSettings.getLastSpinDate(), isNull);
    });

    test('set and get last spin date', () async {
      final dt = DateTime(2025, 6, 15, 10, 0);
      await AppSettings.setLastSpinDate(dt);
      final stored = await AppSettings.getLastSpinDate();
      expect(stored, isNotNull);
      expect(stored!.month, 6);
      expect(stored.day, 15);
    });
  });

  group('AppSettings — weekly spin count', () {
    test('default weekly spin count is 0', () async {
      expect(await AppSettings.getWeeklySpinCount(), 0);
    });

    test('set and get weekly spin count', () async {
      await AppSettings.setWeeklySpinCount(7);
      expect(await AppSettings.getWeeklySpinCount(), 7);
    });

    test('incrementWeeklySpinCount increments by 1', () async {
      await AppSettings.setWeeklySpinCount(4);
      final result = await AppSettings.incrementWeeklySpinCount();
      expect(result, 5);
    });

    test('resetWeeklySpinCount resets to 0', () async {
      await AppSettings.setWeeklySpinCount(6);
      await AppSettings.resetWeeklySpinCount();
      expect(await AppSettings.getWeeklySpinCount(), 0);
    });

    test('setLastWeeklyResetDate and getLastWeeklyResetDate', () async {
      final dt = DateTime(2025, 5, 1);
      await AppSettings.setLastWeeklyResetDate(dt);
      final stored = await AppSettings.getLastWeeklyResetDate();
      expect(stored!.month, 5);
    });
  });

  group('AppSettings — lifetime spins', () {
    test('default total lifetime spins is 0', () async {
      expect(await AppSettings.getTotalLifetimeSpins(), 0);
    });

    test('set and get total lifetime spins', () async {
      await AppSettings.setTotalLifetimeSpins(100);
      expect(await AppSettings.getTotalLifetimeSpins(), 100);
    });

    test('incrementTotalLifetimeSpins returns new count', () async {
      await AppSettings.setTotalLifetimeSpins(9);
      final result = await AppSettings.incrementTotalLifetimeSpins();
      expect(result, 10);
    });
  });

  // -------------------------------------------------------------------------
  // Spin reward points
  // -------------------------------------------------------------------------

  group('AppSettings — spin reward points', () {
    test('default spin reward points is 0.0', () async {
      expect(await AppSettings.getSpinRewardPoints(), 0.0);
    });

    test('set and get spin reward points', () async {
      await AppSettings.setSpinRewardPoints(150.5);
      expect(await AppSettings.getSpinRewardPoints(), 150.5);
    });

    test('addSpinRewardPoints accumulates', () async {
      await AppSettings.setSpinRewardPoints(100.0);
      final result = await AppSettings.addSpinRewardPoints(50.0);
      expect(result, 150.0);
    });

    test('resetSpinRewardPoints sets to 0.0', () async {
      await AppSettings.setSpinRewardPoints(200.0);
      await AppSettings.resetSpinRewardPoints();
      expect(await AppSettings.getSpinRewardPoints(), 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Spin settings booleans
  // -------------------------------------------------------------------------

  group('AppSettings — spin settings booleans', () {
    test('spinAnimationEnabled defaults to true', () async {
      expect(await AppSettings.getSpinAnimationEnabled(), isTrue);
    });

    test('set spin animation disabled', () async {
      await AppSettings.setSpinAnimationEnabled(false);
      expect(await AppSettings.getSpinAnimationEnabled(), isFalse);
    });

    test('spinSoundEnabled defaults to true', () async {
      expect(await AppSettings.getSpinSoundEnabled(), isTrue);
    });

    test('set spin sound disabled', () async {
      await AppSettings.setSpinSoundEnabled(false);
      expect(await AppSettings.getSpinSoundEnabled(), isFalse);
    });

    test('spinHapticEnabled defaults to true', () async {
      expect(await AppSettings.getSpinHapticEnabled(), isTrue);
    });

    test('autoSpinEnabled defaults to false', () async {
      expect(await AppSettings.getAutoSpinEnabled(), isFalse);
    });

    test('set autoSpinEnabled true', () async {
      await AppSettings.setAutoSpinEnabled(true);
      expect(await AppSettings.getAutoSpinEnabled(), isTrue);
    });

    test('spinNotificationEnabled defaults to true', () async {
      expect(await AppSettings.getSpinNotificationEnabled(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Last spin reward
  // -------------------------------------------------------------------------

  group('AppSettings — last spin reward', () {
    test('getLastSpinRewardType is null when not set', () async {
      expect(await AppSettings.getLastSpinRewardType(), isNull);
    });

    test('set and get last spin reward type', () async {
      await AppSettings.setLastSpinRewardType('coins');
      expect(await AppSettings.getLastSpinRewardType(), 'coins');
    });

    test('default last spin reward value is 0', () async {
      expect(await AppSettings.getLastSpinRewardValue(), 0);
    });

    test('set and get last spin reward value', () async {
      await AppSettings.setLastSpinRewardValue(500);
      expect(await AppSettings.getLastSpinRewardValue(), 500);
    });
  });

  // -------------------------------------------------------------------------
  // Bonus spin
  // -------------------------------------------------------------------------

  group('AppSettings — bonus spin', () {
    test('default bonus spin multiplier is 1.0', () async {
      expect(await AppSettings.getBonusSpinMultiplier(), 1.0);
    });

    test('set and get bonus spin multiplier', () async {
      await AppSettings.setBonusSpinMultiplier(2.5);
      expect(await AppSettings.getBonusSpinMultiplier(), 2.5);
    });

    test('isBonusSpinActive false when expiry not set', () async {
      expect(await AppSettings.isBonusSpinActive(), isFalse);
    });

    test('isBonusSpinActive true when expiry is in future', () async {
      final future = DateTime.now().add(const Duration(hours: 2));
      await AppSettings.setBonusSpinExpiry(future);
      expect(await AppSettings.isBonusSpinActive(), isTrue);
    });

    test('isBonusSpinActive false when expiry is in past', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      await AppSettings.setBonusSpinExpiry(past);
      expect(await AppSettings.isBonusSpinActive(), isFalse);
    });

    test('getBonusSpinExpiry null when not set', () async {
      expect(await AppSettings.getBonusSpinExpiry(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Spin history
  // -------------------------------------------------------------------------

  group('AppSettings — spin history', () {
    test('getSpinHistory returns empty list when not set', () async {
      expect(await AppSettings.getSpinHistory(), isEmpty);
    });

    test('addSpinToHistory adds to front', () async {
      await AppSettings.addSpinToHistory({'type': 'coins', 'value': 100});
      await AppSettings.addSpinToHistory({'type': 'gems', 'value': 5});
      final history = await AppSettings.getSpinHistory();
      expect(history.length, 2);
      expect(history.first['type'], 'gems'); // most recent first
    });

    test('clearSpinHistory empties the list', () async {
      await AppSettings.addSpinToHistory({'type': 'coins', 'value': 50});
      await AppSettings.clearSpinHistory();
      expect(await AppSettings.getSpinHistory(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Spin statistics
  // -------------------------------------------------------------------------

  group('AppSettings — spin statistics', () {
    test('getSpinStatistics returns empty map when not set', () async {
      expect(await AppSettings.getSpinStatistics(), isEmpty);
    });

    test('saveSpinStatistics and retrieve', () async {
      await AppSettings.saveSpinStatistics({'totalSpins': 10, 'best': 500});
      final stats = await AppSettings.getSpinStatistics();
      expect(stats['totalSpins'], 10);
    });

    test('updateSpinStatistics increments totalSpins', () async {
      await AppSettings.updateSpinStatistics(
          rewardType: 'coins', rewardValue: 200);
      final stats = await AppSettings.getSpinStatistics();
      expect(stats['totalSpins'], 1);
    });

    test('updateSpinStatistics tracks reward type counts', () async {
      await AppSettings.updateSpinStatistics(
          rewardType: 'coins', rewardValue: 100);
      await AppSettings.updateSpinStatistics(
          rewardType: 'coins', rewardValue: 100);
      final stats = await AppSettings.getSpinStatistics();
      final counts = stats['rewardCounts'] as Map;
      expect(counts['coins'], 2);
    });

    test('updateSpinStatistics tracks best reward', () async {
      await AppSettings.updateSpinStatistics(
          rewardType: 'coins', rewardValue: 100);
      await AppSettings.updateSpinStatistics(
          rewardType: 'gems', rewardValue: 500);
      final stats = await AppSettings.getSpinStatistics();
      expect(stats['bestReward'], 500);
      expect(stats['bestRewardType'], 'gems');
    });
  });

  // -------------------------------------------------------------------------
  // Spin wheel theme
  // -------------------------------------------------------------------------

  group('AppSettings — spin wheel theme', () {
    test('getSpinWheelTheme defaults to "default"', () async {
      expect(await AppSettings.getSpinWheelTheme(), 'default');
    });

    test('set and get spin wheel theme', () async {
      await AppSettings.setSpinWheelTheme('neon');
      expect(await AppSettings.getSpinWheelTheme(), 'neon');
    });

    test('getUnlockedSpinThemes returns ["default"] initially', () async {
      final themes = await AppSettings.getUnlockedSpinThemes();
      expect(themes, contains('default'));
    });

    test('addUnlockedSpinTheme adds if not present', () async {
      await AppSettings.addUnlockedSpinTheme('gold');
      final themes = await AppSettings.getUnlockedSpinThemes();
      expect(themes, contains('gold'));
    });

    test('addUnlockedSpinTheme does not duplicate', () async {
      await AppSettings.addUnlockedSpinTheme('gold');
      await AppSettings.addUnlockedSpinTheme('gold');
      final themes = await AppSettings.getUnlockedSpinThemes();
      expect(themes.where((t) => t == 'gold').length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Splash type
  // -------------------------------------------------------------------------

  group('AppSettings — splash type', () {
    test('getSplashType defaults to fortuneWheel when not set', () async {
      final type = await AppSettings.getSplashType();
      expect(type, SplashType.fortuneWheel);
    });

    test('set and get mindMarket', () async {
      await AppSettings.setSplashType(SplashType.mindMarket);
      expect(await AppSettings.getSplashType(), SplashType.mindMarket);
    });

    test('set and get vaultUnlock', () async {
      await AppSettings.setSplashType(SplashType.vaultUnlock);
      expect(await AppSettings.getSplashType(), SplashType.vaultUnlock);
    });

    test('set and get empireRising', () async {
      await AppSettings.setSplashType(SplashType.empireRising);
      expect(await AppSettings.getSplashType(), SplashType.empireRising);
    });

    test('set and get hqTerminal', () async {
      await AppSettings.setSplashType(SplashType.hqTerminal);
      expect(await AppSettings.getSplashType(), SplashType.hqTerminal);
    });
  });

  // -------------------------------------------------------------------------
  // QR settings
  // -------------------------------------------------------------------------

  group('AppSettings — QR settings', () {
    test('QR auto-launch defaults to true', () async {
      expect(await AppSettings.getQrAutoLaunchEnabled(), isTrue);
    });

    test('set QR auto-launch to false', () async {
      await AppSettings.setQrAutoLaunchEnabled(false);
      expect(await AppSettings.getQrAutoLaunchEnabled(), isFalse);
    });

    test('QR scan history limit defaults to 50', () async {
      expect(await AppSettings.getQrScanHistoryLimit(), 50);
    });

    test('set and get QR scan history limit', () async {
      await AppSettings.setQrScanHistoryLimit(100);
      expect(await AppSettings.getQrScanHistoryLimit(), 100);
    });
  });

  // -------------------------------------------------------------------------
  // Audio settings
  // -------------------------------------------------------------------------

  group('AppSettings — audio settings', () {
    test('save and get audioOn', () async {
      await AppSettings.saveAudioOn(false);
      expect(await AppSettings.getAudioOn(defaultValue: true), isFalse);
    });

    test('getAudioOn returns defaultValue when not set', () async {
      expect(await AppSettings.getAudioOn(defaultValue: true), isTrue);
    });

    test('save and get musicOn', () async {
      await AppSettings.saveMusicOn(false);
      expect(await AppSettings.getMusicOn(defaultValue: true), isFalse);
    });

    test('save and get soundsOn', () async {
      await AppSettings.saveSoundsOn(true);
      expect(await AppSettings.getSoundsOn(defaultValue: false), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Brightness
  // -------------------------------------------------------------------------

  group('AppSettings — brightness', () {
    test('getBrightness defaults to light', () async {
      expect(await AppSettings.getBrightness(), Brightness.light);
    });

    test('set and get dark brightness', () async {
      await AppSettings.setBrightness(Brightness.dark);
      expect(await AppSettings.getBrightness(), Brightness.dark);
    });

    test('set and get light brightness', () async {
      await AppSettings.setBrightness(Brightness.dark);
      await AppSettings.setBrightness(Brightness.light);
      expect(await AppSettings.getBrightness(), Brightness.light);
    });
  });

  // -------------------------------------------------------------------------
  // Player data
  // -------------------------------------------------------------------------

  group('AppSettings — player data', () {
    test('getPlayerName defaults to "Player"', () async {
      expect(await AppSettings.getPlayerName(), 'Player');
    });

    test('save and get player name', () async {
      await AppSettings.savePlayerName('Synaptix Hero');
      expect(await AppSettings.getPlayerName(), 'Synaptix Hero');
    });

    test('getPlayerProgress defaults to empty map', () async {
      expect(await AppSettings.getPlayerProgress(), isEmpty);
    });

    test('save and get player progress', () async {
      await AppSettings.savePlayerProgress({'score': 500, 'streak': 7});
      final progress = await AppSettings.getPlayerProgress();
      expect(progress['score'], 500);
      expect(progress['streak'], 7);
    });

    test('saveQuizProgress and getQuizProgress', () async {
      await AppSettings.saveQuizProgress({'questionIndex': 3, 'score': 200});
      final progress = await AppSettings.getQuizProgress();
      expect(progress['questionIndex'], 3);
    });
  });

  // -------------------------------------------------------------------------
  // Onboarding
  // -------------------------------------------------------------------------

  group('AppSettings — onboarding', () {
    test('getOnboardingStatus defaults to false', () async {
      expect(await AppSettings.getOnboardingStatus(), isFalse);
    });

    test('setOnboardingCompleted marks as done', () async {
      await AppSettings.setOnboardingCompleted();
      expect(await AppSettings.getOnboardingStatus(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Achievements
  // -------------------------------------------------------------------------

  group('AppSettings — achievements', () {
    test('getUnlockedAchievements defaults to empty list', () async {
      expect(await AppSettings.getUnlockedAchievements(), isEmpty);
    });

    test('saveUnlockedAchievements and retrieve', () async {
      await AppSettings.saveUnlockedAchievements(['ach1', 'ach2', 'ach3']);
      expect(await AppSettings.getUnlockedAchievements(),
          ['ach1', 'ach2', 'ach3']);
    });
  });

  // -------------------------------------------------------------------------
  // Purchased songs
  // -------------------------------------------------------------------------

  group('AppSettings — purchased songs', () {
    test('getPurchasedSongs defaults to empty', () async {
      expect(await AppSettings.getPurchasedSongs(), isEmpty);
    });

    test('purchaseSong adds to list', () async {
      await AppSettings.purchaseSong('song_001.mp3');
      expect(await AppSettings.getPurchasedSongs(), contains('song_001.mp3'));
    });

    test('purchaseSong does not duplicate', () async {
      await AppSettings.purchaseSong('song_001.mp3');
      await AppSettings.purchaseSong('song_001.mp3');
      final songs = await AppSettings.getPurchasedSongs();
      expect(songs.where((s) => s == 'song_001.mp3').length, 1);
    });

    test('savePurchasedSongs replaces list', () async {
      await AppSettings.savePurchasedSongs(['a.mp3', 'b.mp3']);
      expect(await AppSettings.getPurchasedSongs(), ['a.mp3', 'b.mp3']);
    });
  });

  // -------------------------------------------------------------------------
  // Theme
  // -------------------------------------------------------------------------

  group('AppSettings — theme name', () {
    test('getThemeName defaults to "Default"', () async {
      expect(await AppSettings.getThemeName(), 'Default');
    });

    test('set and get theme name', () async {
      await AppSettings.setThemeName('Ocean');
      expect(await AppSettings.getThemeName(), 'Ocean');
    });
  });

  group('AppSettings — primary color', () {
    test('getPrimaryColor defaults to blue', () async {
      final color = await AppSettings.getPrimaryColor();
      expect(color.value, const Color(0xFF2196F3).value);
    });

    test('set and get primary color', () async {
      await AppSettings.setPrimaryColor(const Color(0xFFFF0000));
      final color = await AppSettings.getPrimaryColor();
      expect(color.value, const Color(0xFFFF0000).value);
    });
  });

  group('AppSettings — theme presets', () {
    test('getAllThemePresets returns empty when none saved', () async {
      expect(await AppSettings.getAllThemePresets(), isEmpty);
    });

    test('saveThemePreset and getAllThemePresets', () async {
      final preset = ThemeSettings(
        themeName: 'Test Preset',
        primaryColor: const Color(0xFF123456),
        secondaryColor: const Color(0xFF654321),
        brightness: Brightness.dark,
      );
      await AppSettings.saveThemePreset(preset);
      final presets = await AppSettings.getAllThemePresets();
      expect(presets.length, 1);
      expect(presets.first.themeName, 'Test Preset');
    });

    test('deleteThemePreset removes the preset', () async {
      final preset = ThemeSettings(
        themeName: 'ToDelete',
        primaryColor: const Color(0xFF111111),
        secondaryColor: const Color(0xFF222222),
        brightness: Brightness.light,
      );
      await AppSettings.saveThemePreset(preset);
      await AppSettings.deleteThemePreset('ToDelete');
      expect(await AppSettings.getAllThemePresets(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Confetti settings
  // -------------------------------------------------------------------------

  group('AppSettings — confetti', () {
    test('getConfettiTheme defaults to "default"', () async {
      expect(await AppSettings.getConfettiTheme(), 'default');
    });

    test('save and get confetti theme', () async {
      await AppSettings.saveConfettiTheme('fireworks');
      expect(await AppSettings.getConfettiTheme(), 'fireworks');
    });

    test('getConfettiSpeed defaults to 1.0', () async {
      expect(await AppSettings.getConfettiSpeed(), 1.0);
    });

    test('save and get confetti speed', () async {
      await AppSettings.saveConfettiSpeed(2.5);
      expect(await AppSettings.getConfettiSpeed(), 2.5);
    });

    test('getConfettiParticleCount defaults to 100', () async {
      expect(await AppSettings.getConfettiParticleCount(), 100);
    });

    test('save and get confetti particle count', () async {
      await AppSettings.saveConfettiParticleCount(200);
      expect(await AppSettings.getConfettiParticleCount(), 200);
    });

    test('getConfettiColors defaults to empty', () async {
      expect(await AppSettings.getConfettiColors(), isEmpty);
    });

    test('save and get confetti colors', () async {
      await AppSettings.saveConfettiColors([0xFFFF0000, 0xFF00FF00]);
      expect(await AppSettings.getConfettiColors(), [0xFFFF0000, 0xFF00FF00]);
    });

    test('getConfettiPreset defaults to "default"', () async {
      expect(await AppSettings.getConfettiPreset(), 'default');
    });

    test('getParticleDensity defaults to "Auto"', () async {
      expect(await AppSettings.getParticleDensity(), 'Auto');
    });

    test('saveConfettiSettings and get', () async {
      await AppSettings.saveConfettiSettings({'speed': 1.5, 'count': 150});
      final settings = await AppSettings.getConfettiSettings();
      expect(settings['speed'], 1.5);
    });
  });

  // -------------------------------------------------------------------------
  // Jackpot / win streak
  // -------------------------------------------------------------------------

  group('AppSettings — jackpot time', () {
    test('getJackpotTime returns epoch when not set', () async {
      final time = await AppSettings.getJackpotTime();
      expect(time.millisecondsSinceEpoch, 0);
    });

    test('set and get jackpot time', () async {
      final dt = DateTime(2025, 7, 4, 12, 0);
      await AppSettings.setJackpotTime(dt);
      final stored = await AppSettings.getJackpotTime();
      expect(stored.month, 7);
      expect(stored.day, 4);
    });
  });

  // -------------------------------------------------------------------------
  // Badges
  // -------------------------------------------------------------------------

  group('AppSettings — badges', () {
    test('getUnlockedBadges defaults to empty', () async {
      expect(await AppSettings.getUnlockedBadges(), isEmpty);
    });

    test('unlockBadge adds a badge', () async {
      await AppSettings.unlockBadge('gold_star');
      expect(await AppSettings.getUnlockedBadges(), contains('gold_star'));
    });

    test('unlockBadge does not duplicate', () async {
      await AppSettings.unlockBadge('platinum');
      await AppSettings.unlockBadge('platinum');
      final badges = await AppSettings.getUnlockedBadges();
      expect(badges.where((b) => b == 'platinum').length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Purchased items / inventory
  // -------------------------------------------------------------------------

  group('AppSettings — purchased items', () {
    test('hasItem returns false when not purchased', () async {
      expect(await AppSettings.hasItem('item_001'), isFalse);
    });

    test('addPurchasedItem and hasItem', () async {
      await AppSettings.addPurchasedItem('item_001');
      expect(await AppSettings.hasItem('item_001'), isTrue);
    });

    test('different items are independent', () async {
      await AppSettings.addPurchasedItem('item_A');
      expect(await AppSettings.hasItem('item_B'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Generic helpers
  // -------------------------------------------------------------------------

  group('AppSettings — generic helpers', () {
    test('setInt and getInt', () async {
      await AppSettings.setInt('test_int', 42);
      expect(await AppSettings.getInt('test_int'), 42);
    });

    test('getInt returns 0 when not set', () async {
      expect(await AppSettings.getInt('nonexistent_int'), 0);
    });

    test('setString and getString', () async {
      await AppSettings.setString('test_str', 'hello');
      expect(await AppSettings.getString('test_str'), 'hello');
    });

    test('getString returns null when not set', () async {
      expect(await AppSettings.getString('nonexistent_str'), isNull);
    });

    test('setDateTime and getDateTime', () async {
      final dt = DateTime(2025, 3, 20, 8, 0);
      await AppSettings.setDateTime('test_dt', dt);
      final stored = await AppSettings.getDateTime('test_dt');
      expect(stored!.month, 3);
      expect(stored.day, 20);
    });

    test('getDateTime returns null when not set', () async {
      expect(await AppSettings.getDateTime('nonexistent_dt'), isNull);
    });

    test('setColor and getColor', () async {
      await AppSettings.setColor('test_color', const Color(0xFFABCDEF));
      final color = await AppSettings.getColor('test_color');
      expect(color!.value, const Color(0xFFABCDEF).value);
    });

    test('getColor returns null when not set', () async {
      expect(await AppSettings.getColor('nonexistent_color'), isNull);
    });

    test('remove deletes a key', () async {
      await AppSettings.setString('delete_me', 'value');
      await AppSettings.remove('delete_me');
      expect(await AppSettings.getString('delete_me'), isNull);
    });

    test('setStringList and getStringList', () async {
      await AppSettings.setStringList('list_key', ['a', 'b', 'c']);
      final result = await AppSettings.getStringList('list_key');
      expect(result, ['a', 'b', 'c']);
    });

    test('getStringList returns null when not set', () async {
      expect(await AppSettings.getStringList('nonexistent_list'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Segment fetch time
  // -------------------------------------------------------------------------

  group('AppSettings — segment fetch time', () {
    test('getSegmentFetchTime returns null when not set', () async {
      expect(await AppSettings.getSegmentFetchTime(), isNull);
    });

    test('set and get segment fetch time', () async {
      final dt = DateTime(2025, 8, 1, 16, 0);
      await AppSettings.setSegmentFetchTime(dt);
      final stored = await AppSettings.getSegmentFetchTime();
      expect(stored!.month, 8);
    });
  });

  // -------------------------------------------------------------------------
  // Prize log
  // -------------------------------------------------------------------------

  group('AppSettings — prize log', () {
    test('getPrizeLog returns empty list when not set', () async {
      expect(await AppSettings.getPrizeLog(), isEmpty);
    });

    test('setPrizeLog and getPrizeLog', () async {
      final entry = PrizeEntry(
        id: 'p1',
        prize: 'Gold Trophy',
        timestamp: DateTime(2025, 5, 10),
      );
      await AppSettings.setPrizeLog([entry]);
      final log = await AppSettings.getPrizeLog();
      expect(log.length, 1);
      expect(log.first.prize, 'Gold Trophy');
    });

    test('getExportFormat defaults to "json"', () async {
      expect(await AppSettings.getExportFormat(), 'json');
    });

    test('savePrizeLogFilters sets export format', () async {
      await AppSettings.savePrizeLogFilters(exportFormat: 'csv');
      expect(await AppSettings.getExportFormat(), 'csv');
    });

    test('getFilterBadge defaults to empty string', () async {
      expect(await AppSettings.getFilterBadge(), '');
    });

    test('getFilterViewRange defaults to "all"', () async {
      expect(await AppSettings.getFilterViewRange(), 'all');
    });
  });

  // -------------------------------------------------------------------------
  // Total spins
  // -------------------------------------------------------------------------

  group('AppSettings — total spins', () {
    test('getTotalSpins defaults to 0', () async {
      expect(await AppSettings.getTotalSpins(), 0);
    });

    test('incrementTotalSpins adds 1', () async {
      await AppSettings.incrementTotalSpins();
      await AppSettings.incrementTotalSpins();
      expect(await AppSettings.getTotalSpins(), 2);
    });
  });

  // -------------------------------------------------------------------------
  // Last spin notification time
  // -------------------------------------------------------------------------

  group('AppSettings — last spin notification time', () {
    test('null when not set', () async {
      expect(await AppSettings.getLastSpinNotificationTime(), isNull);
    });

    test('set and get last spin notification time', () async {
      final dt = DateTime(2025, 9, 5);
      await AppSettings.setLastSpinNotificationTime(dt);
      final stored = await AppSettings.getLastSpinNotificationTime();
      expect(stored!.month, 9);
    });
  });

  // -------------------------------------------------------------------------
  // getDepthCardTheme
  // -------------------------------------------------------------------------

  group('AppSettings — depth card theme', () {
    test('getDepthCardTheme defaults to "light"', () async {
      expect(await AppSettings.getDepthCardTheme(), 'light');
    });

    test('set and get depth card theme', () async {
      await AppSettings.setDepthCardTheme('dark');
      expect(await AppSettings.getDepthCardTheme(), 'dark');
    });
  });
}
