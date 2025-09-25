import 'dart:math';
import 'package:flutter/material.dart';

/// Advanced physics engine for realistic wheel spinning behavior
class WheelPhysicsEngine {
  final double friction;
  final double airResistance;
  final double mass;
  final double radius;
  final double momentOfInertia;

  WheelPhysicsEngine({
    this.friction = 0.02,
    this.airResistance = 0.001,
    this.mass = 1.0,
    this.radius = 1.0,
  }) : momentOfInertia = 0.5 * mass * radius * radius;

  /// Calculate the physics of a wheel spin
  SpinPhysicsResult calculateSpin({
    required double initialVelocity,
    required double maxDuration,
    int segments = 8,
  }) {
    final List<PhysicsStep> steps = [];
    double currentVelocity = initialVelocity;
    double currentAngle = 0.0;
    double time = 0.0;

    const double timeStep = 0.016; // ~60 FPS

    while (currentVelocity.abs() > 0.01 && time < maxDuration) {
      // Calculate forces
      final frictionForce = -_calculateFriction(currentVelocity);
      final airResistanceForce = -_calculateAirResistance(currentVelocity);
      final totalForce = frictionForce + airResistanceForce;

      // Calculate acceleration (F = ma, but for rotation τ = Iα)
      final acceleration = totalForce / momentOfInertia;

      // Update velocity and position
      currentVelocity += acceleration * timeStep;
      currentAngle += currentVelocity * timeStep;

      steps.add(PhysicsStep(
        time: time,
        angle: currentAngle,
        velocity: currentVelocity,
        acceleration: acceleration,
      ));

      time += timeStep;
    }

    // Ensure the wheel settles on a segment
    final finalAngle = _snapToSegment(currentAngle, segments);
    final selectedSegment = _getSegmentIndex(finalAngle, segments);

    return SpinPhysicsResult(
      steps: steps,
      finalAngle: finalAngle,
      totalDuration: time,
      selectedSegment: selectedSegment,
      initialVelocity: initialVelocity,
    );
  }

  /// Calculate friction force based on velocity
  double _calculateFriction(double velocity) {
    // Static friction is higher than kinetic friction
    final frictionCoeff = velocity.abs() < 0.1 ? friction * 2 : friction;
    return frictionCoeff * velocity.sign * mass * 9.81; // mg * μ
  }

  /// Calculate air resistance force
  double _calculateAirResistance(double velocity) {
    // F = 0.5 * ρ * v² * Cd * A (simplified for rotational motion)
    return airResistance * velocity * velocity.abs();
  }

  /// Snap angle to nearest segment center
  double _snapToSegment(double angle, int segments) {
    final segmentAngle = 2 * pi / segments;
    final segmentIndex = (angle / segmentAngle).round();
    return segmentIndex * segmentAngle;
  }

  /// Get the segment index from angle
  int _getSegmentIndex(double angle, int segments) {
    final normalizedAngle = angle % (2 * pi);
    final segmentAngle = 2 * pi / segments;
    return (normalizedAngle / segmentAngle).floor() % segments;
  }
}

/// Represents a single step in the physics simulation
class PhysicsStep {
  final double time;
  final double angle;
  final double velocity;
  final double acceleration;

  PhysicsStep({
    required this.time,
    required this.angle,
    required this.velocity,
    required this.acceleration,
  });

  @override
  String toString() => 'PhysicsStep(t: ${time.toStringAsFixed(3)}, '
      'θ: ${angle.toStringAsFixed(3)}, '
      'ω: ${velocity.toStringAsFixed(3)}, '
      'α: ${acceleration.toStringAsFixed(3)})';
}

/// Result of a complete spin physics calculation
class SpinPhysicsResult {
  final List<PhysicsStep> steps;
  final double finalAngle;
  final double totalDuration;
  final int selectedSegment;
  final double initialVelocity;

  SpinPhysicsResult({
    required this.steps,
    required this.finalAngle,
    required this.totalDuration,
    required this.selectedSegment,
    required this.initialVelocity,
  });

