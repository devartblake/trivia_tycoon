import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/widget_helper.dart';
import '../../core/services/daily_bonus_api_client.dart';
import '../../game/providers/phase2_reward_providers.dart';

class DailyBonusScreen extends ConsumerWidget {
  const DailyBonusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the daily bonus status and config
    final statusAsync = ref.watch(dailyBonusStatusProvider);
    final configAsync = ref.watch(dailyBonusConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Bonus'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both status and config
          await Future.wait([
            ref.refresh(dailyBonusStatusProvider.future),
            ref.refresh(dailyBonusConfigProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Daily Bonus Card
                statusAsync.when(
                  data: (status) => configAsync.when(
                    data: (config) => _DailyBonusCard(
                      status: status,
                      config: config,
                    ),
                    loading: () => const _DailyBonusSkeleton(),
                    error: (error, stackTrace) => _ErrorState(
                      error: error.toString(),
                      onRetry: () {
                        unawaited(ref.refresh(dailyBonusConfigProvider.future));
                      },
                    ),
                  ),
                  loading: () => const _DailyBonusSkeleton(),
                  error: (error, stackTrace) => _ErrorState(
                    error: error.toString(),
                    onRetry: () {
                      unawaited(ref.refresh(dailyBonusStatusProvider.future));
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Streak Information
                statusAsync.when(
                  data: (status) => _StreakInfo(streak: status.currentStreak),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Next Claim Time
                statusAsync.when(
                  data: (status) => status.nextDailyClaimAt != null
                      ? _NextClaimTime(nextClaimAt: status.nextDailyClaimAt!)
                      : const SizedBox.shrink(),
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

class _DailyBonusCard extends ConsumerWidget {
  final AccountRewardStatus status;
  final DailyRewardConfig config;

  const _DailyBonusCard({
    required this.status,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClaimed = status.claimedToday;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Reward Icon/Display
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.card_giftcard,
                  size: 48,
                  color: Colors.amber[700],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reward Amount
            Text(
              '${config.coinsAmount} Coins',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            if (config.gemsAmount != null && config.gemsAmount! > 0)
              Text(
                '+ ${config.gemsAmount} Gems',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.purple[600],
                      fontWeight: FontWeight.w600,
                    ),
              ),

            const SizedBox(height: 24),

            // Claim Button
            if (!isClaimed)
              _ClaimButton(
                config: config,
                status: status,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Already Claimed Today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends ConsumerWidget {
  final DailyRewardConfig config;
  final AccountRewardStatus status;

  const _ClaimButton({
    required this.config,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(dailyBonusClaimProvider);

    return claimAsync.when(
      data: (result) => _buildClaimButton(
        context,
        ref,
        isLoading: false,
        isError: false,
      ),
      loading: () => _buildClaimButton(
        context,
        ref,
        isLoading: true,
      ),
      error: (error, stackTrace) => _buildClaimButton(
        context,
        ref,
        isLoading: false,
        isError: true,
        errorMessage: error.toString(),
      ),
    );
  }

  Widget _buildClaimButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoading,
    bool isError = false,
    String? errorMessage,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      await ref.read(dailyBonusClaimProvider.future);
                      if (context.mounted) {
                        showSuccessToast(
                          context,
                          'Success',
                          'Claimed ${config.coinsAmount} coins!',
                        );
                        // Refresh status after claim
                        unawaited(ref.refresh(dailyBonusStatusProvider.future));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showErrorToast(
                          context,
                          'Error',
                          'Failed to claim reward: $e',
                        );
                      }
                    }
                  },
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.card_giftcard),
            label: Text(
              isLoading ? 'Claiming...' : 'Claim Daily Bonus',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (isError && errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _StreakInfo extends StatelessWidget {
  final int streak;

  const _StreakInfo({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Current Streak',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$streak ${streak == 1 ? 'day' : 'days'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _NextClaimTime extends StatefulWidget {
  final DateTime nextClaimAt;

  const _NextClaimTime({required this.nextClaimAt});

  @override
  State<_NextClaimTime> createState() => _NextClaimTimeState();
}

class _NextClaimTimeState extends State<_NextClaimTime> {
  late DateTime _nextClaimAt;

  @override
  void initState() {
    super.initState();
    _nextClaimAt = widget.nextClaimAt;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = _nextClaimAt.difference(now);

    String getTimeString() {
      if (difference.isNegative) {
        return 'Ready to claim!';
      }
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 0) {
        return '$hours hour${hours == 1 ? '' : 's'} ${minutes}m remaining';
      }
      return '${difference.inMinutes}m remaining';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Next Claim Available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            getTimeString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DailyBonusSkeleton extends StatelessWidget {
  const _DailyBonusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Icon skeleton
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            // Amount skeleton
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            // Sub-amount skeleton
            Container(
              width: 100,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 24),
            // Button skeleton
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
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
      elevation: 4,
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
