import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/arcade_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../../services/arcade_daily_bonus_service.dart';

class DailyBonusScreen extends ConsumerWidget {
  const DailyBonusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonus = ref.watch(arcadeDailyBonusServiceProvider);

    final claimed = bonus.isClaimedToday;
    final streak = bonus.currentStreak;
    final today = bonus.todayReward;
    final tomorrow = bonus.previewTomorrowReward();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar with gradient
          _buildModernAppBar(context),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Banner
                  _buildStreakBanner(streak),

                  const SizedBox(height: 24),

                  // Main Claim Card (Featured)
                  _buildMainClaimCard(
                    context,
                    ref,
                    claimed: claimed,
                    today: today,
                    streak: streak,
                    bonus: bonus,
                  ),

                  const SizedBox(height: 24),

                  // Week Progress Calendar
                  _buildWeekProgressCalendar(streak),

                  const SizedBox(height: 24),

                  // Rewards Progression
                  _buildRewardsProgression(today, tomorrow, streak),

                  const SizedBox(height: 24),

                  // Info Cards Row
                  _buildInfoCardsRow(tomorrow),

                  const SizedBox(height: 24),

                  // Rules Card
                  _buildModernRulesCard(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFBBF24), // Yellow
                Color(0xFFF59E0B), // Amber
                Color(0xFFEF4444), // Red-orange
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
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
                              'Daily Bonus',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Claim your rewards every day',
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
            color: Colors.white.withOpacity(0.2),
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

  Widget _buildStreakBanner(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.2),
            const Color(0xFFF59E0B).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      streak == 1 ? 'day' : 'days',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (streak >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${(streak / 7).floor()}W',
                    style: const TextStyle(
                      color: Colors.white,
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

  Widget _buildMainClaimCard(
      BuildContext context,
      WidgetRef ref, {
        required bool claimed,
        required DailyBonusReward today,
        required int streak,
        required dynamic bonus,
      }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: claimed
              ? [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ]
              : [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: claimed
            ? []
            : [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: claimed
              ? null
              : () => _handleClaim(context, ref, bonus, today),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        claimed ? 'CLAIMED TODAY' : 'AVAILABLE NOW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  claimed ? 'Come Back Tomorrow!' : 'Today\'s Reward',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Rewards Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRewardChip(
                      icon: Icons.monetization_on_rounded,
                      value: '+${today.coins}',
                      label: 'Coins',
                      color: const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 12),
                    _buildRewardChip(
                      icon: Icons.diamond_rounded,
                      value: '+${today.gems}',
                      label: 'Gems',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Claim Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: claimed
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: claimed
                        ? []
                        : [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: claimed
                          ? null
                          : () => _handleClaim(context, ref, bonus, today),
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              claimed
                                  ? Icons.check_circle_rounded
                                  : Icons.card_giftcard_rounded,
                              color: claimed ? Colors.white60 : const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              claimed ? 'Already Claimed' : 'Claim Reward',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: claimed ? Colors.white60 : const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekProgressCalendar(int streak) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayNum = index + 1;
            final isCompleted = dayNum <= (streak % 7 == 0 ? 7 : streak % 7);
            final isToday = dayNum == (streak % 7 == 0 ? 7 : streak % 7);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 6 ? 8 : 0,
                ),
                child: _buildDayCard(dayNum, isCompleted, isToday),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayCard(int day, bool isCompleted, bool isToday) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isCompleted ? null : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: const Color(0xFFFBBF24), width: 2)
            : Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: isCompleted
            ? [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCompleted)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            )
          else
            Icon(
              Icons.circle_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          const SizedBox(height: 8),
          Text(
            'Day $day',
            style: TextStyle(
              color: isCompleted ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsProgression(
      DailyBonusReward today,
      DailyBonusReward tomorrow,
      int streak,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rewards Progression',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProgressionCard(
                'Today',
                today.coins,
                today.gems,
                true,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressionCard(
                'Tomorrow',
                tomorrow.coins,
                tomorrow.gems,
                false,
                const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressionCard(
      String label,
      int coins,
      int gems,
      bool isToday,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isToday ? Icons.today_rounded : Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFBBF24),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.diamond_rounded,
                color: Color(0xFF8B5CF6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$gems',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsRow(DailyBonusReward tomorrow) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.trending_up_rounded,
            title: 'Keep Streaking',
            subtitle: 'Higher rewards ahead',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer_rounded,
            title: 'Daily Reset',
            subtitle: 'Midnight local time',
            color: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How It Works',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem(
            icon: Icons.check_circle_outline_rounded,
            text: 'Claim your bonus once every day',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            icon: Icons.calendar_month_rounded,
            text: 'Missing a day resets your streak to 0',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            icon: Icons.trending_up_rounded,
            text: 'Rewards increase as your streak grows',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            icon: Icons.stars_rounded,
            text: 'Max streak unlocks the highest rewards',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _handleClaim(
      BuildContext context,
      WidgetRef ref,
      dynamic bonus,
      DailyBonusReward today,
      ) {
    final accepted = bonus.tryClaimToday();
    if (!accepted) return;

    incrementCoins(ref, today.coins);
    incrementGems(ref, today.gems);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Claimed +${today.coins} coins & +${today.gems} gems!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}