import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/physics/spin_physics_handler.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/physics/spin_velocity.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/spin_system_models.dart';
import '../services/spin_tracker.dart';
import 'non_uniform_motion.dart';

class UpdatedSpinHandlers {
  // Initialize enhanced physics (you can make this configurable)
  static final _physics = EnhancedNonUniformMotion.realistic(resistance: 0.015);
  static final _velocityCalculator = EnhancedSpinVelocity(width: 400, height: 400);
  static final _spinHandler = EnhancedSpinHandler(
    physics: EnhancedSpinPhysics(resistance: 0.015),
    velocityCalculator: _velocityCalculator,
  );

  /// Updated handleSpinWithPhysics function
  static Future<void> handleSpinWithPhysics({
    required TickerProvider vsync,
    required WidgetRef ref,
    required double currentAngle,
    required List<WheelSegment> segments,
    required void Function(AnimationController controller, Animation<double> animation) setAnimation,
    required VoidCallback onStart,
    required void Function(WheelSegment) onComplete,
    double? customVelocity,
  }) async {
    // Generate velocity if not provided
    final velocity = customVelocity ?? _velocityCalculator.generateRandomVelocity();

    // Calculate physics
    final duration = _physics.calculateDuration(velocity);
    final distance = _physics.calculateDistance(velocity, duration);
    final targetAngle = currentAngle + distance;

    // Create animation controller
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (duration * 1000).round()),
    );

    // Create animation with physics curve
    final animation = Tween<double>(
      begin: currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _physics.decelerationCurve(1.0) > 0.5
          ? Curves.easeOutQuart
          : Curves.easeOutCubic,
    ));

    // Provide animation to caller
    setAnimation(controller, animation);

    // Start spin
    onStart();

    // Forward animation
    await controller.forward();

    // Calculate final result
    final finalAngle = _physics.normalizeAngle(animation.value);
    final segmentIndex = _physics.predictLandingSegment(
      initialAngle: currentAngle,
      initialVelocity: velocity,
      segmentCount: segments.length,
      addRandomness: true,
    );

    final selectedSegment = segments[segmentIndex];

    // Trigger confetti and register spin
    ref.read(confettiControllerProvider).play();
    await SpinTracker.registerSpin();

    // Complete callback
    onComplete(selectedSegment);
  }
}