import 'package:flutter/material.dart';

/// Centralized Animation Manager for Trivia Tycoon
///
/// Consolidates all animation patterns found across:
/// - ShowUpAnimation (core/utils/animation.dart)
/// - DrawerAnimations (game/utils/drawer_animations.dart)
/// - TypingIndicator animations
/// - Staggered list animations
/// - Page transitions
/// - Presence indicators
/// - And 50+ other animation implementations
///
/// Usage:
/// ```dart
/// // Simple fade in
/// AnimationManager.fadeIn(child: MyWidget())
///
/// // Slide from bottom with custom duration
/// AnimationManager.slideFromBottom(
///   child: MyWidget(),
///   duration: Duration(milliseconds: 500),
/// )
///
/// // Staggered list
/// AnimationManager.staggeredList(
///   children: widgets,
///   staggerDelay: 100,
/// )
/// ```
class AnimationManager {
  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  /// Default animation duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Default stagger delay between items
  static const Duration defaultStaggerDelay = Duration(milliseconds: 100);

  /// Default curve
  static const Curve defaultCurve = Curves.easeInOut;

  // ============================================================================
  // FADE ANIMATIONS
  // ============================================================================

  /// Simple fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.easeIn,
    int? delay,
  }) {
    return _AnimatedFade(
      child: child,
      duration: duration ?? defaultDuration,
      curve: curve,
      delay: delay,
    );
  }

  /// Fade in from opacity 0 to 1
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    Curve curve = Curves.easeInOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  // ============================================================================
  // SLIDE ANIMATIONS
  // ============================================================================

  /// Slide from bottom (common for modals, cards)
  static Widget slideFromBottom({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
    int? delay,
  }) {
    return _AnimatedSlide(
      child: child,
      duration: duration ?? defaultDuration,
      curve: curve,
      delay: delay,
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    );
  }

  /// Slide from left (common for drawer items)
  static Widget slideFromLeft({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.easeOutBack,
    int? delay,
  }) {
    return _AnimatedSlide(
      child: child,
      duration: duration ?? defaultDuration,
      curve: curve,
      delay: delay,
      begin: const Offset(-1, 0),
      end: Offset.zero,
    );
  }

  /// Slide from right
  static Widget slideFromRight({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.easeOutBack,
    int? delay,
  }) {
    return _AnimatedSlide(
      child: child,
      duration: duration ?? defaultDuration,
      curve: curve,
      delay: delay,
      begin: const Offset(1, 0),
      end: Offset.zero,
    );
  }

  /// Slide from top
  static Widget slideFromTop({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
    int? delay,
  }) {
    return _AnimatedSlide(
      child: child,
      duration: duration ?? defaultDuration,
      curve: curve,
      delay: delay,
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    );
  }

  // ============================================================================
  // COMBINED ANIMATIONS
  // ============================================================================

  /// Fade + Slide (most common pattern in the app)
  /// Used in: ShowUpAnimation, MainMenuScreen, etc.
  static Widget fadeSlideIn({
    required Widget child,
    Duration? duration,
    Curve fadeCurve = Curves.easeInOut,
    Curve slideCurve = Curves.decelerate,
    int? delay,
    Offset begin = const Offset(0, 0.35),
  }) {
    return _AnimatedFadeSlide(
      child: child,
      duration: duration ?? Duration(milliseconds: 500),
      fadeCurve: fadeCurve,
      slideCurve: slideCurve,
      delay: delay,
      begin: begin,
    );
  }

  // ============================================================================
  // SCALE ANIMATIONS
  // ============================================================================

  /// Scale animation (grow from small to full size)
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    Curve curve = Curves.elasticOut,
    int? delay,
    double beginScale = 0.0,
    double endScale = 1.0,
  }) {
    return _AnimatedScale(
      child: child,
      duration: duration ?? Duration(milliseconds: 600),
      curve: curve,
      delay: delay,
      begin: beginScale,
      end: endScale,
    );
  }

  /// Pulse animation (continuous scale effect)
  /// Used in: PresenceStatusIndicator, TycoonToast
  static Widget pulse({
    required Widget child,
    Duration? duration,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return _PulseAnimation(
      child: child,
      duration: duration ?? Duration(seconds: 2),
      minScale: minScale,
      maxScale: maxScale,
    );
  }

  /// Bounce animation (single bounce)
  static Widget bounce({
    required Widget child,
    Duration? duration,
    int? delay,
  }) {
    return _BounceAnimation(
      child: child,
      duration: duration ?? Duration(milliseconds: 800),
      delay: delay,
    );
  }

  // ============================================================================
  // ROTATION ANIMATIONS
  // ============================================================================

  /// Rotate animation
  static Widget rotate({
    required Widget child,
    Duration? duration,
    double turns = 1.0,
    Curve curve = Curves.easeInOut,
    int? delay,
  }) {
    return _AnimatedRotation(
      child: child,
      duration: duration ?? Duration(milliseconds: 500),
      curve: curve,
      delay: delay,
      turns: turns,
    );
  }

  /// Continuous rotation (loading spinners)
  static Widget spin({
    required Widget child,
    Duration? duration,
  }) {
    return _SpinAnimation(
      child: child,
      duration: duration ?? Duration(seconds: 2),
    );
  }

  // ============================================================================
  // STAGGERED ANIMATIONS
  // ============================================================================

  /// Staggered list animation (common in menu screens)
  static Widget staggeredList({
    required List<Widget> children,
    Duration? itemDuration,
    Duration? staggerDelay,
    Axis scrollDirection = Axis.vertical,
    Curve curve = Curves.easeOutCubic,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return _StaggeredList(
      children: children,
      itemDuration: itemDuration ?? defaultDuration,
      staggerDelay: staggerDelay ?? defaultStaggerDelay,
      scrollDirection: scrollDirection,
      curve: curve,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }

  /// Create staggered animation controllers
  /// Used in: MainMenuScreen, TierProgressionWidget
  static List<AnimationController> createStaggeredControllers({
    required TickerProvider vsync,
    required int count,
    int baseDuration = 400,
    int durationIncrement = 50,
  }) {
    return List.generate(
      count,
          (index) => AnimationController(
        duration: Duration(milliseconds: baseDuration + (index * durationIncrement)),
        vsync: vsync,
      ),
    );
  }

  /// Start staggered animations
  static void startStaggered({
    required List<AnimationController> controllers,
    int baseDelay = 200,
    int delayIncrement = 80,
    required bool mounted,
  }) {
    for (int i = 0; i < controllers.length; i++) {
      Future.delayed(Duration(milliseconds: baseDelay + (i * delayIncrement)), () {
        if (mounted) {
          controllers[i].forward();
        }
      });
    }
  }

  /// Dispose multiple controllers
  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  // ============================================================================
  // SPECIAL ANIMATIONS
  // ============================================================================

  /// Typing dots animation (like in TypingIndicatorWidget)
  static Widget typingDots({
    Color? color,
    double size = 4.0,
    Duration? duration,
  }) {
    return _TypingDotsAnimation(
      color: color ?? Colors.grey,
      size: size,
      duration: duration ?? Duration(milliseconds: 1500),
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? duration,
  }) {
    return _ShimmerAnimation(
      child: child,
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      duration: duration ?? Duration(milliseconds: 1500),
    );
  }

  /// Progress bar fill animation
  static Widget progressBar({
    required double progress,
    Duration? duration,
    Color? color,
    Color? backgroundColor,
    double height = 4.0,
    BorderRadius? borderRadius,
  }) {
    return _AnimatedProgressBar(
      progress: progress,
      duration: duration ?? Duration(milliseconds: 300),
      color: color ?? Colors.blue,
      backgroundColor: backgroundColor ?? Colors.grey[300]!,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(2),
    );
  }

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  /// Fade page transition
  static Route fadeTransition({
    required Widget page,
    Duration? duration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide page transition
  static Route slideTransition({
    required Widget page,
    Duration? duration,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset begin;
    switch (direction) {
      case SlideDirection.left:
        begin = const Offset(-1, 0);
        break;
      case SlideDirection.right:
        begin = const Offset(1, 0);
        break;
      case SlideDirection.up:
        begin = const Offset(0, -1);
        break;
      case SlideDirection.down:
        begin = const Offset(0, 1);
        break;
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  /// Scale page transition
  static Route scaleTransition({
    required Widget page,
    Duration? duration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // ============================================================================
  // HELPER BUILDERS
  // ============================================================================

  /// Create a standard controller
  static AnimationController createController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? defaultDuration,
      vsync: vsync,
    );
  }

  /// Create a curved animation
  static Animation<double> createCurvedAnimation({
    required AnimationController controller,
    Curve curve = Curves.easeInOut,
    Curve? reverseCurve,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }
}

// ============================================================================
// INTERNAL ANIMATION WIDGETS
// ============================================================================

/// Simple fade animation widget
class _AnimatedFade extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int? delay;

  const _AnimatedFade({
    required this.child,
    required this.duration,
    required this.curve,
    this.delay,
  });

  @override
  State<_AnimatedFade> createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends State<_AnimatedFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// Slide animation widget
class _AnimatedSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int? delay;
  final Offset begin;
  final Offset end;

  const _AnimatedSlide({
    required this.child,
    required this.duration,
    required this.curve,
    this.delay,
    required this.begin,
    required this.end,
  });

  @override
  State<_AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends State<_AnimatedSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<Offset>(begin: widget.begin, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}

/// Combined fade and slide animation (most common)
class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve fadeCurve;
  final Curve slideCurve;
  final int? delay;
  final Offset begin;

  const _AnimatedFadeSlide({
    required this.child,
    required this.duration,
    required this.fadeCurve,
    required this.slideCurve,
    this.delay,
    required this.begin,
  });

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.fadeCurve),
    );

    _slideAnimation = Tween<Offset>(begin: widget.begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.slideCurve),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
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
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale animation widget
class _AnimatedScale extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int? delay;
  final double begin;
  final double end;

  const _AnimatedScale({
    required this.child,
    required this.duration,
    required this.curve,
    this.delay,
    required this.begin,
    required this.end,
  });

  @override
  State<_AnimatedScale> createState() => _AnimatedScaleState();
}

class _AnimatedScaleState extends State<_AnimatedScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: widget.begin, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Pulse animation (continuous)
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
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Bounce animation
class _BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int? delay;

  const _BounceAnimation({
    required this.child,
    required this.duration,
    this.delay,
  });

  @override
  State<_BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<_BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Rotation animation
class _AnimatedRotation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final int? delay;
  final double turns;

  const _AnimatedRotation({
    required this.child,
    required this.duration,
    required this.curve,
    this.delay,
    required this.turns,
  });

  @override
  State<_AnimatedRotation> createState() => _AnimatedRotationState();
}

class _AnimatedRotationState extends State<_AnimatedRotation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: widget.turns).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay != null) {
      Future.delayed(Duration(milliseconds: widget.delay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _animation, child: widget.child);
  }
}

/// Continuous spin animation
class _SpinAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SpinAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_SpinAnimation> createState() => _SpinAnimationState();
}

class _SpinAnimationState extends State<_SpinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _controller, child: widget.child);
  }
}

