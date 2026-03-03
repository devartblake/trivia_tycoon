import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/animations/animation_manager.dart';

/// Helper functions for drawer animations
@Deprecated('Use AnimationManager in core/animations/animation_manager.dart')
class DrawerAnimations {
  /// Create staggered animation controllers
  static List<AnimationController> createStaggeredControllers({
    required TickerProvider vsync,
    required int count,
    int baseDelay = 400,
    int delayIncrement = 50,
  }) {
    return AnimationManager.createStaggeredControllers(
      vsync: vsync,
      count: count,
      baseDurationMs: baseDelay,
      durationIncrementMs: delayIncrement,
    );
  }

  /// Start staggered animations with delay
  static void startStaggered({
    required List<AnimationController> controllers,
    int baseDelay = 200,
    int delayIncrement = 80,
    required bool mounted,
  }) {
    AnimationManager.startStaggered(
      controllers: controllers,
      baseDelayMs: baseDelay,
      delayIncrementMs: delayIncrement,
      mounted: mounted,
    );
  }

  /// Dispose multiple controllers
  static void disposeControllers(List<AnimationController> controllers) {
    AnimationManager.disposeControllers(controllers);
  }

  /// Create slide transition from left
  static Widget slideFromLeft({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeOutBack,
  }) {
    return AnimationManager.slideFromLeft(
      animation: animation,
      curve: curve,
      child: child,
    );
  }

  /// Create fade transition
  static Widget fadeIn({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: AnimationManager.fadeIn(animation, curve: curve),
      child: child,
    );
  }
}
