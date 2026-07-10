import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/theme/seasonal_theme_service.dart';
import 'package:trivia_tycoon/core/theme/themes.dart';
import 'package:trivia_tycoon/game/models/seasonal_theme_models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('seasonal_theme_service_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  SeasonalThemeService makeService() =>
      SeasonalThemeService(GeneralKeyValueStorageService());

  SeasonalTheme activeThemeFixture({
    String id = 'test_season',
    String name = 'Test Season',
    ThemeType themeType = ThemeType.allStar,
  }) {
    final now = DateTime.now();
    return SeasonalTheme(
      id: id,
      name: name,
      themeType: themeType,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 30)),
      isActive: true,
    );
  }

  // -------------------------------------------------------------------------
  // setUserThemeOverride / getUserThemeOverride / hasUserOverride
  // -------------------------------------------------------------------------

  group('setUserThemeOverride / getUserThemeOverride / hasUserOverride', () {
    test('hasUserOverride returns false when nothing stored', () async {
      expect(await makeService().hasUserOverride(), isFalse);
    });

    test('getUserThemeOverride returns null when nothing stored', () async {
      expect(await makeService().getUserThemeOverride(), isNull);
    });

    test('set and get round-trip preserves ThemeType', () async {
      final svc = makeService();
      await svc.setUserThemeOverride(ThemeType.allStar);
      expect(await svc.getUserThemeOverride(), ThemeType.allStar);
      expect(await svc.hasUserOverride(), isTrue);
    });

    test('round-trips all ThemeType values', () async {
      for (final type in ThemeType.values) {
        final svc = makeService();
        await svc.setUserThemeOverride(type);
        expect(await svc.getUserThemeOverride(), type);
        await svc.setUserThemeOverride(null);
      }
    });

    test('setting null removes the override', () async {
      final svc = makeService();
      await svc.setUserThemeOverride(ThemeType.competition);
      await svc.setUserThemeOverride(null);
      expect(await svc.getUserThemeOverride(), isNull);
      expect(await svc.hasUserOverride(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // saveSeasonalTheme / getCurrentSeasonalTheme
  // -------------------------------------------------------------------------

  group('saveSeasonalTheme / getCurrentSeasonalTheme', () {
    test('returns null when nothing stored', () async {
      expect(await makeService().getCurrentSeasonalTheme(), isNull);
    });

    test('active theme with dates spanning now is returned', () async {
      final svc = makeService();
      await svc.saveSeasonalTheme(
          activeThemeFixture(id: 'spring', themeType: ThemeType.allStar));
      final retrieved = await svc.getCurrentSeasonalTheme();
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'spring');
      expect(retrieved.themeType, ThemeType.allStar);
    });

    test('theme with isActive=false returns null', () async {
      final svc = makeService();
      final now = DateTime.now();
      final inactive = SeasonalTheme(
        id: 'inactive',
        name: 'Inactive',
        themeType: ThemeType.competition,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 30)),
        isActive: false,
      );
      await svc.saveSeasonalTheme(inactive);
      expect(await svc.getCurrentSeasonalTheme(), isNull);
    });

    test('expired theme (endDate in past) returns null', () async {
      final svc = makeService();
      final now = DateTime.now();
      final expired = SeasonalTheme(
        id: 'expired',
        name: 'Expired',
        themeType: ThemeType.allStar,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      await svc.saveSeasonalTheme(expired);
      expect(await svc.getCurrentSeasonalTheme(), isNull);
    });

    test('future theme (startDate in future) returns null', () async {
      final svc = makeService();
      final now = DateTime.now();
      final future = SeasonalTheme(
        id: 'future',
        name: 'Future',
        themeType: ThemeType.main,
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 40)),
        isActive: true,
      );
      await svc.saveSeasonalTheme(future);
      expect(await svc.getCurrentSeasonalTheme(), isNull);
    });

    test('overwriting with a new theme returns the latest one', () async {
      final svc = makeService();
      await svc.saveSeasonalTheme(activeThemeFixture(id: 'first'));
      await svc.saveSeasonalTheme(
          activeThemeFixture(id: 'second', themeType: ThemeType.competition));
      final retrieved = await svc.getCurrentSeasonalTheme();
      expect(retrieved!.id, 'second');
      expect(retrieved.themeType, ThemeType.competition);
    });
  });

  // -------------------------------------------------------------------------
  // updateFromBackend
  // -------------------------------------------------------------------------

  group('updateFromBackend', () {
    test('stores theme from a JSON-like map', () async {
      final svc = makeService();
      final now = DateTime.now();
      final themeData = {
        'id': 'backend_season',
        'name': 'Backend Season',
        'theme_type': 'allStar',
        'start_date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'end_date': now.add(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
      };
      await svc.updateFromBackend(themeData);
      final retrieved = await svc.getCurrentSeasonalTheme();
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'backend_season');
      expect(retrieved.themeType, ThemeType.allStar);
    });

    test('invalid JSON map is silently ignored', () async {
      final svc = makeService();
      await svc.updateFromBackend({'bad_key': 'bad_value'});
      expect(await svc.getCurrentSeasonalTheme(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // getActiveTheme — priority: user override > seasonal > default
  // -------------------------------------------------------------------------

  group('getActiveTheme', () {
    test('returns default theme when nothing configured', () async {
      expect(await makeService().getActiveTheme(), AppTheme.defaultTheme);
    });

    test('returns seasonal theme when no user override', () async {
      final svc = makeService();
      await svc.saveSeasonalTheme(
          activeThemeFixture(themeType: ThemeType.competition));
      expect(await svc.getActiveTheme(), ThemeType.competition);
    });

    test('user override takes precedence over active seasonal theme', () async {
      final svc = makeService();
      await svc.saveSeasonalTheme(
          activeThemeFixture(themeType: ThemeType.competition));
      await svc.setUserThemeOverride(ThemeType.allStar);
      expect(await svc.getActiveTheme(), ThemeType.allStar);
    });

    test('returns default when seasonal theme is inactive', () async {
      final svc = makeService();
      final now = DateTime.now();
      final inactive = SeasonalTheme(
        id: 'i',
        name: 'I',
        themeType: ThemeType.competition,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 10)),
        isActive: false,
      );
      await svc.saveSeasonalTheme(inactive);
      expect(await svc.getActiveTheme(), AppTheme.defaultTheme);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear', () {
    test('removes both seasonal theme and user override', () async {
      final svc = makeService();
      await svc.saveSeasonalTheme(activeThemeFixture());
      await svc.setUserThemeOverride(ThemeType.allStar);
      await svc.clear();
      expect(await svc.getCurrentSeasonalTheme(), isNull);
      expect(await svc.hasUserOverride(), isFalse);
      expect(await svc.getActiveTheme(), AppTheme.defaultTheme);
    });
  });

  // -------------------------------------------------------------------------
  // static getExampleSeasons
  // -------------------------------------------------------------------------

  group('getExampleSeasons', () {
    test('returns exactly 3 example seasons', () {
      expect(SeasonalThemeService.getExampleSeasons().length, 3);
    });

    test('all seasons have non-empty id and name', () {
      for (final season in SeasonalThemeService.getExampleSeasons()) {
        expect(season.id, isNotEmpty);
        expect(season.name, isNotEmpty);
      }
    });

    test('all seasons have a valid themeType', () {
      for (final season in SeasonalThemeService.getExampleSeasons()) {
        expect(ThemeType.values, contains(season.themeType));
      }
    });
  });
}
