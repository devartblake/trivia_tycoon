import 'retention_entry.dart';
import 'engagement_entry.dart';
import 'mission_analytics_entry.dart';

class AnalyticsData {
  final List<MissionAnalyticsEntry> missions;
  final List<EngagementEntry> engagements;
  final List<RetentionEntry> retentions;

  AnalyticsData({
    required this.missions,
    required this.engagements,
    required this.retentions,
  });
}
