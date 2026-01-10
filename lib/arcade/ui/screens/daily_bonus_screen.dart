import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/wallet_counters_row.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../../missions/arcade_mission_models.dart';
import '../../providers/arcade_providers.dart';

class DailyBonusScreen extends ConsumerWidget {
  const DailyBonusScreen({super.key});

  // Small helpers to avoid repeating SliverToBoxAdapter everywhere.
  SliverToBoxAdapter _sliverBox(Widget child) =>
      SliverToBoxAdapter(child: child);

  SliverToBoxAdapter _sliverGap([double h = 12]) =>
      SliverToBoxAdapter(child: SizedBox(height: h));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(arcadeRegistryProvider);
    final games = registry.games;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar with gradient
          _buildModernAppBar(context, ref),

          // Daily Bonus Banner
          _sliverBox(_buildDailyBonusBanner(context, ref)),

          // Open Daily Bonus Button (must be wrapped as sliver)
          _sliverBox(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/arcade/daily-bonus'),
                  icon: const Icon(
                      Icons.calendar_month_rounded, color: Colors.white),
                  label: const Text(
                    'Open Daily Bonus',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          _sliverGap(12),

          // Arcade Missions Section (already returns SliverToBoxAdapter)
          _buildArcadeMissionsBox(context, ref),

          _sliverGap(24),
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
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
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
                        child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arcade',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Classic games, epic rewards',
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

  Widget _buildDailyBonusBanner(BuildContext context, WidgetRef ref) {
    final bonus = ref.read(arcadeDailyBonusServiceProvider);
    final claimed = bonus.isClaimedToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.amberAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Bonus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  claimed ? 'Claimed for today.' : 'Claim once per day for extra coins.',
                  style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: claimed
                ? null
                : () {
              final didClaim = bonus.tryClaimToday();
              if (!didClaim) return;

              incrementCoins(ref, 250);
              incrementGems(ref, 2);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Daily bonus claimed: +250 coins, +2 gems')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: claimed ? Colors.white.withOpacity(0.10) : Colors.amber.withOpacity(0.95),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(claimed ? 'Claimed' : 'Claim'),
          ),
        ],
      ),
    );
  }

  Widget _buildArcadeMissionsBox(BuildContext context, WidgetRef ref) {
    final service = ref.watch(arcadeMissionServiceProvider);
    final missions = service.missions;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arcade Missions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 10),
            for (final m in missions)
              _MissionRow(
                mission: m,
                progress: service.progressFor(m.id),
                canClaim: service.canClaim(m.id),
                onClaim: () {
                  // IMPORTANT: service must enforce one-claim-only internally.
                  service.markClaimed(m.id);

                  incrementCoins(ref, m.reward.coins);
                  incrementGems(ref, m.reward.gems);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mission complete! +${m.reward.coins} coins, +${m.reward.gems} gems'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final ArcadeMission mission;
  final ArcadeMissionProgress progress;
  final bool canClaim;
  final VoidCallback onClaim;

  const _MissionRow({
    required this.mission,
    required this.progress,
    required this.canClaim,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (progress.current / mission.target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            mission.subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withOpacity(0.1),
            color: Colors.amberAccent,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${progress.current}/${mission.target}',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: canClaim ? onClaim : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canClaim ? Colors.amberAccent : Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(canClaim ? 'Claim' : 'In Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}