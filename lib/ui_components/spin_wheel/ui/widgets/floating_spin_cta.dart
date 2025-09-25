import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/spin_tracker.dart';
import 'dart:math' as math;

/// Enhanced Floating CTA button with modern design and smart behavior
class FloatingSpinCTA extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final String? customText;
  final IconData? customIcon;
  final Color? primaryColor;
  final Color? secondaryColor;
  final EdgeInsets? margin;

  const FloatingSpinCTA({
    super.key,
    required this.onPressed,
    this.customText,
    this.customIcon,
    this.primaryColor,
    this.secondaryColor,
    this.margin,
  });

  @override
  ConsumerState<FloatingSpinCTA> createState() => _FloatingSpinCTAState();
}

class _FloatingSpinCTAState extends ConsumerState<FloatingSpinCTA>
    with TickerProviderStateMixin {
  bool _canSpin = false;
  bool _isVisible = false;
  Timer? _checkTimer;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _rotationController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _bounceAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkSpin();
    _startPeriodicCheck();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.primaryColor ?? Colors.amber,
      end: widget.secondaryColor ?? Colors.orange,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkSpin();
    });
  }

  Future<void> _checkSpin() async {
    try {
      final allowed = await SpinTracker.canSpin();
      if (!mounted) return;

      final wasCanSpin = _canSpin;
      setState(() => _canSpin = allowed);

      if (allowed && !wasCanSpin) {
        _showCTA();
      } else if (!allowed && wasCanSpin) {
        _hideCTA();
      }
    } catch (e) {
      // Handle error silently - don't show CTA if check fails
      debugPrint('Spin check failed: $e');
    }
  }

  void _showCTA() {
    if (!_isVisible) {
      setState(() => _isVisible = true);

      _slideController.forward();
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
      _rotationController.repeat();

      // Haptic feedback to draw attention
      HapticFeedback.lightImpact();
    }
  }

  void _hideCTA() {
    if (_isVisible) {
      _slideController.reverse().then((_) {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });

      _pulseController.stop();
      _glowController.stop();
      _rotationController.stop();
    }
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();

    // Brief scale animation on press
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    widget.onPressed();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canSpin || !_isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      right: 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _slideAnimation,
          _bounceAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: _bounceAnimation.value,
            child: Opacity(
              opacity: _slideAnimation.value,
              child: _buildCTAButton(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCTAButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _glowAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? Colors.amber)
                      .withOpacity(_glowAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handlePress,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _colorAnimation.value ?? Colors.amber,
                        widget.secondaryColor ?? Colors.orange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 12),
                      _buildText(),
                      const SizedBox(width: 8),
                      _buildSparkles(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.customIcon ?? Icons.casino,
              color: Colors.white,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  Widget _buildText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.customText ?? 'Spin Ready!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        Text(
          'Tap to spin now',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(20, 40),
          painter: SparklesPainter(
            animation: _glowAnimation.value,
            color: Colors.white.withOpacity(0.8),
          ),
        );
      },
    );
  }
}

class SparklesPainter extends CustomPainter {
  final double animation;
  final Color color;

  SparklesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw sparkle particles
    for (int i = 0; i < 5; i++) {
      final progress = (animation + (i * 0.2)) % 1.0;
      final x = (i % 2) * size.width * 0.8 + (size.width * 0.1);
      final y = size.height * (1 - progress);
      final radius = 1 + (2 * math.sin(progress * math.pi));
      final opacity = 1.0 - progress;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw sparkle stars
    for (int i = 0; i < 3; i++) {
      final progress = (animation + (i * 0.3)) % 1.0;
      final x = size.width * 0.5 + (20 * math.sin(progress * math.pi * 2));
      final y = size.height * 0.5 + (10 * math.cos(progress * math.pi * 2));
      final opacity = math.sin(progress * math.pi);

      _drawStar(canvas, Offset(x, y), 3, color.withOpacity(opacity));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = (i * math.pi * 2 / 5) - (math.pi / 2);
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Inner point
      final innerAngle = angle + (math.pi / 5);
      final innerSize = size * 0.4;
      final innerX = center.dx + innerSize * math.cos(innerAngle);
      final innerY = center.dy + innerSize * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Enhanced version with additional customization options
class PremiumFloatingSpinCTA extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final String? customText;
  final IconData? customIcon;
  final Color? primaryColor;
  final Color? secondaryColor;
  final EdgeInsets? margin;
  final Duration animationDuration;
  final bool showSparkles;
  final bool enableHaptics;
  final VoidCallback? onLongPress;

  const PremiumFloatingSpinCTA({
    super.key,
    required this.onPressed,
    this.customText,
    this.customIcon,
    this.primaryColor,
    this.secondaryColor,
    this.margin,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.showSparkles = true,
    this.enableHaptics = true,
    this.onLongPress,
  });

  @override
  ConsumerState<PremiumFloatingSpinCTA> createState() => _PremiumFloatingSpinCTAState();
}

class _PremiumFloatingSpinCTAState extends ConsumerState<PremiumFloatingSpinCTA>
    with TickerProviderStateMixin {
  late AnimationController _premiumController;
  late Animation<double> _premiumAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initPremiumAnimations();
  }

  void _initPremiumAnimations() {
    _premiumController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _premiumAnimation = Tween<double>(
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

  void _handlePremiumPress() {
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }

    setState(() => _isPressed = true);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });

    widget.onPressed();
  }

  void _handleLongPress() {
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePremiumPress,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: _premiumAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: (widget.primaryColor ?? Colors.amber)
                        .withOpacity(0.6 + (0.4 * _premiumAnimation.value)),
                    blurRadius: 25 + (10 * _premiumAnimation.value),
                    spreadRadius: 5 + (3 * _premiumAnimation.value),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingSpinCTA(
                onPressed: widget.onPressed,
                customText: widget.customText,
                customIcon: widget.customIcon,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                margin: widget.margin,
              ),
            ),
          );
        },
      ),
    );
  }
}