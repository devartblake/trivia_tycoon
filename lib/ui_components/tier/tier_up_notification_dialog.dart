import 'package:flutter/material.dart';
import '../../core/services/tier_api_client.dart';

/// Celebration dialog when player reaches new tier
class TierUpNotificationDialog extends StatefulWidget {
  final TierDefinition newTier;
  final VoidCallback? onDismiss;

  const TierUpNotificationDialog({
    super.key,
    required this.newTier,
    this.onDismiss,
  });

  @override
  State<TierUpNotificationDialog> createState() =>
      _TierUpNotificationDialogState();
}

class _TierUpNotificationDialogState extends State<TierUpNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getTierColor().withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _getTierIcon(),
                    size: 40,
                    color: _getTierColor(),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Tier Up!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getTierColor(),
                      ),
                ),
                const SizedBox(height: 8),
                // New tier name
                Text(
                  widget.newTier.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Congratulations on reaching Level ${widget.newTier.level}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // Rewards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rewards Unlocked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RewardBadge(
                            icon: Icons.monetization_on,
                            label: 'Coins',
                            value: widget.newTier.rewards.coinsBonus
                                .toString(),
                            color: Colors.amber,
                          ),
                          _RewardBadge(
                            icon: Icons.diamond,
                            label: 'Gems',
                            value: widget.newTier.rewards.gemsBonus
                                .toString(),
                            color: Colors.purple,
                          ),
                          _RewardBadge(
                            icon: Icons.card_giftcard,
                            label: 'Badge',
                            value: '1',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Dismiss button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDismiss?.call();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTierColor(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTierColor() {
    if (widget.newTier.name.contains('Platinum')) return Colors.purple;
    if (widget.newTier.name.contains('Gold')) return Colors.amber;
    if (widget.newTier.name.contains('Silver')) return Colors.grey;
    return Colors.brown;
  }

  IconData _getTierIcon() {
    if (widget.newTier.name.contains('Platinum')) return Icons.diamond;
    if (widget.newTier.name.contains('Gold')) return Icons.monetization_on;
    if (widget.newTier.name.contains('Silver')) return Icons.shield;
    return Icons.school;
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
