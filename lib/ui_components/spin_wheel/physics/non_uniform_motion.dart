import 'dart:math' as math;

/// Enhanced non-uniform circular motion physics with performance optimizations
class EnhancedNonUniformMotion {
  final double resistance;
  final double minDuration;
  final double maxDuration;
  final bool enableRealism;

  // Cached values for performance
  late final double _acceleration;
  late final double _twoPi;
  late final double _negativeSeven;

  EnhancedNonUniformMotion({
    required this.resistance,
    this.minDuration = 0.5,
    this.maxDuration = 8.0,
    this.enableRealism = true,
  }) {
    // Cache expensive calculations
    _twoPi = 2 * math.pi;
    _negativeSeven = -7.0;
    _acceleration = resistance * _negativeSeven * math.pi;
  }

  /// Cached acceleration value for performance
  double get acceleration => _acceleration;

  /// Calculate distance traveled with given velocity and time
  double calculateDistance(double velocity, double time) {
    if (!enableRealism) {
      // Simple linear calculation for better performance
      return velocity * time * 0.7; // Reduced factor for similar visual effect
    }

    // Realistic physics: s = ut + (1/2)at²
    return (velocity * time) + (0.5 * acceleration * time * time);
  }

  /// Calculate spin duration based on initial velocity
  double calculateDuration(double velocity) {
    if (!enableRealism) {
      // Simple duration mapping for performance
      final normalizedVelocity = velocity.clamp(1.0, 20.0);
      return (normalizedVelocity / 20.0) * (maxDuration - minDuration) + minDuration;
    }

    // Realistic physics: t = -v/a (when final velocity = 0)
    final duration = -velocity / acceleration;
    return duration.clamp(minDuration, maxDuration);
  }

  /// Normalize angle to 0-2π range (optimized)
  double normalizeAngle(double angle) {
    // Use modulo operator which is more efficient than conditional checks
    final normalized = angle % _twoPi;
    return normalized < 0 ? normalized + _twoPi : normalized;
  }

  /// Calculate angle per segment (cached calculation)
  double anglePerSegment(int segmentCount) {
    assert(segmentCount > 0, 'Segment count must be positive');
    return _twoPi / segmentCount;
  }

  /// Calculate final velocity at given time
  double finalVelocity(double initialVelocity, double time) {
    if (!enableRealism) {
      // Simple linear decay
      final decay = math.max(0.0, 1.0 - (time / maxDuration));
      return initialVelocity * decay;
    }

    // Realistic physics: v = u + at
    return math.max(0.0, initialVelocity + (acceleration * time));
  }

  /// Calculate velocity at any point during the motion
  double velocityAtTime(double initialVelocity, double time) {
    return finalVelocity(initialVelocity, time);
  }

  /// Calculate kinetic energy at given velocity
  double kineticEnergy(double velocity, {double mass = 1.0}) {
    return 0.5 * mass * velocity * velocity;
  }

  /// Calculate work done by friction
  double workDoneByFriction(double initialVelocity, double finalVelocity, {double mass = 1.0}) {
    final initialKE = kineticEnergy(initialVelocity, mass: mass);
    final finalKE = kineticEnergy(finalVelocity, mass: mass);
    return initialKE - finalKE;
  }

  /// Predict landing segment with enhanced accuracy
  int predictLandingSegment({
    required double initialAngle,
    required double initialVelocity,
    required int segmentCount,
    bool addRandomness = true,
  }) {
    final duration = calculateDuration(initialVelocity);
    final distance = calculateDistance(initialVelocity, duration);
    final finalAngle = normalizeAngle(initialAngle + distance);

    final segmentAngle = anglePerSegment(segmentCount);
    int baseSegment = (finalAngle / segmentAngle).floor();

    if (addRandomness && enableRealism) {
      // Add slight randomness for fairness (±5% of segment angle)
      final randomOffset = (math.Random().nextDouble() - 0.5) * segmentAngle * 0.1;
      final adjustedAngle = normalizeAngle(finalAngle + randomOffset);
      baseSegment = (adjustedAngle / segmentAngle).floor();
    }

    return baseSegment % segmentCount;
  }

  /// Calculate deceleration curve value at normalized time (0-1)
  double decelerationCurve(double normalizedTime) {
    if (!enableRealism) {
      // Simple ease-out curve
      return 1.0 - (normalizedTime * normalizedTime);
    }

    // Realistic exponential decay
    return math.exp(-3.0 * normalizedTime);
  }

  /// Create physics data for analysis
  MotionAnalysis analyzeMotion({
    required double initialVelocity,
    required double initialAngle,
    int samplePoints = 10,
  }) {
    final duration = calculateDuration(initialVelocity);
    final finalDistance = calculateDistance(initialVelocity, duration);
    final samples = <MotionSample>[];

    for (int i = 0; i <= samplePoints; i++) {
      final t = (i / samplePoints) * duration;
      final distance = calculateDistance(initialVelocity, t);
      final velocity = velocityAtTime(initialVelocity, t);
      final angle = normalizeAngle(initialAngle + distance);

      samples.add(MotionSample(
        time: t,
        angle: angle,
        velocity: velocity,
        distance: distance,
      ));
    }

    return MotionAnalysis(
      initialVelocity: initialVelocity,
      initialAngle: initialAngle,
      duration: duration,
      finalDistance: finalDistance,
      finalAngle: normalizeAngle(initialAngle + finalDistance),
      samples: samples,
    );
  }

