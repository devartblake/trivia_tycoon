import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import '../../../core/helpers/responsive_layout.dart';
import '../../../core/navigation/navigation_extensions.dart';
import 'package:synaptix/arcade/ui/screens/widgets/wallet_counters_row.dart';
import '../../../game/analytics/providers/analytics_providers.dart';
import '../../../synaptix/mode/synaptix_mode_provider.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_definition.dart';
import '../../providers/arcade_providers.dart';
import '../../../game/providers/feature_flag_providers.dart';
import 'package:synaptix/ui_components/spin_wheel/core/sound_manager.dart';

class ArcadeHubScreen extends ConsumerWidget {
  const ArcadeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Synaptix analytics — Labs surface opened
    final mode = ref.read(synaptixModeProvider);
    ref.read(analyticsServiceProvider).trackEvent('synaptix_surface_opened', {
      'surface': 'labs',
      'synaptix_mode': mode.name,
      'entry_point': 'navigation',
      'audience_segment': mode.name,
    });

    final registry = ref.watch(arcadeRegistryProvider);
    final games = registry.games;

    return Hero(
      tag: 'surface_labs',
      child: SynaptixScaffold(
        appBar: GlassAppBar(
          title: const GlowText('Labs'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.safeBack(),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: WalletCountersRow(compact: true, backplate: true),
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
                child: SizedBox(height: kToolbarHeight + 20)),

            // Stats/Achievement Banner
            SliverToBoxAdapter(
              child: AppResponsiveWidth(
                padding: EdgeInsets.zero,
                child: _buildStatsBanner(context),
              ),
            ),

            // Quick Actions Row (3 cards)
            SliverToBoxAdapter(
              child: AppResponsiveWidth(
                padding: EdgeInsets.zero,
                child: _buildQuickActionsRow(context, ref),
              ),
            ),

            // Featured Game Section
            if (games.isNotEmpty)
              SliverToBoxAdapter(
                child: AppResponsiveWidth(
                  padding: EdgeInsets.zero,
                  child: _buildFeaturedSection(context, games.first),
                ),
              ),

            SliverToBoxAdapter(
              child: AppResponsiveWidth(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.games_rounded,
                            color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        GlowText(
                          'All Games',
                          style: TextStyle(
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final game in games)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildModernGameCard(context, game),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner(BuildContext context) {
    return AdaptiveGlassCard(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
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
            color: Colors.white.withValues(alpha: 0.1),
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
            color: Colors.white.withValues(alpha: 0.1),
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
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, WidgetRef ref) {
    final bonus = ref.read(arcadeDailyBonusServiceProvider);
    final claimed = bonus.isClaimedToday;
    final streak = bonus.currentStreak;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowText(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  ref,
                  title: 'Daily Signal',
                  subtitle: claimed ? 'Claimed' : 'Available',
                  icon: Icons.card_giftcard_rounded,
                  gradient: claimed
                      ? [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          const Color(0xFFFBBF24),
                          const Color(0xFFF59E0B),
                        ],
                  badge: streak > 0 ? '🔥$streak' : null,
                  onTap: () => context.push('/arcade/daily-bonus'),
                  hasGlow: !claimed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  ref,
                  title: 'Missions',
                  subtitle: 'Complete',
                  icon: Icons.emoji_events_rounded,
                  gradient: const [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                  onTap: () => context.push('/arcade/missions'),
                  hasGlow: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            ref,
            title: 'Leaderboards',
            subtitle: 'View rankings and compete',
            icon: Icons.leaderboard_rounded,
            gradient: const [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            onTap: () => context.push('/arcade/local-leaderboards'),
            hasGlow: false,
            isFullWidth: true,
          ),
          if (ref.watch(featureFlagsProvider).rewardReactorEnabled) ...[
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              ref,
              title: 'Reward Reactor',
              subtitle: 'Claim your daily reward',
              icon: Icons.flash_on_rounded,
              gradient: const [
                Color(0xFF7C3AED),
                Color(0xFFFFD700),
              ],
              onTap: () => context.push('/rewards/reactor'),
              hasGlow: true,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    String? badge,
    bool hasGlow = false,
    bool isFullWidth = false,
  }) {
    return AdaptiveGlassCard(
      glowColor: gradient.first,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        height: isFullWidth ? 90 : 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withValues(alpha: 0.3)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isFullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        if (badge != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(
      BuildContext context, ArcadeGameDefinition game) {
    return AdaptiveGlassCard(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      glowColor: const Color(0xFF10B981),
      onTap: () {
        soundManager.playButtonClick();
        _openDifficultyPicker(context, game);
      },
      padding: EdgeInsets.zero,
      child: Container(
        height: 180,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0x3310B981),
              Color(0x11059669),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                    GlowText(
                      game.title,
                      style: const TextStyle(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
    );
  }

  Widget _buildModernGameCard(BuildContext context, ArcadeGameDefinition game) {
    return AdaptiveGlassCard(
      onTap: () => _openDifficultyPicker(context, game),
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
                    color: Colors.white.withValues(alpha: 0.7),
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
              color: Colors.white.withValues(alpha: 0.1),
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
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
    if (!context.mounted) return;

    await context
        .push('/arcade/play', extra: {'game': game, 'difficulty': selected});
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
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              soundManager.playUISound('reward');
              Navigator.of(context).pop(difficulty);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
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
                    color: color.withValues(alpha: 0.7),
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
