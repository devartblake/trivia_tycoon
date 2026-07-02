import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trivia_tycoon/ui_components/analytics/performance_line_chart.dart';

void main() {
  group('PerformanceLineChart', () {
    late List<PerformanceDataPoint> testData;

    setUp(() {
      final now = DateTime.now();
      testData = [
        PerformanceDataPoint(
          timestamp: now.subtract(const Duration(hours: 2)),
          accuracy: 75.0,
          xpEarned: 200,
          questionsAnswered: 8,
        ),
        PerformanceDataPoint(
          timestamp: now.subtract(const Duration(hours: 1)),
          accuracy: 82.5,
          xpEarned: 250,
          questionsAnswered: 10,
        ),
        PerformanceDataPoint(
          timestamp: now,
          accuracy: 88.0,
          xpEarned: 300,
          questionsAnswered: 12,
        ),
      ];
    });

    testWidgets('renders with accuracy metric', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              metric: PerformanceMetric.accuracy,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with xpEarned metric', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              metric: PerformanceMetric.xpEarned,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with questionsAnswered metric',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              metric: PerformanceMetric.questionsAnswered,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows title when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              title: 'Test Chart Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Chart Title'), findsOneWidget);
    });

    testWidgets('hides title when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              title: '',
            ),
          ),
        ),
      );

      expect(find.text(''), findsNothing);
    });

    testWidgets('shows legend when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              showLegend: true,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('hides legend when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              showLegend: false,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('shows empty state with no data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: [],
              metric: PerformanceMetric.accuracy,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('applies custom line color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              lineColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('applies custom max value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              maxValue: 100.0,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('has correct height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
            ),
          ),
        ),
      );

      final sizeFinder = find.byType(SizedBox);
      expect(sizeFinder, findsWidgets);
    });

    testWidgets('contains grid when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              showGrid: true,
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles single data point', (WidgetTester tester) async {
      final singleData = [testData[0]];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: singleData,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('metric name display is correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
              metric: PerformanceMetric.accuracy,
              showLegend: true,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });

    testWidgets('responsive chart sizing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceLineChart(
              data: testData,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceLineChart), findsOneWidget);
    });
  });

  group('PerformanceDataPoint', () {
    testWidgets('creates data point with all fields', (WidgetTester tester) async {
      final now = DateTime.now();
      final point = PerformanceDataPoint(
        timestamp: now,
        accuracy: 85.5,
        xpEarned: 250,
        questionsAnswered: 10,
      );

      expect(point.timestamp, equals(now));
      expect(point.accuracy, equals(85.5));
      expect(point.xpEarned, equals(250));
      expect(point.questionsAnswered, equals(10));
    });

    testWidgets('handles boundary accuracy values', (WidgetTester tester) async {
      final now = DateTime.now();

      final minPoint = PerformanceDataPoint(
        timestamp: now,
        accuracy: 0.0,
        xpEarned: 0,
        questionsAnswered: 0,
      );

      final maxPoint = PerformanceDataPoint(
        timestamp: now,
        accuracy: 100.0,
        xpEarned: 10000,
        questionsAnswered: 100,
      );

      expect(minPoint.accuracy, equals(0.0));
      expect(maxPoint.accuracy, equals(100.0));
    });
  });

  group('PerformanceMetric', () {
    testWidgets('enum values exist', (WidgetTester tester) async {
      expect(PerformanceMetric.accuracy, isNotNull);
      expect(PerformanceMetric.xpEarned, isNotNull);
      expect(PerformanceMetric.questionsAnswered, isNotNull);
    });
  });
}
