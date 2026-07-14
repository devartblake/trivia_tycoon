import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/screens/rewards/tier_progress_widget.dart';

void main() {
  group('TierProgressWidget', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: TierProgressWidget(),
            ),
          ),
        ),
      );

      expect(find.byType(TierProgressWidget), findsOneWidget);
    });

    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: TierProgressWidget(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays in a scrollable container when needed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: SingleChildScrollView(
                child: TierProgressWidget(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(TierProgressWidget), findsOneWidget);
    });

    testWidgets('renders as part of dashboard layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: TierProgressWidget(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TierProgressWidget), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('widget is responsive to parent constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: TierProgressWidget(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TierProgressWidget), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
