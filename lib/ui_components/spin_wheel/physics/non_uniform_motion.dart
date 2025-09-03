import 'dart:math';

class NonUniformCircularMotion {
  final double resistance;

  NonUniformCircularMotion({required this.resistance});

  double get acceleration => resistance * -7 * pi;

  double distance(double velocity, double time) =>
      (velocity * time) + (0.5 * acceleration * pow(time, 2));

  double duration(double velocity) => -velocity / acceleration;

  double modulo(double angle) => angle % (2 * pi);

  double anglePerDivision(int dividers) => (2 * pi) / dividers;
}

double pixelsPerSecondToRadians(double pps) {
  return (pps * 2 * pi) / 1000;
}