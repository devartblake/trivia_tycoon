import 'dart:math';

class FinderPattern {
  final double x;
  final double y;
  final double estimatedModuleSize;

  const FinderPattern(this.x, this.y, this.estimatedModuleSize);

  Point<double> get point => Point(x, y);
}
