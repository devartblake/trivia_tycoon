import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/manager/service_manager.dart';
import '../services/analytics_service.dart';
import '../models/mission_analytics_entry.dart';
import '../models/engagement_entry.dart';
import '../models/retention_entry.dart';

/// Provide the AnalyticsService instance (use Provider or directly ServiceManager later if needed)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ServiceManager.instance.analyticsService;
});

/// Raw mock JSON fetchers (non-aggregated)
final missionAnalyticsRawProvider = FutureProvider<List<MissionAnalyticsEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchMissionAnalytics();
});

final engagementAnalyticsRawProvider = FutureProvider<List<EngagementEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchEngagementAnalytics();
});

final retentionAnalyticsRawProvider = FutureProvider<List<RetentionEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchRetentionAnalytics();
});