/// Staggered list animation
class _StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final Axis scrollDirection;
  final Curve curve;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const _StaggeredList({
    required this.children,
    required this.itemDuration,
    required this.staggerDelay,
    required this.scrollDirection,
    required this.curve,
    required this.shrinkWrap,
    this.physics,
  });

  @override
  State<_StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<_StaggeredList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimationManager.fadeSlideIn(
          child: widget.children[index],
          duration: widget.itemDuration,
          delay: widget.staggerDelay.inMilliseconds * index,
          fadeCurve: widget.curve,
          slideCurve: widget.curve,
        );
      },
    );
  }
}

/// Typing dots animation
class _TypingDotsAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _TypingDotsAnimation({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 6,
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final animationValue = (_controller.value + delay) % 1.0;
              final opacity = _calculateDotOpacity(animationValue);

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _calculateDotOpacity(double animationValue) {
    if (animationValue < 0.4) {
      return 0.3 + (animationValue / 0.4) * 0.7;
    } else if (animationValue < 0.6) {
      return 1.0;
    } else {
      return 1.0 - ((animationValue - 0.6) / 0.4) * 0.7;
    }
  }
}

/// Shimmer animation
class _ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const _ShimmerAnimation({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
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
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animated progress bar
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Duration duration;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius borderRadius;

  const _AnimatedProgressBar({
    required this.progress,
    required this.duration,
    required this.color,
    required this.backgroundColor,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedContainer(
            duration: duration,
            width: constraints.maxWidth * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ENUMS
// ============================================================================

/// Slide direction for page transitions
enum SlideDirection {
  left,
  right,
  up,
  down,
}