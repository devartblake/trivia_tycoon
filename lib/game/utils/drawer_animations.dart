import 'package:flutter/material.dart';

/// Helper functions for drawer animations
class DrawerAnimations {
  /// Create staggered animation controllers
  static List<AnimationController> createStaggeredControllers({
    required TickerProvider vsync,
    required int count,
    int baseDelay = 400,
    int delayIncrement = 50,
  }) {
    return List.generate(
      count,
          (index) => AnimationController(
        duration: Duration(milliseconds: baseDelay + (index * delayIncrement)),
        vsync: vsync,
      ),
    );
  }

  /// Start staggered animations with delay
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

  /// Create slide transition from left
  static Widget slideFromLeft({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeOutBack,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
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
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }
}
