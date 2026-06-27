import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/widget_helper.dart';
import '../../core/services/weekly_rewards_api_client.dart';
import '../../game/providers/phase2_reward_providers.dart';

class WeeklyRewardsScreen extends ConsumerWidget {
  const WeeklyRewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(weeklyScheduleProvider);
    final streakAsync = ref.watch(weeklyStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Rewards'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return Future.wait([
            ref.refresh(weeklyScheduleProvider.future),
            ref.refresh(weeklyStreakProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Weekly Rewards Calendar
                scheduleAsync.when(
                  data: (schedule) => streakAsync.when(
                    data: (streak) => _WeeklyCalendar(
                      schedule: schedule,
                      streak: streak,
                    ),
                    loading: () => const _WeeklyCalendarSkeleton(),
                    error: (error, stackTrace) => _ErrorState(
                      error: error.toString(),
                      onRetry: () {
                        ref.refresh(weeklyStreakProvider);
                      },
                    ),
                  ),
                  loading: () => const _WeeklyCalendarSkeleton(),
                  error: (error, stackTrace) => _ErrorState(
                    error: error.toString(),
                    onRetry: () {
                      ref.refresh(weeklyScheduleProvider);
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Streak Information
                streakAsync.when(
                  data: (streak) => _StreakBanner(streak: streak),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Week Reset Info
                streakAsync.when(
                  data: (streak) => _WeekResetInfo(resetDate: streak.weekResetDate),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyCalendar extends ConsumerWidget {
  final List<WeeklyRewardDay> schedule;
  final WeeklyStreakStatus streak;

  const _WeeklyCalendar({
    required this.schedule,
    required this.streak,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Calendar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final day = schedule[index];
            final isCurrentDay = streak.currentDay == day.day;
            final isClaimed = day.claimed ?? false;
            final canClaim = isCurrentDay && !isClaimed;

            return _DayCard(
              day: day,
              isCurrentDay: isCurrentDay,
              isClaimed: isClaimed,
              canClaim: canClaim,
            );
          },
        ),
      ],
    );
  }
}

class _DayCard extends ConsumerWidget {
  final WeeklyRewardDay day;
  final bool isCurrentDay;
  final bool isClaimed;
  final bool canClaim;

  const _DayCard({
    required this.day,
    required this.isCurrentDay,
    required this.isClaimed,
    required this.canClaim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: isCurrentDay ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentDay ? Colors.amber : Colors.grey[300]!,
          width: isCurrentDay ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCurrentDay
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    'Day ${day.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCurrentDay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Today',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                children: [
                  // Reward Icon
                  Icon(
                    day.type == 'gems' ? Icons.diamond : Icons.monetization_on,
                    size: 32,
                    color: day.type == 'gems' ? Colors.purple : Colors.green,
                  ),
                  const SizedBox(height: 4),
                  // Reward Amount
                  Text(
                    day.type == 'gems'
                        ? '${day.gemsAmount}'
                        : '${day.coinsAmount}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    day.type == 'gems' ? 'Gems' : 'Coins',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Status Indicator
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Claimed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (canClaim)
                _ClaimButton(day: day)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Locked',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimButton extends ConsumerWidget {
  final WeeklyRewardDay day;

  const _ClaimButton({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(weeklyClaimProvider);

    return claimAsync.when(
      data: (_) => SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              await ref.read(weeklyClaimProvider.future);
              if (context.mounted) {
                showSuccessToast(
                  context,
                  'Success',
                  'Day ${day.day} reward claimed!',
                );
                ref.refresh(weeklyStreakProvider);
              }
            } catch (e) {
              if (context.mounted) {
                showErrorToast(
                  context,
                  'Error',
                  'Failed to claim: $e',
                );
              }
            }
          },
          icon: const Icon(Icons.card_giftcard, size: 16),
          label: const Text('Claim', style: TextStyle(fontSize: 12)),
        ),
      ),
      loading: () => SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Claiming...', style: TextStyle(fontSize: 12)),
        ),
      ),
      error: (error, _) => SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              await ref.read(weeklyClaimProvider.future);
              if (context.mounted) {
                showSuccessToast(
                  context,
                  'Success',
                  'Day ${day.day} reward claimed!',
                );
                ref.refresh(weeklyStreakProvider);
              }
            } catch (e) {
              if (context.mounted) {
                showErrorToast(
                  context,
                  'Error',
                  'Failed to claim: $e',
                );
              }
            }
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final WeeklyStreakStatus streak;

  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    final progressPercent = (streak.daysClaimedCount / 7) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.indigo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Streak',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${streak.daysClaimedCount}/7 Days',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.purple[700],
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.local_fire_department,
                size: 48,
                color: Colors.orange[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                Colors.purple[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekResetInfo extends StatefulWidget {
  final DateTime resetDate;

  const _WeekResetInfo({required this.resetDate});

  @override
  State<_WeekResetInfo> createState() => _WeekResetInfoState();
}

class _WeekResetInfoState extends State<_WeekResetInfo> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = widget.resetDate.difference(now);

    String getTimeString() {
      if (difference.isNegative) {
        return 'Resetting now...';
      }
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      if (days > 0) {
        return '$days day${days == 1 ? '' : 's'} ${hours}h remaining';
      }
      return '${difference.inHours}h remaining';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Week Resets In',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            getTimeString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCalendarSkeleton extends StatelessWidget {
  const _WeeklyCalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: 7,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
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