  /// Get the angle at a specific time
  double getAngleAtTime(double time) {
    if (steps.isEmpty) return 0.0;
    if (time <= 0) return steps.first.angle;
    if (time >= totalDuration) return finalAngle;

    // Find the appropriate step
    for (int i = 0; i < steps.length - 1; i++) {
      if (time >= steps[i].time && time < steps[i + 1].time) {
        // Linear interpolation between steps
        final t1 = steps[i].time;
        final t2 = steps[i + 1].time;
        final a1 = steps[i].angle;
        final a2 = steps[i + 1].angle;

        final factor = (time - t1) / (t2 - t1);
        return a1 + (a2 - a1) * factor;
      }
    }

    return finalAngle;
  }

  /// Get the velocity at a specific time
  double getVelocityAtTime(double time) {
    if (steps.isEmpty) return 0.0;
    if (time <= 0) return initialVelocity;
    if (time >= totalDuration) return 0.0;

    for (int i = 0; i < steps.length - 1; i++) {
      if (time >= steps[i].time && time < steps[i + 1].time) {
        final t1 = steps[i].time;
        final t2 = steps[i + 1].time;
        final v1 = steps[i].velocity;
        final v2 = steps[i + 1].velocity;

        final factor = (time - t1) / (t2 - t1);
        return v1 + (v2 - v1) * factor;
      }
    }

    return 0.0;
  }

  @override
  String toString() => 'SpinPhysicsResult('
      'duration: ${totalDuration.toStringAsFixed(3)}s, '
      'finalAngle: ${finalAngle.toStringAsFixed(3)}, '
      'segment: $selectedSegment, '
      'steps: ${steps.length})';
}

/// Advanced gesture-based physics for touch interactions
class GesturePhysics {
  static const double _velocityScale = 0.001;
  static const double _minimumVelocity = 1.0;
  static const double _maximumVelocity = 20.0;

  /// Convert gesture velocity to angular velocity
  static double gestureToAngularVelocity(
      Offset gestureVelocity,
      Offset centerPoint,
      Offset touchPoint,
      ) {
    // Calculate the vector from center to touch point
    final touchVector = touchPoint - centerPoint;
    final radius = touchVector.distance;

    if (radius < 10) return 0.0; // Too close to center

    // Calculate tangential velocity
    final tangentialVelocity = _calculateTangentialVelocity(
      gestureVelocity,
      touchVector,
      radius,
    );

    // Convert to angular velocity
    double angularVelocity = tangentialVelocity * _velocityScale;

    // Apply constraints
    angularVelocity = angularVelocity.clamp(
      -_maximumVelocity,
      _maximumVelocity,
    );

    // Apply minimum threshold
    if (angularVelocity.abs() < _minimumVelocity) {
      return 0.0;
    }

    return angularVelocity;
  }

  /// Calculate tangential velocity component
  static double _calculateTangentialVelocity(
      Offset gestureVelocity,
      Offset touchVector,
      double radius,
      ) {
    // Normalize the touch vector
    final normalizedTouch = touchVector / radius;

    // Calculate perpendicular vector (tangent)
    final tangent = Offset(-normalizedTouch.dy, normalizedTouch.dx);

    // Project gesture velocity onto tangent
    final dotProduct = gestureVelocity.dx * tangent.dx +
        gestureVelocity.dy * tangent.dy;

    return dotProduct;
  }

  /// Calculate spin direction based on gesture
  static int getSpinDirection(
      Offset gestureVelocity,
      Offset centerPoint,
      Offset touchPoint,
      ) {
    final angularVelocity = gestureToAngularVelocity(
      gestureVelocity,
      centerPoint,
      touchPoint,
    );

    if (angularVelocity > 0) return 1;  // Clockwise
    if (angularVelocity < 0) return -1; // Counter-clockwise
    return 0; // No rotation
  }
}

/// Realistic wheel momentum and inertia simulation
class WheelMomentum {
  final double mass;
  final double radius;
  final double friction;

  late double _momentOfInertia;
  late double _angularVelocity;
  late double _angle;

  WheelMomentum({
    this.mass = 1.0,
    this.radius = 1.0,
    this.friction = 0.02,
  }) {
    _momentOfInertia = 0.5 * mass * radius * radius;
    _angularVelocity = 0.0;
    _angle = 0.0;
  }

