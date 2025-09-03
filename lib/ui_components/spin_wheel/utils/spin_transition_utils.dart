import 'dart:math';

class SpinTransitionUtils {
  /// Calculates the end angle for a random spin ending on the [targetIndex]
  static double calculateTargetAngle({
    required int targetIndex,
    required int totalSegments,
    required double currentAngle,
    int minSpins = 5,
    int maxSpins = 8,
  }) {
    final random = Random();
    final spins = minSpins + random.nextInt(maxSpins - minSpins + 1);
    final fullCircle = 2 * pi;
    final anglePerSegment = fullCircle / totalSegments;

    final targetAngle = fullCircle * spins + anglePerSegment * (totalSegments - targetIndex);
    return currentAngle + targetAngle;
  }

  /// Determines which segment index corresponds to a final rotation [angle]
  static int getSegmentIndexFromAngle(double angle, int totalSegments) {
    final normalized = angle % (2 * pi);
    final anglePerSegment = (2 * pi) / totalSegments;
    return (totalSegments - (normalized / anglePerSegment).floor()) % totalSegments;
  }

  /// Optionally add randomness offset within the selected segment
  static double addOffsetWithinSegment(double angle, int totalSegments) {
    final anglePerSegment = (2 * pi) / totalSegments;
    final random = Random();
    final offset = (random.nextDouble() - 0.5) * anglePerSegment * 0.4; // ±20% of segment
    return angle + offset;
  }
}
