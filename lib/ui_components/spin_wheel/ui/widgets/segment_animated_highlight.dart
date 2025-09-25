import 'package:flutter/material.dart';
import 'dart:math' as math;

class SegmentAnimatedHighlight extends StatefulWidget {
  final bool isActive;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration animationDuration;

  const SegmentAnimatedHighlight({
    super.key,
    required this.isActive,
    this.size = 60,
    this.primaryColor = Colors.amber,
    this.secondaryColor = Colors.white,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<SegmentAnimatedHighlight> createState() => _SegmentAnimatedHighlightState();
}

class _SegmentAnimatedHighlightState extends State<SegmentAnimatedHighlight>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _sparkleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.primaryColor,
      end: widget.secondaryColor,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _waveController.repeat();
    _sparkleController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
    _rotationController.stop();
    _waveController.stop();
    _sparkleController.stop();
  }

  @override
  void didUpdateWidget(SegmentAnimatedHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
        _resetAnimations();
      }
    }
  }

  void _resetAnimations() {
    _pulseController.reset();
    _rotationController.reset();
    _waveController.reset();
    _sparkleController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _opacityAnimation,
        _rotationAnimation,
        _waveAnimation,
        _sparkleAnimation,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave effect
              _buildWaveEffect(),

              // Rotating border rings
              _buildRotatingRings(),

              // Pulse ring
              _buildPulseRing(),

              // Sparkle particles
              _buildSparkleEffect(),

              // Center highlight
              _buildCenterHighlight(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveEffect() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WaveEffectPainter(
            animation: _waveAnimation.value,
            color: widget.primaryColor.withOpacity(0.2),
          ),
        );
      },
    );
  }

  Widget _buildRotatingRings() {
    return Transform.rotate(
      angle: _rotationAnimation.value,
      child: Container(
        width: widget.size * 0.9,
        height: widget.size * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: (_colorAnimation.value ?? widget.primaryColor)
                .withOpacity(_opacityAnimation.value),
            width: 3,
          ),
        ),
        child: Transform.rotate(
          angle: -_rotationAnimation.value * 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.secondaryColor
                    .withOpacity(_opacityAnimation.value * 0.8),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing() {
    return Transform.scale(
      scale: _pulseAnimation.value,
      child: Container(
        width: widget.size * 0.7,
        height: widget.size * 0.7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.primaryColor.withOpacity(_opacityAnimation.value),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(_opacityAnimation.value * 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkleEffect() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: SparklePainter(
        animation: _sparkleAnimation.value,
        primaryColor: widget.primaryColor,
        secondaryColor: widget.secondaryColor,
        opacity: _opacityAnimation.value,
      ),
    );
  }

  Widget _buildCenterHighlight() {
    return Container(
      width: widget.size * 0.3,
      height: widget.size * 0.3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.secondaryColor.withOpacity(_opacityAnimation.value),
            widget.primaryColor.withOpacity(_opacityAnimation.value * 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class WaveEffectPainter extends CustomPainter {
  final double animation;
  final Color color;

  WaveEffectPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw multiple expanding circles
    for (int i = 0; i < 3; i++) {
      final progress = (animation + (i * 0.3)) % 1.0;
      final radius = maxRadius * progress;
      final opacity = 1.0 - progress;

      paint.color = color.withOpacity(opacity * 0.6);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveEffectPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class SparklePainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;
  final double opacity;

  SparklePainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 3;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw sparkle particles
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animation * math.pi * 2);
      final sparkleRadius = radius + (math.sin(animation * math.pi * 4) * 10);

      final sparklePosition = Offset(
        center.dx + sparkleRadius * math.cos(angle),
        center.dy + sparkleRadius * math.sin(angle),
      );

      // Alternate colors for sparkles
      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
          .withOpacity(opacity * (0.5 + 0.5 * math.sin(animation * math.pi * 6)));

      // Draw sparkle as a small star
      _drawStar(canvas, sparklePosition, 3, paint);
    }

    // Draw central burst lines
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;
    paint.color = primaryColor.withOpacity(opacity * 0.8);

    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (animation * math.pi / 2);
      final lineLength = 15 + (5 * math.sin(animation * math.pi * 3));

      final startPoint = Offset(
        center.dx + (radius * 0.3) * math.cos(angle),
        center.dy + (radius * 0.3) * math.sin(angle),
      );

      final endPoint = Offset(
        center.dx + (radius * 0.3 + lineLength) * math.cos(angle),
        center.dy + (radius * 0.3 + lineLength) * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
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
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.opacity != opacity;
  }
}
