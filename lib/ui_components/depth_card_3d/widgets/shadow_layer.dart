import 'package:flutter/material.dart';
import '../models/depth_card_theme.dart';

class ShadowLayer extends StatefulWidget {
  final Widget child;
  final DepthCardTheme theme;

  const ShadowLayer({super.key, required this.child, required this.theme});

  @override
  State<ShadowLayer> createState() => _ShadowLayerState();
}

class _ShadowLayerState extends State<ShadowLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowStrength = widget.theme.glowEnabled
            ? 4 + (_glowController.value * 8)
            : widget.theme.elevation;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.theme.shadowColor,
                blurRadius: glowStrength,
                spreadRadius: glowStrength / 2,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
