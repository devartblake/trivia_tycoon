import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/admin/widgets/analytics/analytics_empty_state.dart';
import 'package:trivia_tycoon/admin/widgets/analytics/user_type_dropdown.dart';
import 'package:trivia_tycoon/core/manager/analytics/analytics_stream_manager.dart';
import 'package:trivia_tycoon/game/providers/mission_filters_provider.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../../ui_components/mission/mission_filters_segmented_tabs.dart';
import '../../game/providers/timeline_filter_provider.dart';
import '../widgets/analytics/timeline_filter_tabs.dart';
import '../widgets/analytics/engagement/engagement_analytics_widget.dart';
import '../widgets/analytics/retention/retention_analytics_widget.dart';
import '../widgets/analytics/mission/mission_analytics_bar_chart.dart';
import '../widgets/analytics/mission/mission_analytics_radar_chart.dart';
import '../widgets/analytics/mission/mission_analytics_widget.dart';
import '../widgets/analytics/spin_analytics_dashboard.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Future<void> _onRefresh() async {
    await ref.refresh(analyticsManagerProvider.future);
    // Also refresh spin analytics
    ref.invalidate(spinAnalyticsSummaryProvider);
    ref.invalidate(spinTrendDataProvider);
    ref.invalidate(recentSpinsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsManagerProvider);
    final filters = ref.watch(missionFiltersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Analytics Overview',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        edgeOffset: 80,
        displacement: 80,
        color: const Color(0xFF6366F1),
        child: analyticsAsync.when(
          data: (data) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 40),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analytics Dashboard',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Track your performance metrics',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============ NEW: SPIN & EARN ANALYTICS ============
                  const SpinAnalyticsDashboard(),

                  const SizedBox(height: 24),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(thickness: 1, color: Colors.grey[200]),
                  ),

                  const SizedBox(height: 24),
                  // ============ END SPIN & EARN ANALYTICS ============

                  // Filters Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          MissionFiltersSegmentedTabs(),
                          SizedBox(height: 12),
                          TimelineFilterTabs(),
                          SizedBox(height: 12),
                          UserTypeDropdown(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mission Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: MissionAnalyticsWidget(
                          totalCompleted: data.missions.fold(0, (sum, e) => sum + e.missionsCompleted),
                          totalSwapped: data.missions.fold(0, (sum, e) => sum + e.missionsSwapped),
                          xpEarned: data.missions.fold(0, (sum, e) => sum + e.xpEarned),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${filters.timeframe} Trends",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mission Radar Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.radar, color: Color(0xFF10B981), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Performance Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data.missions.length >= 3)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: MissionAnalyticsRadarChart(
                                missionsCompleted: data.missions.map((e) => e.missionsCompleted).toList(),
                                missionsSwapped: data.missions.map((e) => e.missionsSwapped).toList(),
                                xpEarned: data.missions.map((e) => e.xpEarned).toList(),
                                labelMode: filters.timeframe,
                                missions: [],
                              ),
                            )
                          else
                            const AnalyticsEmptyState(message: "Not enough data for Radar Chart."),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mission Bar Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bar_chart, color: Color(0xFF3B82F6), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Daily Activity',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data.missions.isNotEmpty)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: SizedBox(
                                height: 300,
                                child: MissionAnalyticsBarChart(
                                  days: data.missions.map((e) => "${e.date.month}/${e.date.day}").toList(),
                                  completedData: data.missions.map((e) => e.missionsCompleted).toList(),
                                  swappedData: data.missions.map((e) => e.missionsSwapped).toList(),
                                  missions: [],
                                ),
                              ),
                            )
                          else
                            const AnalyticsEmptyState(message: "No mission data available for bar chart."),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(thickness: 1, color: Colors.grey[200]),
                  ),

                  const SizedBox(height: 24),

                  // User Engagement Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'User Engagement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people, color: Color(0xFFF59E0B), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Engagement Metrics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data.engagements.isNotEmpty)
                            EngagementAnalyticsChart(entries: data.engagements)
                          else
                            const AnalyticsEmptyState(message: "No engagement data."),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(thickness: 1, color: Colors.grey[200]),
                  ),

                  const SizedBox(height: 24),

                  // User Retention Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'User Retention',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up, color: Color(0xFFEF4444), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Retention Metrics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data.retentions.isNotEmpty)
                            RetentionAnalyticsChart(entries: data.retentions)
                          else
                            const AnalyticsEmptyState(message: "No retention data."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading analytics...',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          error: (e, __) => Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
