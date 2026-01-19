import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/utils/gradient_themes.dart';

/// Modern rewards banner with animations and glass morphism
class RewardsBanner extends ConsumerStatefulWidget {
  final bool dailyRewardsAvailable;
  final String ageGroup;

  const RewardsBanner({
    super.key,
    required this.dailyRewardsAvailable,
    required this.ageGroup,
  });

  @override
  ConsumerState<RewardsBanner> createState() => _RewardsBannerState();
}

class _RewardsBannerState extends ConsumerState<RewardsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.dailyRewardsAvailable) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RewardsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dailyRewardsAvailable && !oldWidget.dailyRewardsAvailable) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.dailyRewardsAvailable &&
        oldWidget.dailyRewardsAvailable) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dailyRewardsAvailable) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _handleRewardTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: GradientThemes.getRewardGradient(widget.ageGroup),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: GradientThemes.getAgeGroupColors(widget.ageGroup)
                    .first
                    .withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              _buildContent(),
              _buildArrow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Rewards Available!',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to claim your rewards',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Future<void> _handleRewardTap() async {
    HapticFeedback.mediumImpact();
    final result = await context.push('/rewards');
    if (result == true && mounted) {
      _claimRewards();
    }
  }

  void _claimRewards() {
    ref.read(dailyRewardsAvailableProvider.notifier).state = false;
    debugPrint('Daily rewards claimed - banner will be hidden');
  }
}
