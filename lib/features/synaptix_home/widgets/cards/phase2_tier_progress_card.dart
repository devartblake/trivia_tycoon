import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/tier_api_client.dart';
import '../../../../game/providers/phase2_reward_providers.dart';

/// Dashboard card displaying player tier progress.
/// Shows current tier and progress towards next tier.
class Phase2TierProgressCard extends ConsumerWidget {
  const Phase2TierProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final progressAsync = ref.watch(playerTierProgressProvider(userId));
    final defsAsync = ref.watch(tierDefinitionsProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.cyan.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: progressAsync.when(
            data: (progress) => defsAsync.when(
              data: (definitions) => _TierProgressContent(
                progress: progress,
                definitions: definitions,
              ),
              loading: () => const _LoadingState(),
              error: (_, __) => const _ErrorState(),
            ),
            loading: () => const _LoadingState(),
            error: (_, __) => const _ErrorState(),
          ),
        ),
      ),
    );
  }
}

class _TierProgressContent extends StatelessWidget {
  final PlayerTierProgress progress;
  final List<TierDefinition> definitions;

  const _TierProgressContent({
    required this.progress,
    required this.definitions,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(progress.currentTier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tier Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Icon(
              Icons.military_tech,
              size: 24,
              color: tierColor,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Current Tier
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.currentTier.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                  ),
                  Text(
                    'Level ${progress.currentTier.level}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tierColor,
                        ),
                  ),
                ],
              ),
              Text(
                'L${progress.currentTier.level}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tierColor,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Progress Bar
        if (!progress.isMaxTier)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To ${progress.nextTier?.name ?? 'Next Tier'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${progress.progressPercentage}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Colors.blue[600]),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${progress.xpNeededForNextTier} XP needed',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Maximum tier reached!',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/tier-progress'),
            icon: const Icon(Icons.trending_up),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(TierDefinition tier) {
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 24, color: Colors.red[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Failed to load tier progress',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[600],
                ),
          ),
        ),
      ],
    );
  }
}
