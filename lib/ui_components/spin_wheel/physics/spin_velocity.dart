import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/spin_system_models.dart';
import '../services/spin_tracker.dart';

/// Enhanced spin physics system with realistic motion and customization
class EnhancedSpinPhysics {
  final double resistance;
  final double minVelocity;
  final double maxVelocity;
  final double friction;
  final bool enableRealism;

  const EnhancedSpinPhysics({
    this.resistance = 0.015,
    this.minVelocity = 3.0,
    this.maxVelocity = 15.0,
    this.friction = 0.98,
    this.enableRealism = true,
  });

  /// Calculate deceleration based on resistance
  double get deceleration => resistance * -7 * math.pi;

  /// Calculate spin distance based on initial velocity and time
  double calculateDistance(double velocity, double time) {
    if (!enableRealism) {
      // Simple linear calculation for performance
      return velocity * time * 0.5;
    }

    // Realistic physics with deceleration
    return (velocity * time) + (0.5 * deceleration * math.pow(time, 2));
  }

  /// Calculate spin duration based on initial velocity
  double calculateDuration(double velocity) {
    if (!enableRealism) {
      // Simple duration calculation
      return (velocity / maxVelocity) * 3.0 + 1.0;
    }

    // Realistic physics calculation
    return -velocity / deceleration;
  }

  /// Normalize angle to 0-2π range
  double normalizeAngle(double angle) => angle % (2 * math.pi);

  /// Calculate angle per segment
  double anglePerSegment(int segmentCount) => (2 * math.pi) / segmentCount;

  /// Calculate final landing segment with weighted probability
  int calculateLandingSegment({
    required double finalAngle,
    required int segmentCount,
    required List<WheelSegment> segments,
    bool useWeighting = true,
  }) {
    if (!useWeighting) {
      // Simple calculation
      final segmentAngle = anglePerSegment(segmentCount);
      return ((normalizeAngle(finalAngle) / segmentAngle).floor()) % segmentCount;
    }

    // Weighted calculation based on segment probability
    final normalizedAngle = normalizeAngle(finalAngle);
    final segmentAngle = anglePerSegment(segmentCount);

    // Add slight randomness for fairness
    final randomOffset = (math.Random().nextDouble() - 0.5) * segmentAngle * 0.1;
    final adjustedAngle = normalizeAngle(normalizedAngle + randomOffset);

    return (adjustedAngle / segmentAngle).floor() % segmentCount;
  }

  /// Create physics-based animation curve
  Curve createSpinCurve() {
    return enableRealism ? const _RealisticSpinCurve() : Curves.easeOutQuart;
  }

  /// Calculate spin result with comprehensive data
  SpinResult calculateSpinResult({
    required double initialVelocity,
    required double initialAngle,
    required List<WheelSegment> segments,
    required String spinId,
  }) {
    final duration = calculateDuration(initialVelocity);
    final distance = calculateDistance(initialVelocity, duration);
    final finalAngle = normalizeAngle(initialAngle + distance);

    final landingSegment = calculateLandingSegment(
      finalAngle: finalAngle,
      segmentCount: segments.length,
      segments: segments,
    );

    final selectedSegment = segments[landingSegment];

    return SpinResult(
      id: spinId,
      label: selectedSegment.label,
      imagePath: selectedSegment.imagePath,
      reward: selectedSegment.reward,
      rewardType: selectedSegment.rewardType,
      timestamp: DateTime.now(),
      spinDuration: Duration(milliseconds: (duration * 1000).round()),
      spinVelocity: initialVelocity,
      segmentIndex: landingSegment,
      metadata: {
        'finalAngle': finalAngle,
        'distance': distance,
        'physics': {
          'resistance': resistance,
          'deceleration': deceleration,
          'enableRealism': enableRealism,
        },
      },
      isJackpot: selectedSegment.rewardType.toLowerCase() == 'jackpot',
      isRare: ['rare', 'legendary', 'premium'].contains(
        selectedSegment.rewardType.toLowerCase(),
      ),
    );
  }
}

/// Custom curve for realistic spin physics
class _RealisticSpinCurve extends Curve {
  const _RealisticSpinCurve();

  @override
  double transformInternal(double t) {
    // Exponential decay curve that simulates realistic friction
    return 1.0 - math.pow(1.0 - t, 2.5);
  }
}

/// Enhanced velocity calculator with gesture recognition
class EnhancedSpinVelocity {
  final double width;
  final double height;
  final double sensitivityMultiplier;
  final bool enableGestureOptimization;

  const EnhancedSpinVelocity({
    required this.width,
    required this.height,
    this.sensitivityMultiplier = 1.0,
    this.enableGestureOptimization = true,
  });

  // Cached values for performance
  double get centerX => width * 0.5;
  double get centerY => height * 0.5;
  double get radius => math.min(width, height) * 0.4;

  /// Generate random spin velocity for button-triggered spins
  double generateRandomVelocity({
    double min = 5.0,
    double max = 12.0,
    double? bias,
  }) {
    final random = math.Random();
    double velocity = min + (random.nextDouble() * (max - min));

    // Apply bias if provided (useful for different spin types)
    if (bias != null) {
      velocity = velocity * bias;
    }

    return velocity.clamp(min, max);
  }

