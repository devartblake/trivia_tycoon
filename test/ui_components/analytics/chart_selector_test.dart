import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/ui_components/analytics/chart_selector.dart';
import 'package:trivia_tycoon/ui_components/analytics/performance_line_chart.dart';

void main() {
  group('ChartSelector', () {
    testWidgets('renders metric selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Metric'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('renders time range selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Time Range'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
    });

    testWidgets('shows all metric options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('XP Earned'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
    });

    testWidgets('shows all time range options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('24h'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('calls onMetricChanged when metric selected',
        (WidgetTester tester) async {
      PerformanceMetric? changedMetric;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (metric) {
                changedMetric = metric;
              },
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('XP Earned'));
      await tester.pumpAndSettle();

      expect(changedMetric, equals(PerformanceMetric.xpEarned));
    });

    testWidgets('calls onTimeRangeChanged when time range selected',
        (WidgetTester tester) async {
      TimeRange? changedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (range) {
                changedRange = range;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('7d'));
      await tester.pumpAndSettle();

      expect(changedRange, equals(TimeRange.days7));
    });

    testWidgets('highlights selected metric', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      final accuracyChip = find.widgetWithText(FilterChip, 'Accuracy');
      expect(accuracyChip, findsOneWidget);
    });

    testWidgets('highlights selected time range', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('24h'), findsOneWidget);
    });

    testWidgets('switches between metrics', (WidgetTester tester) async {
      final metrics = <PerformanceMetric>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (metric) {
                metrics.add(metric);
              },
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('XP Earned'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Questions'));
      await tester.pumpAndSettle();

      expect(metrics.length, equals(2));
      expect(metrics[0], equals(PerformanceMetric.xpEarned));
      expect(metrics[1], equals(PerformanceMetric.questionsAnswered));
    });

    testWidgets('switches between time ranges', (WidgetTester tester) async {
      final ranges = <TimeRange>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (range) {
                ranges.add(range);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('7d'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('30d'));
      await tester.pumpAndSettle();

      expect(ranges.length, equals(2));
      expect(ranges[0], equals(TimeRange.days7));
      expect(ranges[1], equals(TimeRange.days30));
    });

    testWidgets('has proper spacing between sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (_) {},
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('handles multiple rapid selections',
        (WidgetTester tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartSelector(
              selectedMetric: PerformanceMetric.accuracy,
              selectedTimeRange: TimeRange.hours24,
              onMetricChanged: (m) {
                selections.add(m.toString());
              },
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('XP Earned'));
      await tester.tap(find.text('Questions'));
      await tester.tap(find.text('Accuracy'));
      await tester.pumpAndSettle();

      expect(selections.length, equals(3));
    });
  });

  group('TimeRange', () {
    testWidgets('TimeRange.hours24 has correct days value',
        (WidgetTester tester) async {
      expect(TimeRange.hours24.days, equals(1));
    });

    testWidgets('TimeRange.days7 has correct days value',
        (WidgetTester tester) async {
      expect(TimeRange.days7.days, equals(7));
    });

    testWidgets('TimeRange.days30 has correct days value',
        (WidgetTester tester) async {
      expect(TimeRange.days30.days, equals(30));
    });

    testWidgets('TimeRange.hours24 has correct label',
        (WidgetTester tester) async {
      expect(
        TimeRange.hours24.label,
        equals('Last 24 Hours'),
      );
    });

    testWidgets('TimeRange.days7 has correct label',
        (WidgetTester tester) async {
      expect(
        TimeRange.days7.label,
        equals('Last 7 Days'),
      );
    });

    testWidgets('TimeRange.days30 has correct label',
        (WidgetTester tester) async {
      expect(
        TimeRange.days30.label,
        equals('Last 30 Days'),
      );
    });
  });
}
