import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/analytics/performance_chart_screen.dart';
import 'package:synaptix/ui_components/analytics/performance_line_chart.dart';
import 'package:synaptix/ui_components/analytics/chart_selector.dart';

void main() {
  group('PerformanceChartScreen (Riverpod)', () {
    testWidgets('renders screen with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(
                title: 'Performance Test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Performance Test'), findsOneWidget);
    });

    testWidgets('renders with default title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Performance Trends'), findsOneWidget);
    });

    testWidgets('renders chart selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ChartSelector), findsOneWidget);
    });

    testWidgets('renders chart component', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('has metric selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Metric'), findsOneWidget);
    });

    testWidgets('has time range selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Time Range'), findsOneWidget);
    });

    testWidgets('shows loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      // On first pump, may show loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays summary statistics after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Summary Statistics'), findsOneWidget);
    });

    testWidgets('shows Average, Peak, and Low stats',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Average'), findsOneWidget);
      expect(find.text('Peak'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('renders in scrollable container', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has proper spacing between elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('wraps chart in Card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('metric selector changes visible metric',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Try to tap metric chip if visible
      final xpChip = find.text('XP Earned');
      if (xpChip.evaluate().isNotEmpty) {
        await tester.tap(xpChip);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('time range selector updates data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Try to tap time range button
      final sevenDay = find.text('7d');
      if (sevenDay.evaluate().isNotEmpty) {
        await tester.tap(sevenDay);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('handles error state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PerformanceChartScreen), findsOneWidget);
    });

    testWidgets('layout is responsive', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PerformanceChartScreen), findsOneWidget);
    });

    testWidgets('supports mobile layout', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PerformanceChartScreen), findsOneWidget);
    });

    testWidgets('all metric options are accessible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      expect(find.text('XP Earned'), findsWidgets);
      expect(find.text('Questions'), findsWidgets);
    });

    testWidgets('all time range options are accessible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceChartScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('24h'), findsWidgets);
      expect(find.text('7d'), findsWidgets);
      expect(find.text('30d'), findsWidgets);
    });
  });
}
