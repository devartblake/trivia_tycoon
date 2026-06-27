import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/navigation_extensions.dart';

import '../../core/helpers/mission_notification_helper.dart';
import '../../game/state/hybrid_mission_state.dart' hide currentUserIdProvider;
import '../../game/providers/profile_providers.dart' show currentUserIdProvider;

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MissionNotificationHelper _notificationHelper =
      MissionNotificationHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    ref.read(currentUserIdProvider.future).then((userId) {
      _notificationHelper.onMissionsScreenVisited(userId: userId);
    }).catchError((_) {
      _notificationHelper.onMissionsScreenVisited(userId: 'anonymous');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missions = ref.watch(liveMissionsProvider);
    final dailyMissions =
        missions.where((m) => m['status'] != 'completed').toList();
    final completedMissions =
        missions.where((m) => m['status'] == 'completed').toList();
    final totalXP = missions.fold<int>(
        0, (sum, m) => sum + ((m['reward'] as num?)?.toInt() ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => context.safeBack(),
        ),
        title: const Text(
          "Missions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(totalXP),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyMissions(dailyMissions),
                  _buildWeeklyMissions(completedMissions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalXP) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withValues(alpha: 0.8),
            const Color(0xFF5A4FCF).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Missions Center",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Complete missions to earn rewards",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  "$totalXP XP",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C54).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C5CE7).withValues(alpha: 0.8),
              const Color(0xFF5A4FCF).withValues(alpha: 0.6),
            ],
          ),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.today, size: 20),
                const SizedBox(width: 8),
                const Text("Today's Missions"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                const Text("Weekly"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMissions(List<Map<String, dynamic>> missions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Today's Missions",
            "",
            "",
          ),
          const SizedBox(height: 16),
          if (missions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No active missions right now.\nCheck back later!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...missions.map((mission) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMissionCard(
                  missionId: mission['id'].toString(),
                  icon: _iconForMission(mission['icon']),
                  title: mission['title'] as String? ?? 'Mission',
                  progress: (mission['progress'] as num?)?.toInt() ?? 0,
                  total: (mission['total'] as num?)?.toInt() ?? 1,
                  reward: (mission['reward'] as num?)?.toInt() ?? 0,
                  isCompleted: mission['status'] == 'completed',
                  isClaimed: mission['claimed'] == true,
                  badge: mission['badge'] as String? ?? 'DAILY',
                ),
              );
            }),
          const SizedBox(height: 24),
          _buildSectionHeader("Quick Missions", "", ""),
          const SizedBox(height: 16),
          _buildQuickMissionsGrid(),
        ],
      ),
    );
  }

  Widget _buildWeeklyMissions(List<Map<String, dynamic>> completedMissions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Completed Missions", "", ""),
          const SizedBox(height: 16),
          if (completedMissions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No completed missions yet.\nFinish daily missions to see them here!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...completedMissions.map((mission) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMissionCard(
                  missionId: mission['id'].toString(),
                  icon: _iconForMission(mission['icon']),
                  title: mission['title'] as String? ?? 'Mission',
                  progress: (mission['total'] as num?)?.toInt() ?? 1,
                  total: (mission['total'] as num?)?.toInt() ?? 1,
                  reward: (mission['reward'] as num?)?.toInt() ?? 0,
                  isCompleted: true,
                  isClaimed: mission['claimed'] == true,
                  badge: mission['badge'] as String? ?? 'DAILY',
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _iconForMission(Object? iconValue) {
    if (iconValue is IconData) {
      return iconValue;
    }
    if (iconValue is! String) {
      return Icons.assignment;
    }
    switch (iconValue.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      case 'math':
        return Icons.calculate;
      case 'sports':
        return Icons.sports;
      case 'arts':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'technology':
        return Icons.computer;
      case 'trophy':
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildSectionHeader(
      String title, String subtitle, String refreshTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (refreshTime.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8500).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8500).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time,
                      color: Color(0xFFFF8500), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    refreshTime,
                    style: const TextStyle(
                      color: Color(0xFFFF8500),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required String missionId,
    required IconData icon,
    required String title,
    required int progress,
    required int total,
    required int reward,
    required bool isCompleted,
    required bool isClaimed,
    required String badge,
  }) {
    final progressValue = (progress / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color(0xFF52B788).withValues(alpha: 0.3),
                  const Color(0xFF40916C).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFF2C2C54).withValues(alpha: 0.8),
                  const Color(0xFF1B1B2F).withValues(alpha: 0.6),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF52B788).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : const Color(0xFF74C0FC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeColor(badge).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getBadgeColor(badge).withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: _getBadgeColor(badge),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? const Color(0xFF52B788)
                                : const Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$progress / $total",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (isCompleted)
                ElevatedButton(
                  onPressed: isClaimed
                      ? null
                      : () async {
                          await ref
                              .read(missionActionsProvider)
                              .claimMission(missionId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.55),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isClaimed ? "Claimed" : "Claim",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFD60A), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "x$reward",
                        style: const TextStyle(
                          color: Color(0xFFFFD60A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMissionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildQuickMissionCard(
          icon: Icons.flash_on,
          title: "Energy Boost",
          reward: 500,
          currency: "coins",
          isAvailable: true,
          backgroundColor: const Color(0xFF6C5CE7),
        ),
        _buildQuickMissionCard(
          icon: Icons.shield,
          title: "Defense Up",
          reward: 500,
          currency: "coins",
          isAvailable: true,
          backgroundColor: const Color(0xFF74C0FC),
        ),
        _buildQuickMissionCard(
          icon: Icons.speed,
          title: "Speed Boost",
          reward: 500,
          currency: "coins",
          isAvailable: true,
          backgroundColor: const Color(0xFFFF8500),
        ),
        _buildQuickMissionCard(
          icon: Icons.auto_awesome,
          title: "Lucky Draw",
          reward: 3000,
          currency: "coins",
          isAvailable: true,
          backgroundColor: const Color(0xFF52B788),
        ),
        _buildQuickMissionCard(
          icon: Icons.star_border,
          title: "Rare Pack",
          reward: 4500,
          currency: "coins",
          isAvailable: false,
          backgroundColor: const Color(0xFFE74C3C),
        ),
        _buildQuickMissionCard(
          icon: Icons.diamond,
          title: "Premium Pack",
          reward: 15000,
          currency: "coins",
          isAvailable: false,
          backgroundColor: const Color(0xFF9B59B6),
        ),
      ],
    );
  }

  Widget _buildQuickMissionCard({
    required IconData icon,
    required String title,
    required int reward,
    required String currency,
    required bool isAvailable,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor.withValues(alpha: 0.8),
            backgroundColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _QuickMissionPatternPainter(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "1",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currency == "coins"
                            ? Icons.monetization_on
                            : Icons.star,
                        color: currency == "coins"
                            ? const Color(0xFFFFD60A)
                            : Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$reward",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Unavailable overlay
          if (!isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'daily':
        return const Color(0xFF74C0FC);
      case 'weekly':
        return const Color(0xFFFFB366);
      default:
        return const Color(0xFFADB5BD);
    }
  }
}

class _QuickMissionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle geometric pattern
    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.7 + (i * 8),
        -10 + (i * 15),
        20,
        20,
      );
      canvas.drawOval(rect, paint);
    }

    for (int i = 0; i < 2; i++) {
      final rect = Rect.fromLTWH(
        -10 + (i * 20),
        size.height * 0.6 + (i * 10),
        15,
        15,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