  /// Factory constructors for common configurations
  factory EnhancedNonUniformMotion.realistic({double resistance = 0.015}) {
    return EnhancedNonUniformMotion(
      resistance: resistance,
      enableRealism: true,
      minDuration: 1.0,
      maxDuration: 6.0,
    );
  }

  factory EnhancedNonUniformMotion.performance({double resistance = 0.015}) {
    return EnhancedNonUniformMotion(
      resistance: resistance,
      enableRealism: false,
      minDuration: 0.8,
      maxDuration: 4.0,
    );
  }

  factory EnhancedNonUniformMotion.arcade({double resistance = 0.012}) {
    return EnhancedNonUniformMotion(
      resistance: resistance,
      enableRealism: false,
      minDuration: 1.5,
      maxDuration: 5.0,
    );
  }

  @override
  String toString() {
    return 'EnhancedNonUniformMotion(resistance: $resistance, realism: $enableRealism)';
  }
}

/// Data class for motion sample points
class MotionSample {
  final double time;
  final double angle;
  final double velocity;
  final double distance;

  const MotionSample({
    required this.time,
    required this.angle,
    required this.velocity,
    required this.distance,
  });

  @override
  String toString() {
    return 'MotionSample(t: ${time.toStringAsFixed(2)}s, '
        'v: ${velocity.toStringAsFixed(2)}, '
        'θ: ${(angle * 180 / math.pi).toStringAsFixed(1)}°)';
  }
}

/// Comprehensive motion analysis data
class MotionAnalysis {
  final double initialVelocity;
  final double initialAngle;
  final double duration;
  final double finalDistance;
  final double finalAngle;
  final List<MotionSample> samples;

  const MotionAnalysis({
    required this.initialVelocity,
    required this.initialAngle,
    required this.duration,
    required this.finalDistance,
    required this.finalAngle,
    required this.samples,
  });

  /// Get peak velocity from samples
  double get peakVelocity {
    return samples.map((s) => s.velocity).reduce(math.max);
  }

  /// Get total rotations
  double get totalRotations {
    return finalDistance / (2 * math.pi);
  }

  /// Get average velocity
  double get averageVelocity {
    if (samples.isEmpty) return 0.0;
    final totalVelocity = samples.map((s) => s.velocity).reduce((a, b) => a + b);
    return totalVelocity / samples.length;
  }

  /// Get velocity at specific time (interpolated)
  double velocityAtTime(double time) {
    if (samples.isEmpty) return 0.0;
    if (time <= 0) return samples.first.velocity;
    if (time >= duration) return samples.last.velocity;

    // Find bracketing samples
    for (int i = 0; i < samples.length - 1; i++) {
      final current = samples[i];
      final next = samples[i + 1];

      if (time >= current.time && time <= next.time) {
        // Linear interpolation
        final t = (time - current.time) / (next.time - current.time);
        return current.velocity + t * (next.velocity - current.velocity);
      }
    }

    return samples.last.velocity;
  }

  @override
  String toString() {
    return 'MotionAnalysis(duration: ${duration.toStringAsFixed(2)}s, '
        'rotations: ${totalRotations.toStringAsFixed(1)}, '
        'samples: ${samples.length})';
  }
}

/// Enhanced physics utilities with performance optimizations
class PhysicsUtils {
  // Cached constants for performance
  static const double _radiansPerDegree = math.pi / 180.0;
  static const double _degreesPerRadian = 180.0 / math.pi;

  /// Convert pixels per second to radians per second (optimized)
  static double pixelsPerSecondToRadians(double pps, {double radius = 100.0}) {
    return pps / radius;
  }

  /// Convert radians per second to pixels per second (optimized)
  static double radiansPerSecondToPixels(double rps, {double radius = 100.0}) {
    return rps * radius;
  }

  /// Convert degrees to radians (cached constant)
  static double degreesToRadians(double degrees) {
    return degrees * _radiansPerDegree;
  }

  /// Convert radians to degrees (cached constant)
  static double radiansToDegrees(double radians) {
    return radians * _degreesPerRadian;
  }

  /// Calculate angular acceleration from linear acceleration
  static double linearToAngularAcceleration(double linearAcceleration, double radius) {
    return linearAcceleration / radius;
  }

  /// Calculate centripetal force
  static double centripetalForce(double mass, double velocity, double radius) {
    return mass * velocity * velocity / radius;
  }

  /// Calculate moment of inertia for a disk
  static double momentOfInertia(double mass, double radius) {
    return 0.5 * mass * radius * radius;
  }

  /// Calculate angular momentum
  static double angularMomentum(double momentOfInertia, double angularVelocity) {
    return momentOfInertia * angularVelocity;
  }

  /// Interpolate between two angles (handles wrapping)
  static double interpolateAngles(double from, double to, double t) {
    final twoPi = 2 * math.pi;

    // Normalize angles
    from = from % twoPi;
    to = to % twoPi;

    // Find shortest path
    double diff = to - from;
    if (diff > math.pi) {
      diff -= twoPi;
    } else if (diff < -math.pi) {
      diff += twoPi;
    }

    return (from + diff * t) % twoPi;
  }

  /// Calculate energy loss due to friction
  static double energyLoss(double initialVelocity, double finalVelocity, double mass) {
    return 0.5 * mass * (initialVelocity * initialVelocity - finalVelocity * finalVelocity);
  }

  /// Smooth step function for animations
  static double smoothStep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Smoother step function for more natural animations
  static double smootherStep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
  }
}