import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/wallet_counters_row.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_definition.dart';
import '../../domain/arcade_game_id.dart';
import '../../leaderboards/local_arcade_leaderboard_models.dart';
import '../../leaderboards/local_arcade_leaderboard_service.dart';
import '../../missions/arcade_mission_models.dart';
import '../../providers/arcade_providers.dart';
import 'arcade_game_shell.dart';

class ArcadeHubScreen extends ConsumerWidget {
  const ArcadeHubScreen({super.key});

  // Small helpers to avoid repeating SliverToBoxAdapter everywhere.
  SliverToBoxAdapter _sliverBox(Widget child) => SliverToBoxAdapter(child: child);

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
                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                  label: const Text(
                    'Open Daily Bonus',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          _sliverGap(12),

          // Stats/Achievement Banner
          _sliverBox(_buildStatsBanner(context)),

          // Featured Game Section
          if (games.isNotEmpty) _sliverBox(_buildFeaturedSection(context, games.first)),

          // Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.games_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'All Games',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Game List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final game = games[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildModernGameCard(context, game),
                  );
                },
                childCount: games.length,
              ),
            ),
          ),

          // Arcade Missions Section (already returns SliverToBoxAdapter)
          _buildArcadeMissionsBox(context, ref),

          // Local leaderboards box MUST be sliver-wrapped (it returns a normal widget)
          _sliverBox(_buildLocalLeaderboardsBox(context, ref)),

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

  Widget _buildStatsBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.emoji_events_rounded,
              label: 'High Score',
              value: '12,450',
              color: const Color(0xFFFBBF24),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '7 Days',
              color: const Color(0xFFEF4444),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              label: 'Level',
              value: '24',
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
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

  Widget _buildFeaturedSection(BuildContext context, ArcadeGameDefinition game) {
    return GestureDetector(
      onTap: () => _openDifficultyPicker(context, game),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openDifficultyPicker(context, game),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '⭐ FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          game.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.subtitle,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(game.icon, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernGameCard(BuildContext context, ArcadeGameDefinition game) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDifficultyPicker(context, game),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(game.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: game.supportedDifficulties.take(3).map(_buildDifficultyChip).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(ArcadeDifficulty difficulty) {
    Color color;
    switch (difficulty.label.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        break;
      case 'hard':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6366F1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _openDifficultyPicker(BuildContext context, ArcadeGameDefinition game) async {
    final selected = await showModalBottomSheet<ArcadeDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildModernDifficultyPicker(game),
    );

    if (selected == null) return;

    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArcadeGameShell(game: game, difficulty: selected),
      ),
    );
  }

  void _showLeaderboardSheet(
      BuildContext context,
      LocalArcadeLeaderboardService svc,
      ArcadeGameId gameId,
      String title,
      ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E12),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final all = svc.topForGame(gameId, limit: 25);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title — Local Leaderboard',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (all.isEmpty)
                  Text('No scores recorded yet.', style: TextStyle(color: Colors.white.withOpacity(0.7)))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: all.length,
                      itemBuilder: (_, i) => _LeaderboardRow(rank: i + 1, entry: all[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildModernDifficultyPicker(ArcadeGameDefinition game) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A24), Color(0xFF0E0E12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(game.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Select Difficulty', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...game.supportedDifficulties.map(
                    (difficulty) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDifficultyOption(difficulty),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(ArcadeDifficulty difficulty) {
    Color color;
    IconData icon;
    String description;

    switch (difficulty.label.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        icon = Icons.sentiment_satisfied_rounded;
        description = 'Perfect for beginners';
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        icon = Icons.sentiment_neutral_rounded;
        description = 'A balanced challenge';
        break;
      case 'hard':
        color = const Color(0xFFEF4444);
        icon = Icons.sentiment_very_dissatisfied_rounded;
        description = 'For experienced players';
        break;
      default:
        color = const Color(0xFF6366F1);
        icon = Icons.star_rounded;
        description = 'Test your skills';
    }

    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(difficulty),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          difficulty.label,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.7), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalLeaderboardsBox(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(localArcadeLeaderboardServiceProvider);

    Widget buildGame(ArcadeGameId gameId, String title) {
      final top = svc.topForGame(gameId, limit: 5);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () => _showLeaderboardSheet(context, svc, gameId, title),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (top.isEmpty)
              Text(
                'No scores yet. Play a run to set your first record.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              )
            else
              for (int i = 0; i < top.length; i++) _LeaderboardRow(rank: i + 1, entry: top[i]),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Scores (Local)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 10),
          buildGame(ArcadeGameId.patternSprint, 'Pattern Sprint'),
          buildGame(ArcadeGameId.memoryFlip, 'Memory Flip'),
          buildGame(ArcadeGameId.quickMathRush, 'Quick Math Rush'),
        ],
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

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LocalArcadeScoreEntry entry;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final secs = (entry.durationMs / 1000).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${entry.score} pts',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${entry.difficulty.name.toUpperCase()} • ${secs}s',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
