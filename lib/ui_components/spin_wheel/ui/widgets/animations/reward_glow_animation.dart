import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reward animation that adds bounce + glow to any widget when triggered
class RewardGlowAnimation extends StatelessWidget {
  final Widget child;
  final bool trigger;
  final Duration delay;

  const RewardGlowAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (!trigger) return child;

    return child.animate(delay: delay).scale(
      duration: 300.ms,
      curve: Curves.elasticOut,
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.1, 1.1),
    ).then().scale(
      duration: 150.ms,
      curve: Curves.easeInOut,
      begin: const Offset(1.1, 1.1),
      end: const Offset(1.0, 1.0),
    ).then().fadeIn(duration: 150.ms).then().shimmer(
      duration: 500.ms,
      color: Colors.amberAccent,
    );
  }
}