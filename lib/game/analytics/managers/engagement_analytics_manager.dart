import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/timeline_filter_provider.dart';
import '../../../game/analytics/services/analytics_aggregation_service.dart';
import '../../../game/analytics/services/analytics_service.dart';
import '../../providers/riverpod_providers.dart';
import '../models/engagement_entry.dart';

final engagementAnalyticsManagerProvider = AsyncNotifierProvider<EngagementAnalyticsManager, List<EngagementEntry>>(
      () => EngagementAnalyticsManager(),
);

class EngagementAnalyticsManager extends AsyncNotifier<List<EngagementEntry>> {
  @override
  Future<List<EngagementEntry>> build() async {
    final timeline = ref.watch(timelineFilterProvider);
    final apiService = ref.read(apiServiceProvider);
    final eventQueueService = ref.read(eventQueueServiceProvider);

    final rawEngagements = await AnalyticsService(apiService, eventQueueService).fetchEngagementAnalytics();
    return AnalyticsAggregationService.aggregateEngagements(rawEngagements, timeline);
  }
}
