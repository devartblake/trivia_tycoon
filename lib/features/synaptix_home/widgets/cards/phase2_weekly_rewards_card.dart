import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/weekly_rewards_api_client.dart';
import '../../../../game/providers/phase2_reward_providers.dart';

/// Dashboard card displaying weekly rewards progress.
/// Shows current week day and streak progress at a glance.
class Phase2WeeklyRewardsCard extends ConsumerWidget {
  const Phase2WeeklyRewardsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(weeklyStreakProvider);
    final scheduleAsync = ref.watch(weeklyScheduleProvider);

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
              Colors.purple.withValues(alpha: 0.1),
              Colors.indigo.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: streakAsync.when(
            data: (streak) => scheduleAsync.when(
              data: (schedule) => _WeeklyRewardsContent(
                streak: streak,
                schedule: schedule,
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

class _WeeklyRewardsContent extends StatelessWidget {
  final WeeklyStreakStatus streak;
  final List<WeeklyRewardDay> schedule;

  const _WeeklyRewardsContent({
    required this.streak,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (streak.daysClaimedCount / 7) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Weekly Rewards',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // Streak Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Days Claimed',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${streak.daysClaimedCount}/7',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            Icon(
              Icons.local_fire_department,
              size: 32,
              color: Colors.orange[400],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressPercent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(Colors.purple[600]),
          ),
        ),

        const SizedBox(height: 12),

        // Mini Calendar (First 3 days)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            3,
            (index) {
              final day = schedule[index];
              final isClaimed = day.claimed ?? false;

              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isClaimed
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isClaimed ? Colors.green : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'D${day.day}',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isClaimed
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                ),
                      ),
                      const SizedBox(height: 4),
                      if (day.type == 'gems')
                        Icon(Icons.diamond, size: 16, color: Colors.purple)
                      else
                        Icon(Icons.monetization_on, size: 16, color: Colors.green),
                      if (isClaimed)
                        Icon(Icons.check_circle, size: 12, color: Colors.green)
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/weekly-rewards'),
            icon: const Icon(Icons.calendar_today),
            label: const Text('View All Days'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
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
          width: 120,
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
            'Failed to load weekly rewards',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[600],
            ),
          ),
        ),
      ],
    );
  }
}
