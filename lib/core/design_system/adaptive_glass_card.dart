import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A core layout container that morphs its geometry and blur based on [SynaptixMode].
class AdaptiveGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? glowColor;
  final double? borderRadius;
  final bool? showBlur;

  const AdaptiveGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.glowColor,
    this.borderRadius,
    this.showBlur,
  });

  @override
  State<AdaptiveGlassCard> createState() => _AdaptiveGlassCardState();
}

class _AdaptiveGlassCardState extends State<AdaptiveGlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = widget.borderRadius ?? synaptix?.cardRadius ?? 16.0;
    final accent = widget.glowColor ?? synaptix?.accentGlow ?? Colors.cyanAccent;
    
    final shouldBlur = widget.showBlur ?? (synaptix?.useHighEnergyMotion ?? true);
    final blurAmount = synaptix?.useHighEnergyMotion == false ? 25.0 : 12.0;
    final opacity = shouldBlur ? (synaptix?.useSoftCorners == true ? 0.2 : 0.1) : 0.35;

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: widget.child,
    );

    if (shouldBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: content,
        ),
      );
    }

    return Padding(
      padding: widget.margin,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                if (_isHovered && widget.onTap != null)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
