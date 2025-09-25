import 'package:flutter/material.dart';

class CustomDrawerRoute extends PageRouteBuilder {
  final Widget page;

  CustomDrawerRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildTransition(animation, secondaryAnimation, child);
    },
  );

  static Widget _buildTransition(
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    // Primary slide animation
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutExpo,
    ));

    // Fade animation
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Scale animation for modern feel
    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    // Background overlay animation
    final overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        // Background overlay
        FadeTransition(
          opacity: overlayAnimation,
          child: Container(
            color: Colors.black,
          ),
        ),
        // Main drawer content
        SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(5, 0),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDrawerRouteAdvanced extends PageRouteBuilder {
  final Widget page;
  final Color? backgroundColor;
  final Curve? curve;

  CustomDrawerRouteAdvanced({
    required this.page,
    this.backgroundColor,
    Duration? customDuration,
    this.curve,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: customDuration ?? const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildAdvancedTransition(
        animation,
        secondaryAnimation,
        child,
        backgroundColor,
        curve,
      );
    },
  );

  static Widget _buildAdvancedTransition(
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      Color? backgroundColor,
      Curve? curve,
      ) {
    final effectiveCurve = curve ?? Curves.easeOutExpo;
    final effectiveBackgroundColor = backgroundColor ?? Colors.black.withOpacity(0.4);

    // Staggered animations for more sophisticated feel
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: effectiveCurve,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    final scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    // Bouncy overshoot for modern appeal
    final bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    final overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        // Animated background overlay
        AnimatedBuilder(
          animation: overlayAnimation,
          builder: (context, child) {
            return Container(
              color: effectiveBackgroundColor.withOpacity(
                overlayAnimation.value * 0.4,
              ),
            );
          },
        ),
        // Main drawer with multiple animation layers
        SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment.centerLeft,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(0.1 * (1 - bounceAnimation.value)),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(8, 0),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 60,
                        offset: const Offset(15, 5),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Utility class for drawer animation presets
class DrawerAnimationPresets {
  static const Duration fastDuration = Duration(milliseconds: 250);
  static const Duration normalDuration = Duration(milliseconds: 400);
  static const Duration slowDuration = Duration(milliseconds: 600);

  static const Curve easeOutCurve = Curves.easeOutExpo;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  static CustomDrawerRouteAdvanced fast(Widget page) {
    return CustomDrawerRouteAdvanced(
      page: page,
      customDuration: fastDuration,
      curve: smoothCurve,
    );
  }

  static CustomDrawerRouteAdvanced bouncy(Widget page) {
    return CustomDrawerRouteAdvanced(
      page: page,
      customDuration: slowDuration,
      curve: bouncyCurve,
      backgroundColor: Colors.purple,
    );
  }

  static CustomDrawerRouteAdvanced elegant(Widget page) {
    return CustomDrawerRouteAdvanced(
      page: page,
      customDuration: normalDuration,
      curve: easeOutCurve,
      backgroundColor: Colors.indigo,
    );
  }
}