import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/analytics/models/analytics_data.dart';
import '../../../game/providers/mission_filters_provider.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/timeline_filter_provider.dart';
import '../../../game/analytics/services/analytics_aggregation_service.dart';
import '../../../game/analytics/services/analytics_service.dart';

final analyticsManagerProvider = AsyncNotifierProvider<AnalyticsStreamManager, AnalyticsData>(() => AnalyticsStreamManager());

class AnalyticsStreamManager extends AsyncNotifier<AnalyticsData> {
  @override
  Future<AnalyticsData> build() async {
    final filters = ref.watch(missionFiltersProvider);
    final timeline = ref.watch(timelineFilterProvider);

    final serviceManager = ref.watch(serviceManagerProvider);
    final service = AnalyticsService(serviceManager.apiService, serviceManager.eventQueueService);

    final missions = await service.fetchMissionAnalytics();
    final engagements = await service.fetchEngagementAnalytics();
    final retentions = await service.fetchRetentionAnalytics();

    final aggregatedMissions = AnalyticsAggregationService.aggregateMissions(missions, AnalyticsAggregationService.parseTimeframe(filters.timeframe), timeline, filters.userType);
    final aggregatedEngagements = AnalyticsAggregationService.aggregateEngagements(engagements, timeline);
    final aggregatedRetentions = AnalyticsAggregationService.aggregateRetention(retentions, timeline);

    return AnalyticsData(
      missions: aggregatedMissions,
      engagements: aggregatedEngagements,
      retentions: aggregatedRetentions,
    );
  }
}
