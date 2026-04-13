import 'dart:async';

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

  static Animation<double> createFadeAnimation({
    required Animation<double> controller,
    Curve curve = Curves.easeInOut,
    double begin = 0,
    double end = 1,
  }) {
    return _buildFadeAnimation(
      controller,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  /// Backward-compatible staggered controller builder.
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

  static dynamic fadeIn({
    Animation<double>? animation,
    Widget? child,
    Duration duration = const Duration(milliseconds: 300),
    int delay = 0,
    Curve curve = Curves.easeInOut,
    double begin = 0,
    double end = 1,
  }) {
    if (child != null) {
      return _ManagedAnimation(
        duration: duration,
        delay: Duration(milliseconds: delay),
        builder: (animation) => FadeTransition(
          opacity: _buildFadeAnimation(
            animation,
            curve: curve,
            begin: begin,
            end: end,
          ),
          child: child,
        ),
      );
    }

    if (animation != null) {
      return _buildFadeAnimation(
        animation,
        curve: curve,
        begin: begin,
        end: end,
      );
    }

    throw ArgumentError('Provide either a parent animation or a child widget.');
  }

  static Widget fadeSlideIn({
    Animation<double>? animation,
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    int delay = 0,
    Offset begin = const Offset(0, 0.3),
    Curve fadeCurve = Curves.easeInOut,
    Curve slideCurve = Curves.easeOutBack,
  }) {
    if (animation != null) {
      return _buildFadeSlideTransition(
        animation: animation,
        child: child,
        begin: begin,
        fadeCurve: fadeCurve,
        slideCurve: slideCurve,
      );
    }

    return _ManagedAnimation(
      duration: duration,
      delay: Duration(milliseconds: delay),
      builder: (managedAnimation) => _buildFadeSlideTransition(
        animation: managedAnimation,
        child: child,
        begin: begin,
        fadeCurve: fadeCurve,
        slideCurve: slideCurve,
      ),
    );
  }

  static Widget slideFromLeft({
    Animation<double>? animation,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    int delay = 0,
    Curve curve = Curves.easeOutBack,
  }) {
    return _slideTransition(
      animation: animation,
      child: child,
      begin: const Offset(-1, 0),
      duration: duration,
      delay: delay,
      curve: curve,
    );
  }

  static Widget slideFromRight({
    required Widget child,
    Animation<double>? animation,
    Duration duration = const Duration(milliseconds: 400),
    int delay = 0,
    Curve curve = Curves.easeOutBack,
  }) {
    return _slideTransition(
      animation: animation,
      child: child,
      begin: const Offset(1, 0),
      duration: duration,
      delay: delay,
      curve: curve,
    );
  }

  static Widget slideFromTop({
    required Widget child,
    Animation<double>? animation,
    Duration duration = const Duration(milliseconds: 400),
    int delay = 0,
    Curve curve = Curves.easeOutCubic,
  }) {
    return _slideTransition(
      animation: animation,
      child: child,
      begin: const Offset(0, -0.35),
      duration: duration,
      delay: delay,
      curve: curve,
    );
  }

  static Widget slideFromBottom({
    required Widget child,
    Animation<double>? animation,
    Duration duration = const Duration(milliseconds: 400),
    int delay = 0,
    Curve curve = Curves.easeOutCubic,
  }) {
    return _slideTransition(
      animation: animation,
      child: child,
      begin: const Offset(0, 0.35),
      duration: duration,
      delay: delay,
      curve: curve,
    );
  }

  static Widget scaleIn({
    required Widget child,
    Animation<double>? animation,
    Duration duration = const Duration(milliseconds: 450),
    int delay = 0,
    Curve curve = Curves.elasticOut,
    double beginScale = 0.85,
    double endScale = 1.0,
  }) {
    return _animatedOrManaged(
      animation: animation,
      duration: duration,
      delay: delay,
      builder: (activeAnimation) => ScaleTransition(
        scale: Tween<double>(begin: beginScale, end: endScale).animate(
          CurvedAnimation(parent: activeAnimation, curve: curve),
        ),
        child: child,
      ),
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

  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 700),
    int delay = 0,
  }) {
    return _ManagedAnimation(
      duration: duration,
      delay: Duration(milliseconds: delay),
      builder: (animation) => ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.85, end: 1.08),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.08, end: 0.97),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.97, end: 1.0),
            weight: 20,
          ),
        ]).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }

  static Widget rotate({
    required Widget child,
    Animation<double>? animation,
    Duration duration = const Duration(milliseconds: 500),
    int delay = 0,
    double turns = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return _animatedOrManaged(
      animation: animation,
      duration: duration,
      delay: delay,
      builder: (activeAnimation) => RotationTransition(
        turns: Tween<double>(begin: 0, end: turns).animate(
          CurvedAnimation(parent: activeAnimation, curve: curve),
        ),
        child: child,
      ),
    );
  }

  static Widget spin({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
  }) {
    return _SpinAnimation(
      duration: duration,
      child: child,
    );
  }

  static dynamic typingDots({
    double? value,
    Color color = Colors.grey,
    double size = 4.0,
    int count = 3,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    if (value != null) {
      return _buildTypingDotOpacities(value, count: count);
    }

    return _TypingDotsWidget(
      color: color,
      size: size,
      count: count,
      duration: duration,
    );
  }

  static Widget staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration itemDuration = const Duration(milliseconds: 400),
  }) {
    return Column(
      children: List<Widget>.generate(
        children.length,
        (index) => fadeSlideIn(
          child: children[index],
          duration: itemDuration,
          delay: staggerDelay.inMilliseconds * index,
        ),
      ),
    );
  }

  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    return _ShimmerAnimation(
      duration: duration,
      baseColor: baseColor ?? Colors.grey.shade300,
      highlightColor: highlightColor ?? Colors.grey.shade100,
      child: child,
    );
  }

  static Widget progressBar({
    required double progress,
    Color color = Colors.blue,
    double height = 4.0,
    Duration duration = const Duration(milliseconds: 350),
    Color? backgroundColor,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: duration,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: color,
            backgroundColor:
                backgroundColor ?? color.withValues(alpha: 0.18),
          );
        },
      ),
    );
  }

  static PageRouteBuilder<void> fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: _buildFadeAnimation(animation),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<void> slideTransition({
    required Widget page,
    SlideDirection direction = SlideDirection.right,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final begin = switch (direction) {
      SlideDirection.left => const Offset(-1, 0),
      SlideDirection.right => const Offset(1, 0),
      SlideDirection.up => const Offset(0, 1),
      SlideDirection.down => const Offset(0, -1),
    };

    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<void> scaleTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: _buildFadeAnimation(animation),
            child: child,
          ),
        );
      },
    );
  }

  static Animation<double> _buildFadeAnimation(
    Animation<double> parent, {
    Curve curve = Curves.easeInOut,
    double begin = 0,
    double end = 1,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: parent, curve: curve),
    );
  }

  static Widget _buildFadeSlideTransition({
    required Animation<double> animation,
    required Widget child,
    required Offset begin,
    required Curve fadeCurve,
    required Curve slideCurve,
  }) {
    return FadeTransition(
      opacity: _buildFadeAnimation(animation, curve: fadeCurve),
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: slideCurve),
        ),
        child: child,
      ),
    );
  }

  static Widget _slideTransition({
    required Widget child,
    required Offset begin,
    Animation<double>? animation,
    required Duration duration,
    required int delay,
    required Curve curve,
  }) {
    return _animatedOrManaged(
      animation: animation,
      duration: duration,
      delay: delay,
      builder: (activeAnimation) => SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: activeAnimation, curve: curve),
        ),
        child: child,
      ),
    );
  }

  static Widget _animatedOrManaged({
    required Widget Function(Animation<double>) builder,
    Animation<double>? animation,
    required Duration duration,
    required int delay,
  }) {
    if (animation != null) {
      return builder(animation);
    }

    return _ManagedAnimation(
      duration: duration,
      delay: Duration(milliseconds: delay),
      builder: builder,
    );
  }

  static List<double> _buildTypingDotOpacities(double value, {int count = 3}) {
    return List<double>.generate(count, (index) {
      final delayed = (value + (index * 0.2)) % 1.0;
      if (delayed < 0.4) return 0.3 + (delayed / 0.4) * 0.7;
      if (delayed < 0.6) return 1.0;
      return 1.0 - ((delayed - 0.6) / 0.4) * 0.7;
    });
  }
}

