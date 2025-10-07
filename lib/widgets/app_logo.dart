import 'package:flutter/material.dart';
import '../core/constants/image_strings.dart';

/// Main app logo component - works on mobile and web
/// Can be used in splash screens, app bars, and branding sections
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;
  final bool animate;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.textColor,
    this.animate = false,
    this.textStyle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1A1A1A));

    final Widget logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image
        Hero(
          tag: 'app_logo',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              tTriviaGameImage,
              height: size,
              width: size,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Container(
                  height: size,
                  width: size,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: size * 0.6,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),

        // App name
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'Trivia Tycoon',
            style: textStyle ?? TextStyle(
              fontSize: size * 0.24,
              fontWeight: FontWeight.bold,
              color: defaultTextColor,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: size * 0.05),
          Text(
            'Challenge Your Mind',
            style: TextStyle(
              fontSize: size * 0.12,
              color: defaultTextColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: animate ? _AnimatedLogo(child: logo) : logo,
    );
  }
}

/// Animated wrapper for the logo
class _AnimatedLogo extends StatefulWidget {
  final Widget child;

  const _AnimatedLogo({required this.child});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Compact horizontal logo variant for app bars
class AppLogoCompact extends StatelessWidget {
  final double height;
  final Color? textColor;

  const AppLogoCompact({
    super.key,
    this.height = 40,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1A1A1A));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          tTriviaGameImage,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              width: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology,
                size: height * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Trivia Tycoon',
          style: TextStyle(
            fontSize: height * 0.5,
            fontWeight: FontWeight.bold,
            color: defaultTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
