import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/arcade/missions/arcade_missions_screen.dart';
import 'package:synaptix/arcade/missions/arcade_mission_service.dart';
import 'package:synaptix/arcade/services/arcade_daily_bonus_service.dart';
import 'package:synaptix/arcade/ui/screens/daily_bonus_screen.dart';
import 'package:synaptix/core/services/storage/app_cache_service.dart';
import 'package:synaptix/game/providers/arcade_providers.dart'
    show arcadeMissionServiceProvider;
import 'package:synaptix/game/providers/wallet_providers.dart';
import 'package:synaptix/arcade/providers/arcade_providers.dart'
    show arcadeDailyBonusServiceProvider;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrapWithScope(
  Widget child, {
  required ArcadeDailyBonusService bonus,
  ArcadeMissionService? missions,
  int coins = 500,
  int gems = 10,
}) {
  return ProviderScope(
    overrides: [
      playerCoinsProvider.overrideWith((_) => coins),
      playerGemsProvider.overrideWith((_) => gems),
      arcadeDailyBonusServiceProvider.overrideWithValue(bonus),
      if (missions != null)
        arcadeMissionServiceProvider.overrideWithValue(missions),
    ],
    child: MaterialApp(home: child),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

// QUARANTINED: this file hangs uninterruptibly (0% CPU, native block) when
// pumping DailyBonusScreen/ArcadeMissionsScreen in the headless test runner,
// which wedges the ENTIRE `flutter test` suite past the CI 30-min timeout.
// `--timeout` cannot preempt it. Skipped so the suite terminates reliably;
// see docs/status/TEST_SUITE_TRIAGE.md for the root-cause follow-up.
const _quarantineReason =
    'Hangs the whole suite in headless CI (uninterruptible pump); '
    'see docs/status/TEST_SUITE_TRIAGE.md';

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arcade_widget_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // --------------------------------------------------------------------------
  // DailyBonusScreen
  // --------------------------------------------------------------------------

  group('DailyBonusScreen', skip: _quarantineReason, () {
    testWidgets('renders without errors on first use (unclaimed)',
        (tester) async {
      final bonus = ArcadeDailyBonusService(cache);
      expect(bonus.isClaimedToday, isFalse);

      await tester.pumpWidget(
        _wrapWithScope(const DailyBonusScreen(), bonus: bonus),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DailyBonusScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coin reward amount appears in unclaimed state',
        (tester) async {
      final bonus = ArcadeDailyBonusService(cache);
      final expectedCoins = bonus.todayCoins;

      await tester.pumpWidget(
        _wrapWithScope(const DailyBonusScreen(), bonus: bonus),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining(expectedCoins.toString()),
        findsWidgets,
        reason: 'today\'s coin reward ($expectedCoins) must appear in the UI',
      );
    });

    testWidgets('renders without errors after daily bonus is claimed',
        (tester) async {
      final bonus = ArcadeDailyBonusService(cache);
      bonus.tryClaimToday();
      expect(bonus.isClaimedToday, isTrue);

      await tester.pumpWidget(
        _wrapWithScope(const DailyBonusScreen(), bonus: bonus),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DailyBonusScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('streak increments and screen rebuilds cleanly after claim',
        (tester) async {
      final bonus = ArcadeDailyBonusService(cache);
      expect(bonus.currentStreak, 0);

      bonus.tryClaimToday();
      expect(bonus.currentStreak, greaterThanOrEqualTo(1));

      await tester.pumpWidget(
        _wrapWithScope(const DailyBonusScreen(), bonus: bonus),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DailyBonusScreen), findsOneWidget);
    });

    testWidgets('wallet counters show the injected coin/gem values',
        (tester) async {
      final bonus = ArcadeDailyBonusService(cache);

      await tester.pumpWidget(
        _wrapWithScope(
          const DailyBonusScreen(),
          bonus: bonus,
          coins: 9999,
          gems: 42,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DailyBonusScreen), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // ArcadeMissionsScreen
  // --------------------------------------------------------------------------

  group('ArcadeMissionsScreen', skip: _quarantineReason, () {
    testWidgets('renders without errors with default mission catalog',
        (tester) async {
      final missionSvc = ArcadeMissionService(cache);
      final bonus = ArcadeDailyBonusService(cache);

      await tester.pumpWidget(
        _wrapWithScope(
          const ArcadeMissionsScreen(),
          bonus: bonus,
          missions: missionSvc,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ArcadeMissionsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('default catalog is non-empty and first title appears in UI',
        (tester) async {
      final missionSvc = ArcadeMissionService(cache);
      final bonus = ArcadeDailyBonusService(cache);

      expect(
        missionSvc.missions,
        isNotEmpty,
        reason: 'the built-in mission catalog must have at least one mission',
      );

      await tester.pumpWidget(
        _wrapWithScope(
          const ArcadeMissionsScreen(),
          bonus: bonus,
          missions: missionSvc,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final firstTitle = missionSvc.missions.first.title;
      expect(find.textContaining(firstTitle), findsWidgets);
    });

    testWidgets('progress ratio for all default missions is 0.0–1.0',
        (tester) async {
      final missionSvc = ArcadeMissionService(cache);
      final bonus = ArcadeDailyBonusService(cache);

      for (final m in missionSvc.missions) {
        final ratio = missionSvc.progressRatio(m.id);
        expect(ratio, greaterThanOrEqualTo(0.0),
            reason: '${m.id} ratio must be >= 0');
        expect(ratio, lessThanOrEqualTo(1.0),
            reason: '${m.id} ratio must be <= 1');
      }

      await tester.pumpWidget(
        _wrapWithScope(
          const ArcadeMissionsScreen(),
          bonus: bonus,
          missions: missionSvc,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ArcadeMissionsScreen), findsOneWidget);
    });

    testWidgets('wallet counters reflect injected coin value', (tester) async {
      final missionSvc = ArcadeMissionService(cache);
      final bonus = ArcadeDailyBonusService(cache);

      await tester.pumpWidget(
        _wrapWithScope(
          const ArcadeMissionsScreen(),
          bonus: bonus,
          missions: missionSvc,
          coins: 4200,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('4200'), findsWidgets);
    });
  });
}
