import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/tier_definitions.dart';
import '../../core/manager/log_manager.dart';

/// Page for viewing and claiming tier rewards
class TierRewardsPage extends ConsumerStatefulWidget {
  const TierRewardsPage({super.key});

  @override
  ConsumerState<TierRewardsPage> createState() => _TierRewardsPageState();
}

class _TierRewardsPageState extends ConsumerState<TierRewardsPage> {
  bool _isClaimingAll = false;

  @override
  Widget build(BuildContext context) {
    // Mock available rewards - in real app, fetch from provider
    final availableRewards = <TierReward>[
      tierDefinitions[2]?.reward ?? TierReward(coins: 250, gems: 15), // CONTENDER
      tierDefinitions[3]?.reward ?? TierReward(coins: 500, gems: 30), // CHALLENGER
    ];

    final claimedRewards = <(TierDefinition, TierReward, DateTime)>[
      if (tierDefinitions[1] != null)
        (tierDefinitions[1]!, tierDefinitions[1]!.reward, DateTime.now().subtract(const Duration(days: 3))),
      if (tierDefinitions[0] != null)
        (tierDefinitions[0]!, tierDefinitions[0]!.reward, DateTime.now().subtract(const Duration(days: 7))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tier Rewards'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Rewards Section
            Text(
              'Available Rewards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (availableRewards.isEmpty)
              _EmptyStateCard(
                icon: Icons.card_giftcard_outlined,
                message: 'No rewards available yet',
                description: 'Complete tier milestones to earn rewards',
              )
            else
              Column(
                children: [
                  ...availableRewards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reward = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < availableRewards.length - 1 ? 12 : 0,
                      ),
                      child: _RewardClaimCard(
                        reward: reward,
                        onClaim: () => _handleClaimReward(reward),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  _BulkClaimButton(
                    isLoading: _isClaimingAll,
                    onPressed: () => _handleClaimAll(availableRewards),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Claimed Rewards Section
            Text(
              'Claimed Rewards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (claimedRewards.isEmpty)
              _EmptyStateCard(
                icon: Icons.archive_outlined,
                message: 'No claimed rewards yet',
              )
            else
              Column(
                children: [
                  ...claimedRewards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final (tier, reward, claimedDate) = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < claimedRewards.length - 1 ? 12 : 0,
                      ),
                      child: _ClaimedRewardCard(
                        tier: tier,
                        reward: reward,
                        claimedDate: claimedDate,
                      ),
                    );
                  }),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClaimReward(TierReward reward) async {
    LogManager.debug('[TierRewards] Claiming reward: ${reward.badgeName}');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Claim Reward?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reward.coins > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('${reward.coins} Coins'),
                  ],
                ),
              ),
            if (reward.gems > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_outlined, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text('${reward.gems} Gems'),
                  ],
                ),
              ),
            if (reward.badgeName != null)
              Row(
                children: [
                  const Icon(Icons.shield, color: Colors.cyan),
                  const SizedBox(width: 8),
                  Text('Badge: ${reward.badgeName}'),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reward claimed successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleClaimAll(List<TierReward> rewards) async {
    if (rewards.isEmpty) return;

    setState(() => _isClaimingAll = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rewards.length} reward${rewards.length > 1 ? 's' : ''} claimed!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingAll = false);
      }
    }
  }
}

/// Card for claiming a single reward
class _RewardClaimCard extends StatefulWidget {
  final TierReward reward;
  final VoidCallback onClaim;

  const _RewardClaimCard({
    required this.reward,
    required this.onClaim,
  });

  @override
  State<_RewardClaimCard> createState() => _RewardClaimCardState();
}

class _RewardClaimCardState extends State<_RewardClaimCard> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        'Tier Reward',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.reward.badgeName ?? 'Achievement Badge',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.card_giftcard,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.reward.coins > 0)
                  _RewardBadge(
                    icon: Icons.monetization_on,
                    value: widget.reward.coins.toString(),
                    label: 'Coins',
                    color: Colors.amber,
                  ),
                if (widget.reward.gems > 0)
                  _RewardBadge(
                    icon: Icons.diamond_outlined,
                    value: widget.reward.gems.toString(),
                    label: 'Gems',
                    color: Colors.purple,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isClaiming ? null : () async {
                  setState(() => _isClaiming = true);
                  try {
                    widget.onClaim();
                  } finally {
                    if (mounted) {
                      setState(() => _isClaiming = false);
                    }
                  }
                },
                child: _isClaiming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Claim Reward'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual reward badge
class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RewardBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card showing a previously claimed reward
class _ClaimedRewardCard extends StatelessWidget {
  final TierDefinition tier;
  final TierReward reward;
  final DateTime claimedDate;

  const _ClaimedRewardCard({
    required this.tier,
    required this.reward,
    required this.claimedDate,
  });

  @override
  Widget build(BuildContext context) {
    final daysAgo = DateTime.now().difference(claimedDate).inDays;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: tier.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.check_circle,
                color: tier.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Claimed $daysAgo day${daysAgo == 1 ? '' : 's'} ago',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.archive,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulk claim button
class _BulkClaimButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _BulkClaimButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Center(
                    child: Text(
                      'Claim All Rewards',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Empty state card
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? description;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
