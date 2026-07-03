import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/tier_api_client.dart';
import '../../game/providers/phase2_reward_providers.dart';

class TierProgressWidget extends ConsumerWidget {
  const TierProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final progressAsync = ref.watch(playerTierProgressProvider(userId));
    final defsAsync = ref.watch(tierDefinitionsProvider);

    return progressAsync.when(
      data: (progress) => defsAsync.when(
        data: (definitions) => _TierProgressCard(
          progress: progress,
          definitions: definitions,
        ),
        loading: () => const _TierProgressSkeleton(),
        error: (error, stackTrace) => _TierErrorState(
          error: error.toString(),
          onRetry: () {
            unawaited(ref.refresh(tierDefinitionsProvider.future));
          },
        ),
      ),
      loading: () => const _TierProgressSkeleton(),
      error: (error, stackTrace) => _TierErrorState(
        error: error.toString(),
        onRetry: () {
          final userId = ref.read(currentUserIdProvider);
          unawaited(ref.refresh(playerTierProgressProvider(userId).future));
        },
      ),
    );
  }
}

class _TierProgressCard extends StatelessWidget {
  final PlayerTierProgress progress;
  final List<TierDefinition> definitions;

  const _TierProgressCard({
    required this.progress,
    required this.definitions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getTierColor(progress.currentTier).withValues(alpha: 0.1),
              _getTierColor(progress.currentTier).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Your Tier Progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 24),

              // Current Tier Display
              _CurrentTierSection(
                tier: progress.currentTier,
                xp: progress.currentXp,
              ),

              const SizedBox(height: 24),

              // Progress Bar
              _ProgressBarSection(
                progress: progress,
                isMaxTier: progress.isMaxTier,
              ),

              const SizedBox(height: 24),

              // Tier Rewards
              if (!progress.isMaxTier)
                _NextTierRewardsSection(nextTier: progress.nextTier!)
              else
                _MaxTierSection(currentTier: progress.currentTier),

              const SizedBox(height: 24),

              // Tier Benefits
              _TierBenefitsSection(tier: progress.currentTier),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(TierDefinition tier) {
    final tierIndex = definitions.indexOf(tier);
    const colors = [
      Colors.brown,
      Colors.grey,
      Colors.amber,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.red,
    ];
    return colors[tierIndex.clamp(0, colors.length - 1)];
  }
}

class _CurrentTierSection extends StatelessWidget {
  final TierDefinition tier;
  final int xp;

  const _CurrentTierSection({
    required this.tier,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTierColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Tier Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getTierColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.military_tech,
                    size: 40,
                    color: _getTierColor(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'L${tier.level}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTierColor(),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Tier Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getTierColor(),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total XP: $xp',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    const colors = [
      Colors.brown,
      Colors.grey,
      Colors.amber,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.red,
    ];
    return colors[tier.level.clamp(1, 7) - 1];
  }
}

class _ProgressBarSection extends StatelessWidget {
  final PlayerTierProgress progress;
  final bool isMaxTier;

  const _ProgressBarSection({
    required this.progress,
    required this.isMaxTier,
  });

  @override
  Widget build(BuildContext context) {
    if (isMaxTier) {
      return Center(
        child: Text(
          'Maximum tier reached!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange[600],
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to ${progress.nextTier?.name ?? 'Next Tier'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${progress.progressPercentage}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress Bar with Glow
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.progressPercentage / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(
                  Colors.blue[600],
                ),
              ),
            ),
            // Add glow effect from spin_wheel
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedOpacity(
                  opacity: (progress.progressPercentage / 100) * 0.3,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[600]!.withValues(alpha: 0.5),
                          Colors.blue[400]!.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // XP Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.xpInCurrentTier} / ${progress.currentTier.xpRange} XP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              '${progress.xpNeededForNextTier} XP needed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextTierRewardsSection extends StatelessWidget {
  final TierDefinition nextTier;

  const _NextTierRewardsSection({required this.nextTier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Tier Rewards (${nextTier.name})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 20,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${nextTier.rewards.coinsBonus} Coins',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.diamond,
                      size: 20,
                      color: Colors.purple[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${nextTier.rewards.gemsBonus} Gems',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
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
}

class _MaxTierSection extends StatelessWidget {
  final TierDefinition currentTier;

  const _MaxTierSection({required this.currentTier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            size: 24,
            color: Colors.orange[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Congratulations!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have reached the maximum tier',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierBenefitsSection extends StatelessWidget {
  final TierDefinition tier;

  const _TierBenefitsSection({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier Benefits',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _BenefitRow(
          icon: Icons.monetization_on,
          label: 'Coin Reward',
          value: '${tier.rewards.coinsBonus}',
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _BenefitRow(
          icon: Icons.diamond,
          label: 'Gem Reward',
          value: '${tier.rewards.gemsBonus}',
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        _BenefitRow(
          icon: Icons.card_giftcard,
          label: 'Special Badge',
          value: tier.rewards.badge,
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  const _BenefitRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _TierProgressSkeleton extends StatelessWidget {
  const _TierProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _TierErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Tier Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
