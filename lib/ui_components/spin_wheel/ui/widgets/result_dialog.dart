import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/animations/reward_glow_animation.dart';
import '../../models/spin_system_models.dart';
import 'coin/coin_balance_display.dart';
import 'coin/coin_gain_animation.dart';
import 'dart:math' as math;

class ResultDialog extends StatefulWidget {
  final SpinResult result;
  final VoidCallback? onClaim;
  final VoidCallback? onShare;

  const ResultDialog({
    required this.result,
    super.key,
    this.onClaim,
    this.onShare,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _celebrationController;
  late AnimationController _coinController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntranceAnimation();
    _triggerHapticFeedback();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getRewardColor(),
      end: _getRewardColor().withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startEntranceAnimation() async {
    setState(() => _isVisible = true);

    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _celebrationController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 500));
    _coinController.forward();
  }

  void _triggerHapticFeedback() {
    HapticFeedback.heavyImpact();

    // Additional celebration feedback after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  Color _getRewardColor() {
    switch (widget.result.rewardType?.toLowerCase()) {
      case 'coins':
      case 'currency':
        return Colors.amber;
      case 'gems':
      case 'premium':
        return Colors.purple;
      case 'rare':
        return Colors.orange;
      case 'legendary':
        return Colors.pink;
      case 'jackpot':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getRewardEmoji() {
    switch (widget.result.rewardType?.toLowerCase()) {
      case 'coins':
      case 'currency':
        return '🪙';
      case 'gems':
      case 'premium':
        return '💎';
      case 'rare':
        return '✨';
      case 'legendary':
        return '🌟';
      case 'jackpot':
        return '🎉';
      default:
        return '🎁';
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _celebrationController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _slideAnimation,
            _celebrationAnimation,
            _bounceAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildDialogContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogContent() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          _buildRewardContent(),
          _buildCoinSection(),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRewardColor(),
            _getRewardColor().withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          _buildHeaderBackground(),

          // Main content
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Text(
                          _getRewardEmoji(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Congratulations!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You won an amazing reward!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: CelebrationPainter(
            animation: _celebrationAnimation.value,
            color: Colors.white.withOpacity(0.2),
          ),
          size: const Size(double.infinity, 120),
        );
      },
    );
  }

  Widget _buildRewardContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Reward image with glow effect
          if (widget.result.imagePath != null)
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getRewardColor().withOpacity(0.3),
                          _getRewardColor().withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: RewardGlowAnimation(
                        trigger: true,
                        child: ClipOval(
                          child: Image.asset(
                            widget.result.imagePath!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _getRewardColor(),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 20),

          // Reward label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRewardColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRewardColor().withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.result.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getRewardColor(),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Reward description
          if (widget.result.description != null)
            Text(
              widget.result.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildCoinSection() {
    if (widget.result.reward <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.amber.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: AnimatedBuilder(
        animation: _coinController,
        builder: (context, child) {
          return Row(
            children: [
              Expanded(
                child: const CoinBalanceDisplay(),
              ),
              Transform.scale(
                scale: 1.0 + (0.2 * _coinController.value),
                child: CoinGainAnimation(amount: widget.result.reward),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Primary action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onClaim?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getRewardColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard),
                  const SizedBox(width: 8),
                  Text(
                    'Claim Reward',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary actions row
          Row(
            children: [
              // Share button
              if (widget.onShare != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onShare?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getRewardColor(),
                      side: BorderSide(color: _getRewardColor()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.share, size: 18),
                    label: Text('Share'),
                  ),
                ),

              if (widget.onShare != null) const SizedBox(width: 12),

              // Close button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CelebrationPainter extends CustomPainter {
  final double animation;
  final Color color;

  CelebrationPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final progress = (animation + (i * 0.1)) % 1.0;
      final x = (i / 15) * size.width;
      final y = size.height * (1 - progress);
      final radius = 2 + (2 * math.sin(progress * math.pi));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw celebration lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animation * math.pi);
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final length = 30 + (10 * math.sin(animation * math.pi * 2));

      final startX = centerX + (20 * math.cos(angle));
      final startY = centerY + (20 * math.sin(angle));
      final endX = centerX + ((20 + length) * math.cos(angle));
      final endY = centerY + ((20 + length) * math.sin(angle));

      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
