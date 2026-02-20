import 'package:flutter/material.dart';
import '../models/avatar_enums.dart';

/// Modern status indicator with gradient and animations
class AvatarStatusIndicator extends StatefulWidget {
  final AvatarStatus status;
  final double avatarRadius;
  final bool animated;

  const AvatarStatusIndicator({
    super.key,
    required this.status,
    required this.avatarRadius,
    this.animated = true,
  });

  @override
  State<AvatarStatusIndicator> createState() => _AvatarStatusIndicatorState();
}

class _AvatarStatusIndicatorState extends State<AvatarStatusIndicator>
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animated && widget.status == AvatarStatus.online) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AvatarStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == AvatarStatus.online && widget.animated) {
      _pulseController.repeat(reverse: true);
    } else {
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
    final size = widget.avatarRadius * 0.35;
    final borderWidth = widget.avatarRadius * 0.08;
    final icon = widget.status.getIcon();
    final gradientColors = widget.status.getGradientColors();

    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null
          ? Icon(
        icon,
        size: size * 0.5,
        color: Colors.white,
      )
          : null,
    );

    // Add pulse animation for online status
    if (widget.animated && widget.status == AvatarStatus.online) {
      indicator = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width: size * _pulseAnimation.value,
                height: size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gradientColors.first.withOpacity(
                      0.5 * (1 - (_pulseAnimation.value - 1) / 0.3),
                    ),
                    width: 2,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: indicator,
      );
    }

    return indicator;
  }
}