  /// Apply an angular impulse to the wheel
  void applyImpulse(double angularImpulse) {
    _angularVelocity += angularImpulse / _momentOfInertia;
  }

  /// Update the wheel physics for one time step
  void update(double deltaTime) {
    // Apply friction
    final frictionTorque = -friction * _angularVelocity.sign * mass * 9.81 * radius;
    final angularAcceleration = frictionTorque / _momentOfInertia;

    // Update velocity and angle
    _angularVelocity += angularAcceleration * deltaTime;
    _angle += _angularVelocity * deltaTime;

    // Stop if velocity is very small
    if (_angularVelocity.abs() < 0.01) {
      _angularVelocity = 0.0;
    }
  }

  /// Get current angle
  double get angle => _angle;

  /// Get current angular velocity
  double get angularVelocity => _angularVelocity;

  /// Check if wheel is spinning
  bool get isSpinning => _angularVelocity.abs() > 0.01;
}

/// Easing functions for smooth animations
class EasingFunctions {
  /// Ease out cubic - smooth deceleration
  static num easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }

  /// Ease out quart - smoother deceleration
  static num easeOutQuart(double t) {
    return 1 - pow(1 - t, 4);
  }

  /// Ease out elastic - bouncy effect
  static double easeOutElastic(double t) {
    const c4 = (2 * pi) / 3;
    return t == 0
        ? 0
        : t == 1
        ? 1
        : pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
  }

  /// Ease out bounce - bouncing effect
  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;

    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
      return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
      return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
  }

  /// Custom wheel deceleration curve
  static double wheelDeceleration(double t) {
    // Combines exponential decay with slight bounce at the end
    final exponential = pow(e, -5 * t);
    final bounce = 0.05 * sin(20 * t) * pow(e, -10 * t);
    return exponential + bounce;
  }
}

/// Predefined physics configurations for different wheel behaviors
class WheelPhysicsPresets {
  static WheelPhysicsEngine get realistic => WheelPhysicsEngine(
    friction: 0.015,
    airResistance: 0.0008,
    mass: 2.0,
    radius: 1.2,
  );

  static WheelPhysicsEngine get smooth => WheelPhysicsEngine(
    friction: 0.008,
    airResistance: 0.0005,
    mass: 1.5,
    radius: 1.0,
  );

  static WheelPhysicsEngine get snappy => WheelPhysicsEngine(
    friction: 0.025,
    airResistance: 0.002,
    mass: 0.8,
    radius: 0.9,
  );

  static WheelPhysicsEngine get heavy => WheelPhysicsEngine(
    friction: 0.02,
    airResistance: 0.001,
    mass: 5.0,
    radius: 1.5,
  );

  static WheelPhysicsEngine get light => WheelPhysicsEngine(
    friction: 0.03,
    airResistance: 0.005,
    mass: 0.5,
    radius: 0.8,
  );
}

/// Utility functions for physics calculations
class PhysicsUtils {
  /// Convert degrees to radians
  static double degreesToRadians(double degrees) => degrees * pi / 180;

  /// Convert radians to degrees
  static double radiansToDegrees(double radians) => radians * 180 / pi;

  /// Normalize angle to 0-2π range
  static double normalizeAngle(double angle) {
    while (angle < 0) angle += 2 * pi;
    while (angle >= 2 * pi) angle -= 2 * pi;
    return angle;
  }

  /// Calculate the shortest angular distance between two angles
  static double angularDistance(double from, double to) {
    final diff = normalizeAngle(to - from);
    return diff > pi ? diff - 2 * pi : diff;
  }

  /// Linear interpolation between two values
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  /// Smooth step interpolation
  static double smoothStep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Calculate velocity needed to reach target angle with given deceleration
  static double velocityForTarget(double targetAngle, double deceleration) {
    return sqrt(2 * deceleration.abs() * targetAngle.abs());
  }

  /// Calculate stopping distance given initial velocity and deceleration
  static double stoppingDistance(double initialVelocity, double deceleration) {
    return (initialVelocity * initialVelocity) / (2 * deceleration.abs());
  }
}
