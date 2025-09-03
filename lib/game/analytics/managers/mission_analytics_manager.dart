import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mission_filters_provider.dart';
import '../../providers/timeline_filter_provider.dart';
import '../../../game/analytics/services/analytics_aggregation_service.dart';
import '../../providers/riverpod_providers.dart';
import '../models/mission_analytics_entry.dart';

final missionAnalyticsManagerProvider = AsyncNotifierProvider<MissionAnalyticsManager, List<MissionAnalyticsEntry>>(() => MissionAnalyticsManager());

class MissionAnalyticsManager extends AsyncNotifier<List<MissionAnalyticsEntry>> {
  @override
  Future<List<MissionAnalyticsEntry>> build() async {
    final filters = ref.watch(missionFiltersProvider);
    final timeline = ref.watch(timelineFilterProvider);
    final apiService = ref.watch(analyticsServiceProvider);

    final missions = await apiService.fetchMissionAnalytics();
    return AnalyticsAggregationService.aggregateMissions(
      missions,
      AnalyticsAggregationService.parseTimeframe(filters.timeframe),
      timeline,
      filters.userType,
    );
  }
}
