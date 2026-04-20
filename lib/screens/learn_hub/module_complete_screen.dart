import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/learning_dto.dart';

class ModuleCompleteScreen extends StatelessWidget {
  final String moduleId;
  final ModuleCompleteResponseDto? completionData;

  const ModuleCompleteScreen({
    super.key,
    required this.moduleId,
    required this.completionData,
  });

  @override
  Widget build(BuildContext context) {
    final data = completionData;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  data?.isFirstCompletion ?? true
                      ? Icons.emoji_events
                      : Icons.check_circle_outline,
                  size: 72,
                  color: data?.isFirstCompletion ?? true
                      ? Colors.amber
                      : Colors.green,
                ),
                const SizedBox(height: 20),

                // Headline
                Text(
                  data?.isFirstCompletion ?? true
                      ? 'Module Complete!'
                      : 'Already Completed',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  data?.isFirstCompletion ?? true
                      ? 'Great work! You\'ve earned your rewards.'
                      : 'You\'ve already completed this module. No additional rewards granted.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Rewards card (only meaningful on first completion)
                if (data != null) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          if (data.isFirstCompletion) ...[
                            _RewardRow(
                              icon: Icons.star,
                              iconColor: Colors.amber,
                              label: 'XP Earned',
                              value: '+${data.rewardXp}',
                            ),
                            const SizedBox(height: 12),
                            _RewardRow(
                              icon: Icons.monetization_on,
                              iconColor: Colors.orange,
                              label: 'Coins Earned',
                              value: '+${data.rewardCoins}',
                            ),
                            const Divider(height: 24),
                          ],
                          _RewardRow(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: Colors.blueGrey,
                            label: 'Total XP',
                            value: '${data.balanceXp}',
                          ),
                          const SizedBox(height: 12),
                          _RewardRow(
                            icon: Icons.savings_outlined,
                            iconColor: Colors.blueGrey,
                            label: 'Total Coins',
                            value: '${data.balanceCoins}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/learn-hub'),
                    child: const Text('Back to Hub'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
