import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/daily_bonus_api_client.dart';
import '../../../../game/providers/phase2_reward_providers.dart';

/// Dashboard card displaying daily bonus reward status.
/// Provides quick access to claim daily rewards with streak display.
class Phase2DailyBonusCard extends ConsumerWidget {
  const Phase2DailyBonusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(dailyBonusStatusProvider);
    final configAsync = ref.watch(dailyBonusConfigProvider);

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
              Colors.amber.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: statusAsync.when(
            data: (status) => configAsync.when(
              data: (config) => _DailyBonusContent(
                status: status,
                config: config,
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

class _DailyBonusContent extends ConsumerWidget {
  final AccountRewardStatus status;
  final DailyRewardConfig config;

  const _DailyBonusContent({
    required this.status,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClaimed = status.claimedToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Bonus',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isClaimed ? Colors.grey[300] : Colors.green[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isClaimed ? 'Claimed' : 'Available',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isClaimed ? Colors.grey[700] : Colors.green[700],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Reward Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Coins
            Row(
              children: [
                Icon(Icons.monetization_on, size: 24, color: Colors.green),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coins',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${config.coinsAmount}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Gems (if applicable)
            if (config.gemsAmount != null && config.gemsAmount! > 0)
              Row(
                children: [
                  Icon(Icons.diamond, size: 24, color: Colors.purple),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gems',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${config.gemsAmount}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Streak
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.local_fire_department, size: 24, color: Colors.orange),
                const SizedBox(height: 4),
                Text(
                  '${status.currentStreak}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'days',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isClaimed
                ? null
                : () => context.go('/daily-bonus'),
            icon: const Icon(Icons.card_giftcard),
            label: Text(isClaimed ? 'Come Back Tomorrow' : 'Claim Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
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
          width: 100,
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
            'Failed to load daily bonus',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[600],
            ),
          ),
        ),
      ],
    );
  }
}
