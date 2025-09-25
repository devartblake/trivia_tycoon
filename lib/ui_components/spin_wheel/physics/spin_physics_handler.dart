import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/physics/spin_velocity.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../models/spin_system_models.dart';
import '../services/spin_tracker.dart';

/// Enhanced spin handler with comprehensive features
class EnhancedSpinHandler {
  final EnhancedSpinPhysics physics;
  final EnhancedSpinVelocity velocityCalculator;
  final bool enableHaptics;
  final bool enableSoundEffects;

  const EnhancedSpinHandler({
    required this.physics,
    required this.velocityCalculator,
    this.enableHaptics = true,
    this.enableSoundEffects = true,
  });

  /// Handle complete spin with physics and callbacks
  Future<SpinResult> handleSpin({
    required TickerProvider vsync,
    required WidgetRef ref,
    required double currentAngle,
    required List<WheelSegment> segments,
    required void Function(AnimationController, Animation<double>) setAnimation,
    required VoidCallback onStart,
    required void Function(SpinResult) onComplete,
    double? customVelocity,
    Offset? gestureStart,
    Offset? gestureVelocity,
    Duration? gestureDuration,
  }) async {
    // Generate or calculate velocity
    double velocity;
    SpinQuality? quality;

    if (customVelocity != null) {
      velocity = customVelocity;
    } else if (gestureStart != null && gestureVelocity != null && gestureDuration != null) {
      velocity = velocityCalculator.getVelocityFromGesture(
        gestureStart,
        gestureVelocity,
        gestureDuration,
      );
      quality = velocityCalculator.getSpinQuality(
        gestureStart,
        gestureVelocity,
        gestureDuration,
      );
    } else {
      velocity = velocityCalculator.generateRandomVelocity();
    }

    // Calculate spin physics
    final duration = physics.calculateDuration(velocity);
    final distance = physics.calculateDistance(velocity, duration);

    // Create animation controller
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (duration * 1000).round()),
    );

    // Create animation with physics curve
    final animation = Tween<double>(
      begin: currentAngle,
      end: currentAngle + distance,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: physics.createSpinCurve(),
    ));

    // Provide animation to caller
    setAnimation(controller, animation);

    // Start spin
    onStart();

    // Haptic feedback
    if (enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    // Start animation
    await controller.forward();

    // Calculate final result
    final spinResult = physics.calculateSpinResult(
      initialVelocity: velocity,
      initialAngle: currentAngle,
      segments: segments,
      spinId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Add quality data if available
    if (quality != null) {
      final enhancedResult = spinResult.copyWith(
        metadata: {
          ...?spinResult.metadata,
          'spinQuality': quality.name,
          'qualityMultiplier': quality.multiplier,
        },
      );

      // Apply quality bonus to reward
      final bonusReward = (spinResult.reward * quality.multiplier).round();
      final finalResult = enhancedResult.copyWith(reward: bonusReward);

      // Register spin and update state
      await _completeSpin(ref, finalResult);
      onComplete(finalResult);

      return finalResult;
    } else {
      // Register spin and update state
      await _completeSpin(ref, spinResult);
      onComplete(spinResult);

      return spinResult;
    }
  }

  /// Complete spin with state updates
  Future<void> _completeSpin(WidgetRef ref, SpinResult result) async {
    // Trigger confetti
    ref.read(confettiControllerProvider).play();

    // Register spin
    await SpinTracker.registerSpin();

    // End haptic feedback
    if (enableHaptics) {
      HapticFeedback.lightImpact();
    }

    // Update coin balance if reward is currency
    if (result.rewardType?.toLowerCase() == 'currency' ||
        result.rewardType?.toLowerCase() == 'coins') {
      // Assuming there's a coin provider to update
      // ref.read(coinNotifierProvider.notifier).addCoins(result.reward);
    }
  }

  /// Create handler with default physics for different difficulty levels
  factory EnhancedSpinHandler.easy() {
    return EnhancedSpinHandler(
      physics: const EnhancedSpinPhysics(
        resistance: 0.010, // Less resistance = longer spins
        minVelocity: 4.0,
        maxVelocity: 12.0,
        enableRealism: false, // Simpler physics
      ),
      velocityCalculator: const EnhancedSpinVelocity(
        width: 400,
        height: 400,
        sensitivityMultiplier: 1.2, // More sensitive
      ),
    );
  }

  factory EnhancedSpinHandler.normal() {
    return EnhancedSpinHandler(
      physics: const EnhancedSpinPhysics(
        resistance: 0.015,
        minVelocity: 3.0,
        maxVelocity: 15.0,
        enableRealism: true,
      ),
      velocityCalculator: const EnhancedSpinVelocity(
        width: 400,
        height: 400,
        sensitivityMultiplier: 1.0,
      ),
    );
  }

  factory EnhancedSpinHandler.hard() {
    return EnhancedSpinHandler(
      physics: const EnhancedSpinPhysics(
        resistance: 0.020, // More resistance = shorter spins
        minVelocity: 2.0,
        maxVelocity: 18.0,
        enableRealism: true,
      ),
      velocityCalculator: const EnhancedSpinVelocity(
        width: 400,
        height: 400,
        sensitivityMultiplier: 0.8, // Less sensitive
        enableGestureOptimization: true,
      ),
    );
  }
}
