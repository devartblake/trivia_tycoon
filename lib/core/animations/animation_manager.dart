import 'package:flutter/material.dart';

/// Centralized helper methods for common app animations.
class AnimationManager {
  const AnimationManager._();

  static AnimationController createController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimationController(vsync: vsync, duration: duration);
  }

  /// Backward-compatible staggered controller builder.
  ///
  /// Supports both `{baseDurationMs, durationIncrementMs}` and legacy
  /// `{baseDelay, delayIncrement}` naming patterns.
  static List<AnimationController> createStaggeredControllers({
    required TickerProvider vsync,
    required int count,
    int? baseDurationMs,
    int? durationIncrementMs,
    int? baseDelay,
    int? delayIncrement,
  }) {
    final base = baseDurationMs ?? baseDelay ?? 400;
    final inc = durationIncrementMs ?? delayIncrement ?? 50;

    return List.generate(
      count,
      (index) => AnimationController(
        duration: Duration(milliseconds: base + (index * inc)),
        vsync: vsync,
      ),
    );
  }

  /// Backward-compatible staggered starter.
  ///
  /// Supports both `{baseDelayMs, delayIncrementMs}` and legacy
  /// `{baseDelay, delayIncrement}` naming patterns.
  static void startStaggered({
    required List<AnimationController> controllers,
    int? baseDelayMs,
    int? delayIncrementMs,
    int? baseDelay,
    int? delayIncrement,
    required bool mounted,
  }) {
    final base = baseDelayMs ?? baseDelay ?? 200;
    final inc = delayIncrementMs ?? delayIncrement ?? 80;

    for (int i = 0; i < controllers.length; i++) {
      Future.delayed(Duration(milliseconds: base + (i * inc)), () {
        if (mounted) controllers[i].forward();
      });
    }
  }

  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  static Animation<double> fadeIn(
    Animation<double> parent, {
    Curve curve = Curves.easeInOut,
    double begin = 0,
    double end = 1,
  }) {
    return Tween<double>(begin: begin, end: end)
        .animate(CurvedAnimation(parent: parent, curve: curve));
  }

  static Widget fadeSlideIn({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0, 0.3),
    Curve fadeCurve = Curves.easeInOut,
    Curve slideCurve = Curves.easeOutBack,
  }) {
    return FadeTransition(
      opacity: fadeIn(animation, curve: fadeCurve),
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: slideCurve)),
        child: child,
      ),
    );
  }

  static Widget slideFromLeft({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeOutBack,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    double minScale = 0.8,
    double maxScale = 1.0,
  }) {
    return _PulseAnimation(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  static List<double> typingDots(double value, {int count = 3}) {
    return List<double>.generate(count, (index) {
      final delayed = (value + (index * 0.2)) % 1.0;
      if (delayed < 0.4) return 0.3 + (delayed / 0.4) * 0.7;
      if (delayed < 0.6) return 1.0;
      return 1.0 - ((delayed - 0.6) / 0.4) * 0.7;
    });
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