  /// Calculate velocity from gesture with enhanced accuracy
  double getVelocityFromGesture(
      Offset startPosition,
      Offset velocity,
      Duration gestureDuration,
      ) {
    if (!enableGestureOptimization) {
      return _basicVelocityCalculation(startPosition, velocity);
    }

    // Enhanced calculation with gesture analysis
    final center = Offset(centerX, centerY);
    final distanceFromCenter = (startPosition - center).distance;

    // Normalize distance for leverage calculation
    final leverageMultiplier = (distanceFromCenter / radius).clamp(0.3, 1.0);

    // Calculate tangential velocity
    final tangentialVelocity = _calculateTangentialVelocity(
      startPosition,
      center,
      velocity,
    );

    // Apply gesture duration factor (shorter gestures = more intentional)
    final durationFactor = _calculateDurationFactor(gestureDuration);

    // Combine factors
    double finalVelocity = tangentialVelocity *
        leverageMultiplier *
        durationFactor *
        sensitivityMultiplier;

    // Apply realistic constraints
    return finalVelocity.clamp(2.0, 15.0);
  }

  /// Basic velocity calculation for fallback
  double _basicVelocityCalculation(Offset position, Offset velocity) {
    final quadrant = _getQuadrantMultiplier(position);
    return (quadrant.dx * velocity.dx + quadrant.dy * velocity.dy).abs() * 0.01;
  }

  /// Calculate tangential velocity component
  double _calculateTangentialVelocity(
      Offset position,
      Offset center,
      Offset velocity,
      ) {
    // Vector from center to touch point
    final radialVector = position - center;
    final radialLength = radialVector.distance;

    if (radialLength == 0) return 0;

    // Normalized radial vector
    final radialUnit = radialVector / radialLength;

    // Tangent vector (perpendicular to radial)
    final tangentUnit = Offset(-radialUnit.dy, radialUnit.dx);

    // Project velocity onto tangent
    final tangentialComponent = _dotProduct(velocity, tangentUnit);

    // Convert to angular velocity (scale for UI)
    return tangentialComponent / (radialLength * 10);
  }

  /// Calculate duration factor for gesture quality
  double _calculateDurationFactor(Duration duration) {
    final milliseconds = duration.inMilliseconds;

    // Optimal gesture duration is around 200-500ms
    if (milliseconds < 100) return 0.7; // Too quick
    if (milliseconds > 800) return 0.8; // Too slow

    // Peak efficiency around 300ms
    if (milliseconds <= 300) {
      return 0.7 + (milliseconds / 300) * 0.3;
    } else {
      return 1.0 - ((milliseconds - 300) / 500) * 0.2;
    }
  }

  /// Get quadrant multiplier for position
  Offset _getQuadrantMultiplier(Offset position) {
    final isRight = position.dx > centerX;
    final isBottom = position.dy > centerY;

    if (isRight && !isBottom) return const Offset(0.5, 0.5);   // Q1
    if (!isRight && !isBottom) return const Offset(-0.5, 0.5); // Q2
    if (!isRight && isBottom) return const Offset(-0.5, -0.5); // Q3
    return const Offset(0.5, -0.5); // Q4
  }

  /// Dot product of two vectors
  double _dotProduct(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  /// Convert offset to radians with improved precision
  double offsetToRadians(Offset position) {
    final dx = position.dx - centerX;
    final dy = centerY - position.dy; // Flip Y for standard math coordinates
    return math.atan2(dy, dx);
  }

  /// Check if position is within valid spin area
  bool isValidSpinPosition(Offset position) {
    final center = Offset(centerX, centerY);
    final distance = (position - center).distance;
    return distance >= radius * 0.2 && distance <= radius * 1.2;
  }

  /// Get spin quality based on gesture
  SpinQuality getSpinQuality(
      Offset startPosition,
      Offset velocity,
      Duration duration,
      ) {
    final distanceFromCenter = (startPosition - Offset(centerX, centerY)).distance;
    final isGoodPosition = distanceFromCenter >= radius * 0.5;
    final isGoodDuration = duration.inMilliseconds >= 150 && duration.inMilliseconds <= 600;
    final isGoodVelocity = velocity.distance >= 100;

    final score = [isGoodPosition, isGoodDuration, isGoodVelocity]
        .where((condition) => condition)
        .length;

    switch (score) {
      case 3:
        return SpinQuality.excellent;
      case 2:
        return SpinQuality.good;
      case 1:
        return SpinQuality.fair;
      default:
        return SpinQuality.poor;
    }
  }
}

/// Enum for spin quality assessment
enum SpinQuality {
  poor,
  fair,
  good,
  excellent;

  /// Get quality multiplier for rewards
  double get multiplier {
    switch (this) {
      case SpinQuality.poor:
        return 0.8;
      case SpinQuality.fair:
        return 1.0;
      case SpinQuality.good:
        return 1.1;
      case SpinQuality.excellent:
        return 1.2;
    }
  }

  /// Get quality color
  Color get color {
    switch (this) {
      case SpinQuality.poor:
        return Colors.red;
      case SpinQuality.fair:
        return Colors.orange;
      case SpinQuality.good:
        return Colors.green;
      case SpinQuality.excellent:
        return Colors.purple;
    }
  }

  /// Get quality display name
  String get displayName {
    switch (this) {
      case SpinQuality.poor:
        return 'Poor Spin';
      case SpinQuality.fair:
        return 'Fair Spin';
      case SpinQuality.good:
        return 'Good Spin';
      case SpinQuality.excellent:
        return 'Excellent Spin!';
    }
  }
}