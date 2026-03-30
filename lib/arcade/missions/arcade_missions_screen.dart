import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/arcade/missions/widgets/mission_details_modal.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/wallet_counters_row.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../providers/arcade_providers.dart';
import 'arcade_mission_models.dart';

class ArcadeMissionsScreen extends ConsumerWidget {
  const ArcadeMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(arcadeMissionServiceProvider);
    final missions = service.missions;

    List<ArcadeMission> byTier(ArcadeMissionTier tier) =>
        missions.where((m) => m.tier == tier).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar with gradient
          _buildModernAppBar(context, ref),

          // Stats Banner
          SliverToBoxAdapter(
            child: _buildStatsBanner(context, ref, service),
          ),

          // Daily Bonus Card (Enhanced)
          SliverToBoxAdapter(
            child: _buildDailyBonusCard(context, ref),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),

          // Mission Sections
          _buildMissionSections(context, ref, service, byTier),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: WalletCountersRow(compact: true, backplate: true),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6366F1), // Indigo
                Color(0xFF8B5CF6), // Purple
                Color(0xFFEC4899), // Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Missions',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Complete challenges, earn rewards',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner(BuildContext context, WidgetRef ref, dynamic service) {
    final totalMissions = service.missions.length;
    final completedToday = service.missions
        .where((m) => m.tier == ArcadeMissionTier.daily && service.progressFor(m.id).claimed)
        .length;
    final dailyMissions = service.missions
        .where((m) => m.tier == ArcadeMissionTier.daily)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.2),
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Today',
              value: '$completedToday/$dailyMissions',
              color: const Color(0xFF10B981),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.emoji_events_rounded,
              label: 'Total',
              value: '$totalMissions',
              color: const Color(0xFFFBBF24),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up_rounded,
              label: 'Active',
              value: '${totalMissions - completedToday}',
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBonusCard(BuildContext context, WidgetRef ref) {
    final bonus = ref.read(arcadeDailyBonusServiceProvider);
    final claimed = bonus.isClaimedToday;
    final streak = bonus.currentStreak;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: claimed
              ? [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ]
              : [
            const Color(0xFFFBBF24),
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: claimed
            ? []
            : [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/arcade/daily-bonus'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Signal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (streak > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        claimed
                            ? 'Come back tomorrow for more rewards'
                            : 'Claim your daily reward now!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionSections(
      BuildContext context,
      WidgetRef ref,
      dynamic service,
      List<ArcadeMission> Function(ArcadeMissionTier) byTier,
      ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMissionSection(
              context,
              ref,
              service,
              'Daily Missions',
              ArcadeMissionTier.daily,
              byTier(ArcadeMissionTier.daily),
              const Color(0xFF10B981),
              Icons.today_rounded,
            ),
            const SizedBox(height: 24),
            _buildMissionSection(
              context,
              ref,
              service,
              'Weekly Missions',
              ArcadeMissionTier.weekly,
              byTier(ArcadeMissionTier.weekly),
              const Color(0xFFF59E0B),
              Icons.calendar_month_rounded,
            ),
            const SizedBox(height: 24),
            _buildMissionSection(
              context,
              ref,
              service,
              'Season Missions',
              ArcadeMissionTier.season,
              byTier(ArcadeMissionTier.season),
              const Color(0xFF6366F1),
              Icons.stars_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSection(
      BuildContext context,
      WidgetRef ref,
      dynamic service,
      String title,
      ArcadeMissionTier tier,
      List<ArcadeMission> missions,
      Color color,
      IconData icon,
      ) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${missions.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Mission Cards
        ...missions.map((mission) => _buildModernMissionCard(
          context,
          ref,
          service,
          mission,
          color,
        )),
      ],
    );
  }

  Widget _buildModernMissionCard(
      BuildContext context,
      WidgetRef ref,
      dynamic service,
      ArcadeMission mission,
      Color tierColor,
      ) {
    final progress = service.progressFor(mission.id);
    final canClaim = service.canClaim(mission.id);
    final ratio = (progress.current / mission.target).clamp(0.0, 1.0);
    final claimed = progress.claimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canClaim
              ? tierColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: canClaim ? 2 : 1,
        ),
        boxShadow: canClaim
            ? [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => MissionDetailsModal.show(
            context,
            ref: ref,
            mission: mission,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Mission Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tierColor,
                            tierColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        claimed
                            ? Icons.check_circle_rounded
                            : Icons.flag_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mission.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Info Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Section
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${progress.current}/${mission.target}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(ratio * 100).toInt()}%',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tierColor, tierColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rewards & Button Row
                Row(
                  children: [
                    // Rewards Display
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRewardChip(
                            Icons.monetization_on_rounded,
                            '+${mission.reward.coins}',
                            const Color(0xFFFBBF24),
                          ),
                          _buildRewardChip(
                            Icons.diamond_rounded,
                            '+${mission.reward.gems}',
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Claim Button
                    _buildClaimButton(
                      context,
                      ref,
                      service,
                      mission,
                      canClaim,
                      claimed,
                      tierColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(
      BuildContext context,
      WidgetRef ref,
      dynamic service,
      ArcadeMission mission,
      bool canClaim,
      bool claimed,
      Color tierColor,
      ) {
    String buttonText;
    Color buttonColor;
    Color textColor;

    if (claimed) {
      buttonText = 'Claimed';
      buttonColor = Colors.white.withValues(alpha: 0.1);
      textColor = Colors.white60;
    } else if (canClaim) {
      buttonText = 'Claim';
      buttonColor = tierColor;
      textColor = Colors.white;
    } else {
      buttonText = 'Locked';
      buttonColor = Colors.white.withValues(alpha: 0.1);
      textColor = Colors.white60;
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: canClaim && !claimed
            ? LinearGradient(
          colors: [tierColor, tierColor.withValues(alpha: 0.8)],
        )
            : null,
        color: !canClaim || claimed ? buttonColor : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: canClaim && !claimed
            ? [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canClaim && !claimed
              ? () {
            final accepted = service.tryClaim(mission.id);
            if (!accepted) return;

            incrementCoins(ref, mission.reward.coins);
            incrementGems(ref, mission.reward.gems);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Claimed +${mission.reward.coins} coins & +${mission.reward.gems} gems!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (claimed)
                  Icon(
                    Icons.check_circle_rounded,
                    color: textColor,
                    size: 16,
                  )
                else if (canClaim)
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: textColor,
                    size: 16,
                  )
                else
                  Icon(
                    Icons.lock_rounded,
                    color: textColor,
                    size: 16,
                  ),
                const SizedBox(width: 6),
                Text(
                  buttonText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}