import 'package:flutter/material.dart';
import 'dart:math' as math;

class SegmentUnlockOverlay extends StatefulWidget {
  final bool isUnlocked;
  final String? unlockRequirement;
  final VoidCallback? onUnlockTap;

  const SegmentUnlockOverlay({
    super.key,
    required this.isUnlocked,
    this.unlockRequirement,
    this.onUnlockTap,
  });

  @override
  State<SegmentUnlockOverlay> createState() => _SegmentUnlockOverlayState();
}

class _SegmentUnlockOverlayState extends State<SegmentUnlockOverlay>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _unlockController;

  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    if (!widget.isUnlocked) {
      _startLockAnimations();
    }
  }

  void _initAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.elasticIn,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeInBack,
    ));
  }

  void _startLockAnimations() {
    _shimmerController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopLockAnimations() {
    _shimmerController.stop();
    _pulseController.stop();
  }

  @override
  void didUpdateWidget(SegmentUnlockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isUnlocked != oldWidget.isUnlocked) {
      if (widget.isUnlocked) {
        _stopLockAnimations();
        _unlockController.forward();
      } else {
        _unlockController.reset();
        _startLockAnimations();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUnlocked && _unlockController.isCompleted) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _opacityAnimation,
        _slideAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 100,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildOverlayContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayContent() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onUnlockTap,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.grey.shade900.withOpacity(0.75),
                Colors.black.withOpacity(0.85),
              ],
            ),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Shimmer effect
              _buildShimmerEffect(),

              // Main content
              _buildMainContent(context),

              // Corner decorations
              _buildCornerDecorations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: ShimmerPainter(
                animation: _shimmerAnimation.value,
                color: Colors.amber.withOpacity(0.15),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon with glow effect
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withOpacity(0.3),
                        Colors.amber.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.amber.shade300,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // LOCKED text
                Text(
                  'LOCKED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade200,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),

                // Unlock requirement
                if (widget.unlockRequirement != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      widget.unlockRequirement!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade100,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerDecorations() {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 8,
          left: 8,
          child: _buildCornerDecoration(),
        ),
        // Top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: Transform.rotate(
            angle: math.pi / 2,
            child: _buildCornerDecoration(),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 8,
          left: 8,
          child: Transform.rotate(
            angle: -math.pi / 2,
            child: _buildCornerDecoration(),
          ),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 8,
          right: 8,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildCornerDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecoration() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value - 0.3,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.amber.withOpacity(0.6),
                  width: 1.5,
                ),
                left: BorderSide(
                  color: Colors.amber.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double animation;
  final Color color;

  ShimmerPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(
        animation * size.width - size.width * 0.5,
        0,
        size.width,
        size.height,
      ));

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ShimmerPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}