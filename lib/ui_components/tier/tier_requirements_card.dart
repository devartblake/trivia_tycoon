import 'package:flutter/material.dart';
import '../../core/services/tier_api_client.dart';

/// Card showing upcoming tier requirements and rewards
class TierRequirementsCard extends StatelessWidget {
  final TierDefinition? nextTier;
  final int xpNeeded;

  const TierRequirementsCard({
    super.key,
    required this.nextTier,
    required this.xpNeeded,
  });

  @override
  Widget build(BuildContext context) {
    if (nextTier == null || xpNeeded <= 0) {
      return const SizedBox.shrink();
    }

    final tier = nextTier!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tier Requirements',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Next tier info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTierIcon(),
                    size: 24,
                    color: _getTierColor(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tier.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Level ${tier.level}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${tier.minXp}+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Requirements list
            ..._buildRequirements(context, tier),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRequirements(BuildContext context, TierDefinition tier) {
    return [
      _RequirementItem(
        icon: Icons.school,
        label: 'Minimum XP Required',
        value: '${tier.minXp} XP',
      ),
      const SizedBox(height: 12),
      _RequirementItem(
        icon: Icons.trending_up,
        label: 'Max XP in Tier',
        value: '${tier.maxXp} XP',
      ),
      const SizedBox(height: 12),
      _RequirementItem(
        icon: Icons.card_giftcard,
        label: 'Badge Reward',
        value: tier.rewards.badge,
      ),
      const SizedBox(height: 12),
      _RequirementItem(
        icon: Icons.monetization_on,
        label: 'Coins Reward',
        value: '${tier.rewards.coinsBonus}',
        color: Colors.amber,
      ),
      const SizedBox(height: 12),
      _RequirementItem(
        icon: Icons.diamond,
        label: 'Gems Reward',
        value: '${tier.rewards.gemsBonus}',
        color: Colors.purple,
      ),
    ];
  }

  Color _getTierColor() {
    if (nextTier!.name.contains('Platinum')) return Colors.purple;
    if (nextTier!.name.contains('Gold')) return Colors.amber;
    if (nextTier!.name.contains('Silver')) return Colors.grey;
    return Colors.brown;
  }

  IconData _getTierIcon() {
    if (nextTier!.name.contains('Platinum')) return Icons.diamond;
    if (nextTier!.name.contains('Gold')) return Icons.monetization_on;
    if (nextTier!.name.contains('Silver')) return Icons.shield;
    return Icons.school;
  }
}

class _RequirementItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _RequirementItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
}
