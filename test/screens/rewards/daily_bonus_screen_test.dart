import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/screens/rewards/daily_bonus_screen.dart';

void main() {
  group('DailyBonusScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: DailyBonusScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
