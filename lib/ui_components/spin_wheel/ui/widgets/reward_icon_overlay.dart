import 'dart:math' as Math;
import 'package:flutter/material.dart';

import '../../models/spin_system_models.dart';

class RewardIconOverlay extends StatefulWidget {
  final WheelSegment segment;
  final bool showAnimation;

  const RewardIconOverlay({
    super.key,
    required this.segment,
    this.showAnimation = true,
  });

  @override
  State<RewardIconOverlay> createState() => _RewardIconOverlayState();
}

class _RewardIconOverlayState extends State<RewardIconOverlay>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _bounceController;

  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    if (widget.showAnimation) {
      _startAnimations();
    }
  }

  void _initAnimations() {
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getRewardColor().withOpacity(0.6),
      end: _getRewardColor(),
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _floatController.repeat(reverse: true);
    _glowController.repeat(reverse: true);

    // Delayed bounce for visual interest
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
      }
    });
  }

  @override
  void didUpdateWidget(RewardIconOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnimation != oldWidget.showAnimation) {
      if (widget.showAnimation) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _stopAnimations() {
    _floatController.stop();
    _glowController.stop();
    _bounceController.stop();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Color _getRewardColor() {
    switch (widget.segment.rewardType.toLowerCase()) {
      case 'coins':
      case 'currency':
        return Colors.amber;
      case 'gems':
      case 'premium':
        return Colors.purple;
      case 'lives':
      case 'health':
        return Colors.red;
      case 'powerup':
      case 'boost':
        return Colors.blue;
      case 'experience':
      case 'xp':
        return Colors.green;
      case 'rare':
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardIcon() {
    switch (widget.segment.rewardType.toLowerCase()) {
      case 'coins':
      case 'currency':
        return Icons.monetization_on;
      case 'gems':
      case 'premium':
        return Icons.diamond;
      case 'lives':
      case 'health':
        return Icons.favorite;
      case 'powerup':
      case 'boost':
        return Icons.flash_on;
      case 'experience':
      case 'xp':
        return Icons.trending_up;
      case 'rare':
      case 'legendary':
        return Icons.auto_awesome;
      case 'mystery':
        return Icons.help_outline;
      case 'jackpot':
        return Icons.stars;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getRewardEmoji() {
    switch (widget.segment.rewardType.toLowerCase()) {
      case 'coins':
      case 'currency':
        return '🪙';
      case 'gems':
      case 'premium':
        return '💎';
      case 'lives':
      case 'health':
        return '❤️';
      case 'powerup':
      case 'boost':
        return '⚡';
      case 'experience':
      case 'xp':
        return '📈';
      case 'rare':
      case 'legendary':
        return '✨';
      case 'mystery':
        return '❓';
      case 'jackpot':
        return '🌟';
      default:
        return '🎁';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      right: 4,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatAnimation,
          _glowAnimation,
          _scaleAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_floatAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      (_colorAnimation.value ?? _getRewardColor()).withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? _getRewardColor())
                          .withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildIconContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconContent() {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Background glow effect
        Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getRewardColor().withOpacity(0.2),
            ),
          ),
        ),
        // Main icon/emoji
        Center(
          child: _shouldUseEmoji()
              ? Text(
            _getRewardEmoji(),
            style: const TextStyle(fontSize: 16),
          )
              : Icon(
            _getRewardIcon(),
            size: 18,
            color: _getRewardColor().computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          ),
        ),
        // Sparkle effect for premium rewards
        if (_isPremiumReward()) _buildSparkleEffect(),
      ],
    );
  }

  bool _shouldUseEmoji() {
    // Use emojis for better visual appeal on certain reward types
    return ['coins', 'currency', 'gems', 'premium', 'lives', 'health',
      'powerup', 'boost', 'experience', 'xp', 'rare', 'legendary',
      'mystery', 'jackpot'].contains(widget.segment.rewardType.toLowerCase());
  }

  bool _isPremiumReward() {
    return ['gems', 'premium', 'rare', 'legendary', 'jackpot']
        .contains(widget.segment.rewardType.toLowerCase());
  }

  Widget _buildSparkleEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return CustomPaint(
            painter: SparklePainter(
              animation: _glowAnimation.value,
              color: _getRewardColor(),
            ),
          );
        },
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final double animation;
  final Color color;

  SparklePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(animation * 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = size.center(Offset.zero);
    final radius = size.width / 3;

    // Draw sparkle lines
    for (int i = 0; i < 4; i++) {
      final angle = (i * 3.14159 / 2) + (animation * 3.14159 / 4);
      final startOffset = Offset(
        center.dx + radius * 0.6 * Math.cos(angle),
        center.dy + radius * 0.6 * Math.sin(angle),
      );
      final endOffset = Offset(
        center.dx + radius * Math.cos(angle),
        center.dy + radius * Math.sin(angle),
      );

      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
