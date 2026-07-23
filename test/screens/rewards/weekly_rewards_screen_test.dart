import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/services/weekly_rewards_api_client.dart';
import 'package:synaptix/game/providers/phase2_reward_providers.dart';
import 'package:synaptix/screens/rewards/weekly_rewards_screen.dart';

import '../../support/hive_test_env.dart';

void main() {
  group('WeeklyRewardsScreen', () {
    late HiveTestEnv hiveEnv;

    setUp(() async {
      // Reward providers require the auth_tokens Hive box to be open, else they
      // throw synchronously instead of entering their loading state.
      hiveEnv = await HiveTestEnv.create(boxes: ['auth_tokens']);
    });

    tearDown(() async {
      await hiveEnv.dispose();
    });

    testWidgets('renders scaffold with app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Weekly Rewards'), findsOneWidget);
    });

    testWidgets('app bar is centered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      final AppBar appBarWidget = tester.widget(appBar);
      expect(appBarWidget.centerTitle, isTrue);
    });

    testWidgets('body contains refresh indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('body is scrollable with always scrollable physics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      final SingleChildScrollView scrollWidget = tester.widget(scrollable);
      expect(
        scrollWidget.physics,
        isA<AlwaysScrollableScrollPhysics>(),
      );
    });

    testWidgets('renders without errors on basic load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      // Should build without throwing
      expect(find.byType(WeeklyRewardsScreen), findsOneWidget);
    });

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              // Keep the schedule pending so the screen stays in its loading
              // (skeleton) state rather than erroring without a ServiceManager.
              weeklyScheduleProvider.overrideWith(
                (ref) => Completer<List<WeeklyRewardDay>>().future,
              ),
            ],
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('weeklyRewardsLoadingSkeleton')),
        findsOneWidget,
      );
    });

    testWidgets('body content is properly padded', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: WeeklyRewardsScreen(),
          ),
        ),
      );

      final padding = find.byType(Padding);
      expect(padding, findsWidgets);
    });
  });
}
