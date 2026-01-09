import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/wallet_counters_row.dart';
import '../../../game/providers/wallet_providers.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_definition.dart';
import '../../providers/arcade_providers.dart';
import 'arcade_game_shell.dart';

class ArcadeHubScreen extends ConsumerWidget {
  const ArcadeHubScreen({super.key});

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

          SliverToBoxAdapter(child: _buildDailyBonusBanner(context, ref)),

          // Stats/Achievement Banner
          SliverToBoxAdapter(
            child: _buildStatsBanner(context),
          ),

          // Featured Game Section (if you want to highlight one)
          if (games.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFeaturedSection(context, games.first),
            ),

          // Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.games_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
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

          // Game Grid/List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
      // Wallet counters in the AppBar
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: WalletCountersRow(compact: true, backplate: true,),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.videogame_asset_rounded,
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
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
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
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '7 Days',
              color: const Color(0xFFEF4444),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
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
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
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
            colors: [
              Color(0xFF10B981), // Green
              Color(0xFF059669), // Emerald
              Color(0xFF047857), // Dark green
            ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      game.icon,
                      color: Colors.white,
                      size: 40,
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

  Widget _buildModernGameCard(BuildContext context, ArcadeGameDefinition game) {
    return Container(
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
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                // Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    game.icon,
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Difficulty badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: game.supportedDifficulties
                            .take(3)
                            .map((difficulty) => _buildDifficultyChip(difficulty))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
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
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _openDifficultyPicker(
      BuildContext context,
      ArcadeGameDefinition game,
      ) async {
    final selected = await showModalBottomSheet<ArcadeDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildModernDifficultyPicker(game),
    );

    if (selected == null) return;

    // Launch through the common shell to standardize rewards & result UX
    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArcadeGameShell(
          game: game,
          difficulty: selected,
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
                const Text(
                  'Daily Bonus',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
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

              // Award daily currency (no XP here)
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
          colors: [
            Color(0xFF1A1A24),
            Color(0xFF0E0E12),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
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
                        const Text(
                          'Select Difficulty',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Difficulty Options
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
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
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
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          difficulty.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.7),
                    size: 18,
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