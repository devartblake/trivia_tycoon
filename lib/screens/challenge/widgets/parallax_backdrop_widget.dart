import 'package:flutter/material.dart';

/// Light modern gradient backdrop
class LightModernBackdrop extends StatefulWidget {
  final Duration animationDuration;

  const LightModernBackdrop({
    super.key,
    this.animationDuration = const Duration(seconds: 12),
  });

  @override
  State<LightModernBackdrop> createState() => _LightModernBackdropState();
}

class _LightModernBackdropState extends State<LightModernBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFF8F9FA), // Soft white
                Color(0xFFE9ECEF), // Light gray
                Color(0xFFDEE2E6), // Medium gray
                Color(0xFFF8F9FA), // Back to soft white
              ],
              stops: [
                0.0,
                0.3 + (_animation.value * 0.2),
                0.7 + (_animation.value * 0.1),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
