import '../common/bit_matrix.dart';
import 'dart:math';

class FinderPattern {
  final double x;
  final double y;

  FinderPattern(this.x, this.y);
}

class FinderPatternFinder {
  final BitMatrix matrix;
  final int height;
  final int width;

  FinderPatternFinder(this.matrix)
      : height = matrix.getHeight(),
        width = matrix.getWidth();

  List<FinderPattern> find() {
    final patterns = <FinderPattern>[];

    for (int y = 0; y < height; y++) {
      int stateCount = 0;
      int currentState = 0;

      for (int x = 0; x < width; x++) {
        if (matrix.get(x, y)) {
          if (currentState % 2 == 0) {
            currentState++;
          }
        } else {
          if (currentState % 2 == 1) {
            currentState++;
          }
        }

        if (currentState == 5) {
          // crude estimation of center
          final centerX = x - 2;
          final centerY = y;

          if (_isFinderPattern(centerX, centerY)) {
            patterns.add(FinderPattern(centerX.toDouble(), centerY.toDouble()));
          }

          currentState = 0;
        }
      }
    }

    return patterns;
  }

  bool _isFinderPattern(int x, int y) {
    // This is where we’d analyze a 7x7 block for the 1:1:3:1:1 ratio
    // For now we’ll simplify it
    return true;
  }
}
