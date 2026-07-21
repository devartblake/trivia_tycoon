import 'package:flutter/material.dart';
import 'package:synaptix/core/services/feedback_service.dart';
import 'package:synaptix/core/services/native_platform_service.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A high-fidelity, metallic button for the Synaptix design system.
class NeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double height;
  final EdgeInsets padding;
  final bool isGlowEnabled;

  const NeonButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.width,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.isGlowEnabled = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      FeedbackService.instance.haptic(NativeHapticPattern.light, context);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = widget.color ?? synaptix?.accentGlow ?? Colors.cyanAccent;
    final isDisabled = widget.onPressed == null;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(synaptix?.cardRadius ?? 16),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.8),
                  accent.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (widget.isGlowEnabled && !isDisabled)
                  BoxShadow(
                    color: accent.withValues(alpha: _isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 20 : 12,
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: synaptix?.headlineFont,
                  letterSpacing: 0.5,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
