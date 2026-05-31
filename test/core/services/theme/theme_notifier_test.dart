import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/theme/themes.dart';

void main() {
  late Directory tempDir;
  late GeneralKeyValueStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('theme_notifier_test_');
    Hive.init(tempDir.path);
    storage = GeneralKeyValueStorageService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<ThemeNotifier> makeNotifier() async {
    final notifier = ThemeNotifier(storage);
    await notifier.initializationCompleted;
    return notifier;
  }

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('default currentThemeType is AppTheme.defaultTheme', () async {
      final notifier = await makeNotifier();
      expect(notifier.currentThemeType, AppTheme.defaultTheme);
    });

    test('default themeMode is ThemeMode.system', () async {
      final notifier = await makeNotifier();
      expect(notifier.themeMode, ThemeMode.system);
    });
  });

  // -------------------------------------------------------------------------
  // setTheme
  // -------------------------------------------------------------------------

  group('setTheme', () {
    test('updates currentThemeType in memory', () async {
      final notifier = await makeNotifier();
      await notifier.setTheme(ThemeType.allStar);
      expect(notifier.currentThemeType, ThemeType.allStar);
    });

    test('persists theme across notifier instances', () async {
      final notifier1 = await makeNotifier();
      await notifier1.setTheme(ThemeType.competition);

      final notifier2 = await makeNotifier();
      expect(notifier2.currentThemeType, ThemeType.competition);
    });

    test('supports all ThemeType values', () async {
      for (final type in ThemeType.values) {
        final notifier = await makeNotifier();
        await notifier.setTheme(type);
        expect(notifier.currentThemeType, type);
      }
    });
  });

  // -------------------------------------------------------------------------
  // setThemeMode
  // -------------------------------------------------------------------------

  group('setThemeMode', () {
    test('updates themeMode in memory', () async {
      final notifier = await makeNotifier();
      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.themeMode, ThemeMode.dark);
    });

    test('persists themeMode across notifier instances', () async {
      final notifier1 = await makeNotifier();
      await notifier1.setThemeMode(ThemeMode.light);

      final notifier2 = await makeNotifier();
      expect(notifier2.themeMode, ThemeMode.light);
    });

    test('supports light, dark, and system modes', () async {
      for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
        final notifier = await makeNotifier();
        await notifier.setThemeMode(mode);
        expect(notifier.themeMode, mode);
      }
    });
  });

  // -------------------------------------------------------------------------
  // notifyListeners — ChangeNotifier integration
  // -------------------------------------------------------------------------

  group('ChangeNotifier integration', () {
    test('setTheme triggers listener notification', () async {
      final notifier = await makeNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      await notifier.setTheme(ThemeType.allStar);
      expect(notified, isTrue);
    });

    test('setThemeMode triggers listener notification', () async {
      final notifier = await makeNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      await notifier.setThemeMode(ThemeMode.dark);
      expect(notified, isTrue);
    });
  });
}
