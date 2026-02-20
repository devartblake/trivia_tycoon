import 'package:flutter/material.dart';
import '../models/depth_card_theme.dart';

class ShadowLayer extends StatefulWidget {
  final Widget? child;
  final DepthCardTheme theme;

  /// Optional parallax tilt. Used to slightly offset the shadow for depth.
  final Offset tilt;

  const ShadowLayer({
    super.key,
    this.child,
    required this.theme,
    this.tilt = Offset.zero,
  });

  @override
  State<ShadowLayer> createState() => _ShadowLayerState();
}

class _ShadowLayerState extends State<ShadowLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    if (widget.theme.glowEnabled) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ShadowLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.theme.glowEnabled && widget.theme.glowEnabled) {
      _glowController.repeat(reverse: true);
    } else if (oldWidget.theme.glowEnabled && !widget.theme.glowEnabled) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.child ?? const SizedBox.expand();

    // Shadow offsets track the tilt slightly so the card feels more "lifted".
    final tiltDx = widget.tilt.dx * 4.0;
    final tiltDy = widget.tilt.dy * 4.0;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowStrength = widget.theme.glowEnabled
            ? (0.5 + (_glowAnimation.value * 0.5))
            : widget.theme.elevation;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.theme.shadowColor.withValues(alpha: 0.35 + glowStrength * 0.25),
                blurRadius: widget.theme.elevation + (glowStrength + 8),
                spreadRadius: 1+ ( glowStrength * 2),
                offset: Offset(0 + tiltDx, 8 + tiltDy),
              ),
            ],
          ),
          child: base,
        );
      },
    );
  }
}
