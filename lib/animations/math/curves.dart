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
  double transform(double x) {
    // A modified version of ElasticOutCurve with the oscillation centered around 0.5
    return math.pow(2.0, -10.0 * x) * math.sin(x * 2.0 * math.pi / period) + 0.5;
  }
}

class CenteredElasticInCurve extends Curve {
  final double period;

  const CenteredElasticInCurve([this.period = 0.4]);

  @override
  double transform(double x) {
    // Basically just a slightly modified version of the built in ElasticInCurve
    return -math.pow(2.0, 10.0 * (x - 1.0)) * math.sin((x - 1.0) * 2.0 * math.pi / period) + 0.5;
  }
}

class LinearPointCurve extends Curve {
  final double pIn;
  final double pOut;

  const LinearPointCurve(this.pIn, this.pOut);

  @override
  double transform(double x) {
    // Just a simple bit of linear interpolation math
    final lowerScale = pOut / pIn;
    final upperScale = (1.0 - pOut) / (1.0 - pIn);
    final upperOffset = 1.0 - upperScale;
    return x < pIn ? x * lowerScale : x * upperScale + upperOffset;
  }
}

class PiecewiseLinearCurve extends Curve {
  final List<double> points;

  PiecewiseLinearCurve(this.points)
      : assert(points.isNotEmpty && points.first == 0 && points.last == 1);

  @override
  double transform(double x) {
    assert(x >= 0 && x <= 1, 'x must be between 0 and 1');
    for (int i = 0; i < points.length - 1; i++) {
      if (x >= points[i] && x <= points[i + 1]) {
        final scale = (x - points[i]) / (points[i + 1] - points[i]);
        return points[i] + scale * (points[i + 1] - points[i]);
      }
    }
    return 1.0; // Should never reach here due to the input validation.
  }
}
