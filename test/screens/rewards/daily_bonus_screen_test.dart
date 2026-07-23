import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/services/daily_bonus_api_client.dart';
import 'package:synaptix/game/providers/phase2_reward_providers.dart';
import 'package:synaptix/screens/rewards/daily_bonus_screen.dart';

import '../../support/hive_test_env.dart';

void main() {
  group('DailyBonusScreen', () {
    late ProviderContainer container;
    late HiveTestEnv hiveEnv;

    setUp(() async {
      // The reward providers require the auth_tokens Hive box to be open;
      // without it they throw synchronously instead of entering loading state.
      hiveEnv = await HiveTestEnv.create(boxes: ['auth_tokens']);
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await hiveEnv.dispose();
    });

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              // Keep status pending so the screen stays in its loading state
              // (otherwise the real provider errors without a ServiceManager,
              // showing an error card instead of the spinner).
              dailyBonusStatusProvider.overrideWith(
                (ref) => Completer<AccountRewardStatus>().future,
              ),
            ],
            child: DailyBonusScreen(),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('dailyBonusLoadingSkeleton')),
        findsOneWidget,
      );
    });

    testWidgets('renders scaffold with app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Daily Bonus'), findsOneWidget);
    });

    testWidgets('app bar is centered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
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
            child: DailyBonusScreen(),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('body is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders without errors on basic load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
          ),
        ),
      );

      // Should build without throwing
      expect(find.byType(DailyBonusScreen), findsOneWidget);
    });

    testWidgets('always scrollable physics enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
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
  });
}
