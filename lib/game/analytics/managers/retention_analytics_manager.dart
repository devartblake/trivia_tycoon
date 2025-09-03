import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/analytics/models/retention_entry.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_aggregation_service.dart';
import 'package:trivia_tycoon/game/providers/timeline_filter_provider.dart';

import '../../providers/riverpod_providers.dart';

final retentionAnalyticsManagerProvider =
AsyncNotifierProvider<RetentionAnalyticsManager, List<RetentionEntry>>(
    RetentionAnalyticsManager.new);

class RetentionAnalyticsManager extends AsyncNotifier<List<RetentionEntry>> {
  @override
  Future<List<RetentionEntry>> build() async {
    final timeline = ref.watch(timelineFilterProvider);
    final apiService = ref.watch(analyticsServiceProvider);

    final rawData = await apiService.fetchRetentionAnalytics();
    return AnalyticsAggregationService.aggregateRetention(rawData, timeline);
  }
}
