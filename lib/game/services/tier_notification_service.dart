import 'package:flutter/material.dart';
import '../../core/models/tier_definitions.dart';
import '../../core/manager/log_manager.dart';

/// Service for managing tier-related notifications
class TierNotificationService {
  static void showTierUpNotification(
    BuildContext context, {
    required TierDefinition newTier,
    required TierReward reward,
    VoidCallback? onClose,
  }) {
    LogManager.debug('[TierNotification] Showing tier-up for ${newTier.name}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _TierUpDialog(
        tier: newTier,
        reward: reward,
        onClose: () {
          Navigator.of(dialogContext).pop();
          onClose?.call();
        },
      ),
    );
  }

  static void showTierProgressNotification(
    BuildContext context, {
    required double progressPercentage,
    VoidCallback? onClose,
  }) {
    String message = '';

    if (progressPercentage >= 90) {
      message = 'Almost there! You\'re 90% to the next tier!';
    } else if (progressPercentage >= 75) {
      message = '75% progress to next tier. Keep going!';
    } else if (progressPercentage >= 50) {
      message = 'Halfway to the next tier!';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: onClose ?? () {},
          ),
        ),
      );
    }
  }
}

/// Dialog displayed when player achieves a new tier
class _TierUpDialog extends StatefulWidget {
  final TierDefinition tier;
  final TierReward reward;
  final VoidCallback onClose;

  const _TierUpDialog({
    required this.tier,
    required this.reward,
    required this.onClose,
  });

  @override
  State<_TierUpDialog> createState() => _TierUpDialogState();
}

class _TierUpDialogState extends State<_TierUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.tier.primaryColor.withValues(alpha: 0.95),
                widget.tier.secondaryColor.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.tier.primaryColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tier icon with animation
              _AnimatedTierIcon(
                tier: widget.tier,
              ),
              const SizedBox(height: 24),

              // "Tier Up!" text
              Text(
                'TIER UP!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),

              // Tier name
              Text(
                widget.tier.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),

              // Tier tagline
              Text(
                widget.tier.tagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Rewards section
              _RewardsDisplay(reward: widget.reward),
              const SizedBox(height: 32),

              // Close button
              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.tier.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

/// Animated tier icon
class _AnimatedTierIcon extends StatefulWidget {
  final TierDefinition tier;

  const _AnimatedTierIcon({required this.tier});

  @override
  State<_AnimatedTierIcon> createState() => _AnimatedTierIconState();
}

class _AnimatedTierIconState extends State<_AnimatedTierIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
        child: Icon(
          Icons.emoji_events,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Rewards display section
class _RewardsDisplay extends StatelessWidget {
  final TierReward reward;

  const _RewardsDisplay({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'REWARDS EARNED',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (reward.coins > 0)
              _RewardItem(
                icon: Icons.monetization_on,
                label: 'Coins',
                value: reward.coins.toString(),
                color: Colors.amber,
              ),
            if (reward.gems > 0)
              _RewardItem(
                icon: Icons.diamond_outlined,
                label: 'Gems',
                value: reward.gems.toString(),
                color: Colors.purple,
              ),
            if (reward.badgeName != null)
              _RewardItem(
                icon: Icons.shield,
                label: 'Badge',
                value: reward.badgeName!,
                color: Colors.cyan,
              ),
          ],
        ),
      ],
    );
  }
}

/// Individual reward item
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
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}
