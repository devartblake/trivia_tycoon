import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Enhanced CoinGainAnimation with modern effects and customization
class CoinGainAnimation extends StatefulWidget {
  final int amount;
  final Offset startOffset;
  final Color? color;
  final Duration duration;
  final double fontSize;
  final bool enableParticles;
  final bool enableHaptics;
  final VoidCallback? onComplete;

  const CoinGainAnimation({
    super.key,
    required this.amount,
    this.startOffset = const Offset(0, 0),
    this.color,
    this.duration = const Duration(milliseconds: 1200),
    this.fontSize = 24,
    this.enableParticles = true,
    this.enableHaptics = true,
    this.onComplete,
  });

  @override
  State<CoinGainAnimation> createState() => _CoinGainAnimationState();
}

class _CoinGainAnimationState extends State<CoinGainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _particleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _particleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.8).round()),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.startOffset,
      end: widget.startOffset.translate(0, -2.5),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
    ))..addListener(() {
      if (_fadeAnimation.value >= 0.95) {
        _fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ));
      }
    });

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.color ?? Colors.amber,
      end: (widget.color ?? Colors.amber).withOpacity(0.6),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimation() async {
    // Start bounce effect
    _bounceController.forward();

    // Start particle animation
    if (widget.enableParticles) {
      _particleController.forward();
    }

    // Start main animation after brief delay
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await _mainController.forward();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _bounceController,
        _particleController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value.dx,
            _slideAnimation.value.dy,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particle effects
                  if (widget.enableParticles) _buildParticleEffect(),

                  // Glow effect
                  _buildGlowEffect(),

                  // Main coin gain text
                  _buildMainText(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleEffect() {
    return CustomPaint(
      size: Size(widget.fontSize * 3, widget.fontSize * 3),
      painter: CoinParticlePainter(
        animation: _particleAnimation.value,
        color: widget.color ?? Colors.amber,
        particleCount: _getParticleCount(),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      padding: EdgeInsets.all(widget.fontSize * 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.fontSize),
        boxShadow: [
          BoxShadow(
            color: (_colorAnimation.value ?? Colors.amber).withOpacity(0.3),
            blurRadius: widget.fontSize * 0.8,
            spreadRadius: widget.fontSize * 0.2,
          ),
        ],
      ),
    );
  }

  Widget _buildMainText() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.fontSize * 0.4,
              vertical: widget.fontSize * 0.2,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.fontSize * 0.6),
              border: Border.all(
                color: (widget.color ?? Colors.amber).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle,
                  color: widget.color ?? Colors.amber,
                  size: widget.fontSize * 0.8,
                ),
                SizedBox(width: widget.fontSize * 0.2),
                Text(
                  _formatAmount(widget.amount),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    color: widget.color ?? Colors.amber,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: widget.fontSize * 0.1),
                Icon(
                  Icons.monetization_on,
                  color: widget.color ?? Colors.amber,
                  size: widget.fontSize * 0.6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '+${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '+${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '+$amount';
  }

  int _getParticleCount() {
    if (widget.amount >= 1000) return 12;
    if (widget.amount >= 100) return 8;
    if (widget.amount >= 10) return 6;
    return 4;
  }
}

class CoinParticlePainter extends CustomPainter {
  final double animation;
  final Color color;
  final int particleCount;

  CoinParticlePainter({
    required this.animation,
    required this.color,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final center = size.center(Offset.zero);
    final maxRadius = size.width / 3;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi / particleCount) + (animation * math.pi);
      final progress = animation;
      final radius = maxRadius * progress;
      final opacity = 1.0 - progress;

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      paint.color = color.withOpacity(opacity * 0.8);

      // Draw coin-like particles
      final particleRadius = 3 + (2 * math.sin(progress * math.pi));
      canvas.drawCircle(Offset(x, y), particleRadius, paint);

      // Draw sparkle effect
      if (i % 2 == 0) {
        _drawSparkle(canvas, Offset(x, y), particleRadius, paint);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final sparkleSize = size * 0.8;

    // Draw cross sparkle
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - sparkleSize, center.dy),
      Offset(center.dx + sparkleSize, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - sparkleSize),
      Offset(center.dx, center.dy + sparkleSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CoinParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Premium coin gain animation with enhanced effects
class PremiumCoinGainAnimation extends StatefulWidget {
  final int amount;
  final Offset startOffset;
  final Color color;
  final Duration duration;
  final double fontSize;
  final bool enableParticles;
  final bool enableHaptics;
  final VoidCallback? onComplete;

  const PremiumCoinGainAnimation({
    super.key,
    required this.amount,
    this.startOffset = const Offset(0, 0),
    this.color = Colors.yellow,
    this.duration = const Duration(milliseconds: 1500),
    this.fontSize = 28,
    this.enableParticles = true,
    this.enableHaptics = true,
    this.onComplete,
  });

  @override
  State<PremiumCoinGainAnimation> createState() => _PremiumCoinGainAnimationState();
}

class _PremiumCoinGainAnimationState extends State<PremiumCoinGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _premiumController;
  late Animation<double> _premiumGlowAnimation;

  @override
  void initState() {
    super.initState();
    _initPremiumAnimations();
  }

  void _initPremiumAnimations() {
    _premiumController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _premiumGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _premiumController,
      curve: Curves.easeInOut,
    ));

    _premiumController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _premiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _premiumGlowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.fontSize),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4 + (0.3 * _premiumGlowAnimation.value)),
                blurRadius: widget.fontSize * (1.0 + _premiumGlowAnimation.value),
                spreadRadius: widget.fontSize * 0.3,
              ),
            ],
          ),
          child: CoinGainAnimation(
            amount: widget.amount,
            startOffset: widget.startOffset,
            color: widget.color,
            duration: widget.duration,
            fontSize: widget.fontSize,
            enableParticles: widget.enableParticles,
            enableHaptics: widget.enableHaptics,
            onComplete: widget.onComplete,
          ),
        );
      },
    );
  }
}