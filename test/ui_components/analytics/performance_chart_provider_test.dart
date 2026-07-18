import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/question_difficulty.dart';
import 'package:synaptix/game/models/question_result_model.dart';
import 'package:synaptix/game/providers/question_analytics_provider.dart';
import 'package:synaptix/game/repositories/question_result_repository.dart';
import 'package:synaptix/ui_components/analytics/performance_line_chart.dart';
import 'package:synaptix/ui_components/analytics/chart_selector.dart';
import 'package:synaptix/ui_components/analytics/performance_chart_provider.dart';

// The chart providers read recent results from QuestionResultRepository (Hive).
// Seed a repo fake so the aggregation produces the full time series; without
// data the provider returns [] by design.
class _FakeQuestionResultRepository extends QuestionResultRepository {
  final List<QuestionResultModel> _seed;
  _FakeQuestionResultRepository(this._seed);

  @override
  List<QuestionResultModel> getRecentResults({int hoursAgo = 24}) => _seed;
}

QuestionResultModel _seedResult() => QuestionResultModel(
      questionId: 'q1',
      category: 'Science',
      difficulty: QuestionDifficulty.easy,
      isCorrect: true,
      timeTakenSeconds: 5,
      xpEarned: 10,
      coinsEarned: 5,
      answeredAt: DateTime.now(),
    );

void main() {
  group('Performance Chart Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          questionResultRepositoryProvider.overrideWithValue(
            _FakeQuestionResultRepository([_seedResult(), _seedResult()]),
          ),
        ],
      );
    });

    test('selectedMetricProvider has default accuracy metric', () {
      final metric = container.read(selectedMetricProvider);
      expect(metric, equals(PerformanceMetric.accuracy));
    });

    test('selectedMetricProvider can be updated', () {
      container.read(selectedMetricProvider.notifier).state =
          PerformanceMetric.xpEarned;

      final metric = container.read(selectedMetricProvider);
      expect(metric, equals(PerformanceMetric.xpEarned));
    });

    test('selectedMetricProvider supports all metrics', () {
      for (final metric in [
        PerformanceMetric.accuracy,
        PerformanceMetric.xpEarned,
        PerformanceMetric.questionsAnswered,
      ]) {
        container.read(selectedMetricProvider.notifier).state = metric;
        expect(container.read(selectedMetricProvider), equals(metric));
      }
    });

    test('selectedTimeRangeProvider has default 24h range', () {
      final range = container.read(selectedTimeRangeProvider);
      expect(range, equals(TimeRange.hours24));
    });

    test('selectedTimeRangeProvider can be updated', () {
      container.read(selectedTimeRangeProvider.notifier).state =
          TimeRange.days7;

      final range = container.read(selectedTimeRangeProvider);
      expect(range, equals(TimeRange.days7));
    });

    test('selectedTimeRangeProvider supports all ranges', () {
      for (final range in [
        TimeRange.hours24,
        TimeRange.days7,
        TimeRange.days30,
      ]) {
        container.read(selectedTimeRangeProvider.notifier).state = range;
        expect(container.read(selectedTimeRangeProvider), equals(range));
      }
    });

    test('performanceChartDataProvider fetches data for 24h', () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      expect(data, isNotNull);
      expect(data, isNotEmpty);
      expect(data.length, equals(24));
    });

    test('performanceChartDataProvider fetches data for 7 days', () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.days7).future);

      expect(data, isNotNull);
      expect(data, isNotEmpty);
      expect(data.length, equals(7));
    });

    test('performanceChartDataProvider fetches data for 30 days', () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.days30).future);

      expect(data, isNotNull);
      expect(data, isNotEmpty);
      expect(data.length, equals(30));
    });

    test('performanceChartDataProvider returns correct data structure',
        () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      expect(data, isNotEmpty);
      final point = data[0];
      expect(point.timestamp, isNotNull);
      expect(point.accuracy, isNotNull);
      expect(point.xpEarned, isNotNull);
      expect(point.questionsAnswered, isNotNull);
    });

    test('performanceChartDataProvider data has valid accuracy values',
        () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      for (final point in data) {
        expect(point.accuracy, greaterThanOrEqualTo(0.0));
        expect(point.accuracy, lessThanOrEqualTo(100.0));
      }
    });

    test('performanceChartDataProvider data has positive xp values', () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      for (final point in data) {
        expect(point.xpEarned, greaterThanOrEqualTo(0));
      }
    });

    test('performanceChartDataProvider data has positive question counts',
        () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      for (final point in data) {
        expect(point.questionsAnswered, greaterThanOrEqualTo(0));
      }
    });

    test('performanceChartDisplayProvider updates when time range changes',
        () async {
      // Read initial data
      var data = await container.read(performanceChartDisplayProvider.future);
      expect(data.length, equals(24));

      // Change time range
      container.read(selectedTimeRangeProvider.notifier).state =
          TimeRange.days7;

      // Read updated data
      data = await container.read(performanceChartDisplayProvider.future);
      expect(data.length, equals(7));
    });

    test('metrics can be changed independently of time range', () async {
      container.read(selectedMetricProvider.notifier).state =
          PerformanceMetric.xpEarned;
      container.read(selectedTimeRangeProvider.notifier).state =
          TimeRange.days7;

      final metric = container.read(selectedMetricProvider);
      final range = container.read(selectedTimeRangeProvider);

      expect(metric, equals(PerformanceMetric.xpEarned));
      expect(range, equals(TimeRange.days7));
    });

    test('time range can be changed multiple times', () async {
      final ranges = [
        TimeRange.hours24,
        TimeRange.days7,
        TimeRange.days30,
        TimeRange.hours24,
      ];

      for (final range in ranges) {
        container.read(selectedTimeRangeProvider.notifier).state = range;
        expect(container.read(selectedTimeRangeProvider), equals(range));
      }
    });
  });

  group('TimeRange Extension', () {
    test('TimeRange.hours24.days returns 1', () {
      expect(TimeRange.hours24.days, equals(1));
    });

    test('TimeRange.days7.days returns 7', () {
      expect(TimeRange.days7.days, equals(7));
    });

    test('TimeRange.days30.days returns 30', () {
      expect(TimeRange.days30.days, equals(30));
    });

    test('TimeRange.hours24.label is correct', () {
      expect(TimeRange.hours24.label, equals('Last 24 Hours'));
    });

    test('TimeRange.days7.label is correct', () {
      expect(TimeRange.days7.label, equals('Last 7 Days'));
    });

    test('TimeRange.days30.label is correct', () {
      expect(TimeRange.days30.label, equals('Last 30 Days'));
    });
  });

  group('PerformanceChartDataProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          questionResultRepositoryProvider.overrideWithValue(
            _FakeQuestionResultRepository([_seedResult(), _seedResult()]),
          ),
        ],
      );
    });

    test('provider caches results for same time range', () async {
      final data1 = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);
      final data2 = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      expect(data1, equals(data2));
    });

    test('provider returns different data for different time ranges', () async {
      final data24h = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);
      final data7d = await container
          .read(performanceChartDataProvider(TimeRange.days7).future);

      expect(data24h.length, equals(24));
      expect(data7d.length, equals(7));
      expect(data24h.length, isNot(equals(data7d.length)));
    });

    test('data is chronologically ordered', () async {
      final data = await container
          .read(performanceChartDataProvider(TimeRange.hours24).future);

      for (int i = 0; i < data.length - 1; i++) {
        expect(
          data[i].timestamp.isBefore(data[i + 1].timestamp) ||
              data[i].timestamp == data[i + 1].timestamp,
          true,
        );
      }
    });
  });
}
