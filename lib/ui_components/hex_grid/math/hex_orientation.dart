import 'dart:math';

enum HexOrientation { pointy, flat }

extension HexagonTypeExtension on HexOrientation {
  static final double _ratioPointy = (sqrt(3) / 2);
  static final double _ratioFlat = 1 / _ratioPointy;

  /// Hexagon width to height ratio
  double get ratio {
    if (isFlat) return _ratioFlat;
    return _ratioPointy;
  }

  /// Returns true for POINTY;
  bool get isPointy => this == HexOrientation.pointy;

  /// Returns true for FLAT;
  bool get isFlat => this == HexOrientation.flat;

  double flatFactor(bool inBounds) => (isFlat && inBounds == false) ? 0.75 : 1;

  double pointyFactor(bool inBounds) =>
      (isPointy && inBounds == false) ? 0.75 : 1;
}