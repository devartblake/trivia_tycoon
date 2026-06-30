import 'package:flutter/material.dart';
import '../../core/services/tier_api_client.dart';

/// Card displaying player's current tier information
class CurrentTierCard extends StatelessWidget {
  final PlayerTierProgress progress;

  const CurrentTierCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final tier = progress.currentTier;
    final isMaxTier = progress.isMaxTier;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Tier',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tier.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level ${tier.level}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTierColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTierColor().withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getTierIcon(),
                    size: 32,
                    color: _getTierColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Rewards breakdown
            _RewardsGrid(reward: tier.rewards),
            if (isMaxTier) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ve reached the maximum tier!',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    if (progress.currentTier.name.contains('Platinum')) return Colors.purple;
    if (progress.currentTier.name.contains('Gold')) return Colors.amber;
    if (progress.currentTier.name.contains('Silver')) return Colors.grey;
    return Colors.brown;
  }

  IconData _getTierIcon() {
    if (progress.currentTier.name.contains('Platinum')) return Icons.diamond;
    if (progress.currentTier.name.contains('Gold')) return Icons.monetization_on;
    if (progress.currentTier.name.contains('Silver')) return Icons.shield;
    return Icons.school;
  }
}

class _RewardsGrid extends StatelessWidget {
  final TierReward reward;

  const _RewardsGrid({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RewardItem(
          icon: Icons.card_giftcard,
          label: 'Badge',
          value: reward.badge,
          color: Colors.blue,
        ),
        _RewardItem(
          icon: Icons.monetization_on,
          label: 'Coins',
          value: reward.coinsBonus.toString(),
          color: Colors.amber,
        ),
        _RewardItem(
          icon: Icons.diamond,
          label: 'Gems',
          value: reward.gemsBonus.toString(),
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