enum SlideDirection {
  left,
  right,
  up,
  down,
}

class _ManagedAnimation extends StatefulWidget {
  const _ManagedAnimation({
    required this.duration,
    required this.delay,
    required this.builder,
  });

  final Duration duration;
  final Duration delay;
  final Widget Function(Animation<double>) builder;

  @override
  State<_ManagedAnimation> createState() => _ManagedAnimationState();
}

class _ManagedAnimationState extends State<_ManagedAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_controller);
  }
}

class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

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
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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

class _SpinAnimation extends StatefulWidget {
  const _SpinAnimation({
    required this.child,
    required this.duration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<_SpinAnimation> createState() => _SpinAnimationState();
}

class _SpinAnimationState extends State<_SpinAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: 0, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget({
    required this.color,
    required this.size,
    required this.count,
    required this.duration,
  });

  final Color color;
  final double size;
  final int count;
  final Duration duration;

  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacities = AnimationManager.typingDots(
          value: _controller.value,
          count: widget.count,
        ) as List<double>;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(widget.count, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index == widget.count - 1 ? 0 : 4),
              child: Opacity(
                opacity: opacities[index],
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  const _ShimmerAnimation({
    required this.duration,
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  });

  final Duration duration;
  final Color baseColor;
  final Color highlightColor;
  final Widget child;

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final slide = (_controller.value * 2) - 1;
            return LinearGradient(
              begin: Alignment(-1.5 + slide, 0),
              end: Alignment(1.5 + slide, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}
