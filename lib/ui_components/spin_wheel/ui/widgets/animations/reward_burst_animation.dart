import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RewardBurstAnimation extends StatelessWidget {
  final Widget child;
  final bool trigger;

  const RewardBurstAnimation({
    super.key,
    required this.child,
    required this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    if (!trigger) return child;

    return Animate(
      effects: [
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        ),
        FadeEffect(begin: 0.0, end: 1.0, duration: 400.ms),
        ScaleEffect(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
        ),
      ],
      child: child,
    );
  }
}