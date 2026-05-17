import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// A custom elastic-out curve centered around the midpoint.
/// This curve produces an elastic effect as the animation progresses,
/// with a slight oscillation and then deceleration.
///
/// [period] controls the frequency of the oscillations.
class CenteredElasticOutCurve extends Curve {
  final double period;

  const CenteredElasticOutCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    // A modified version of ElasticOutCurve with the oscillation centered around 0.5
    return math.pow(2.0, -10.0 * t) * math.sin(t * 2.0 * math.pi / period) +
        0.5;
  }
}

class CenteredElasticInCurve extends Curve {
  final double period;

  const CenteredElasticInCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    // Basically just a slightly modified version of the built in ElasticInCurve
    return -math.pow(2.0, 10.0 * (t - 1.0)) *
            math.sin((t - 1.0) * 2.0 * math.pi / period) +
        0.5;
  }
}

class LinearPointCurve extends Curve {
  final double pIn;
  final double pOut;

  const LinearPointCurve(this.pIn, this.pOut);

  @override
  double transform(double t) {
    // Just a simple bit of linear interpolation math
    final lowerScale = pOut / pIn;
    final upperScale = (1.0 - pOut) / (1.0 - pIn);
    final upperOffset = 1.0 - upperScale;
    return t < pIn ? t * lowerScale : t * upperScale + upperOffset;
  }
}

class PiecewiseLinearCurve extends Curve {
  final List<double> points;

  PiecewiseLinearCurve(this.points)
      : assert(points.isNotEmpty && points.first == 0 && points.last == 1);

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1, 't must be between 0 and 1');
    for (int i = 0; i < points.length - 1; i++) {
      if (t >= points[i] && t <= points[i + 1]) {
        final scale = (t - points[i]) / (points[i + 1] - points[i]);
        return points[i] + scale * (points[i + 1] - points[i]);
      }
    }
    return 1.0; // Should never reach here due to the input validation.
  }
}
