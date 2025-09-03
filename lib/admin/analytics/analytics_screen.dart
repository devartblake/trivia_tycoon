import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/admin/widgets/analytics/analytics_empty_state.dart';
import 'package:trivia_tycoon/admin/widgets/analytics/user_type_dropdown.dart';
import 'package:trivia_tycoon/core/manager/analytics/analytics_stream_manager.dart';
import 'package:trivia_tycoon/game/providers/mission_filters_provider.dart';
import '../../ui_components/mission/mission_filters_segmented_tabs.dart';
import '../../game/providers/timeline_filter_provider.dart';
import '../widgets/analytics/timeline_filter_tabs.dart';
import '../widgets/analytics/engagement/engagement_analytics_widget.dart';
import '../widgets/analytics/retention/retention_analytics_widget.dart';
import '../widgets/analytics/mission/mission_analytics_bar_chart.dart';
import '../widgets/analytics/mission/mission_analytics_radar_chart.dart';
import '../widgets/analytics/mission/mission_analytics_widget.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Future<void> _onRefresh() async {
    // Simply refresh all providers
    await ref.refresh(analyticsManagerProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsManagerProvider);
    final filters = ref.watch(missionFiltersProvider);
    final timeline = ref.watch(timelineFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Overview"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        edgeOffset: 80,
        displacement: 80,
        child: analyticsAsync.when(
          data: (data) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const MissionFiltersSegmentedTabs(),
                  const SizedBox(height: 8),
                  const TimelineFilterTabs(),
                  const SizedBox(height: 8),
                  const UserTypeDropdown(),
                  const SizedBox(height: 16),

                  // Mission Summary
                  MissionAnalyticsWidget(
                    totalCompleted: data.missions.fold(0, (sum, e) => sum + e.missionsCompleted),
                    totalSwapped: data.missions.fold(0, (sum, e) => sum + e.missionsSwapped),
                    xpEarned: data.missions.fold(0, (sum, e) => sum + e.xpEarned),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${filters.timeframe} Trends",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mission Radar Chart
                  if (data.missions.length >= 3)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: MissionAnalyticsRadarChart(
                        missionsCompleted: data.missions.map((e) => e.missionsCompleted).toList(),
                        missionsSwapped: data.missions.map((e) => e.missionsSwapped).toList(),
                        xpEarned: data.missions.map((e) => e.xpEarned).toList(),
                        labelMode: filters.timeframe, missions: [],
                      ),
                    )
                  else
                    const AnalyticsEmptyState(message: "Not enough data for Radar Chart."),

                  const SizedBox(height: 24),

                  // Mission Bar Chart
                  if (data.missions.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: 300,
                        child: MissionAnalyticsBarChart(
                          days: data.missions.map((e) => "${e.date.month}/${e.date.day}").toList(),
                          completedData: data.missions.map((e) => e.missionsCompleted).toList(),
                          swappedData: data.missions.map((e) => e.missionsSwapped).toList(), missions: [],
                        ),
                      ),
                    )
                  else
                    const AnalyticsEmptyState(message: "No mission data available for bar chart."),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // Engagement Analytics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "User Engagement",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.engagements.isNotEmpty)
                    EngagementAnalyticsChart(entries: data.engagements)
                  else
                    const AnalyticsEmptyState(message: "No engagement data."),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // Retention Analytics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "User Retention",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.retentions.isNotEmpty)
                    RetentionAnalyticsChart(entries: data.retentions)
                  else
                    const AnalyticsEmptyState(message: "No retention data."),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('⚠️ Error loading analytics: $e')),
        ),
      ),
    );
  }
}
