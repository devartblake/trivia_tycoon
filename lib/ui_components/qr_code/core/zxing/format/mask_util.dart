import '../common/bit_matrix.dart';

class MaskUtil {
  /// Applies the inverse of the mask (XOR) to the matrix using the mask pattern index.
  static void unmask(BitMatrix matrix, int maskPattern) {
    final size = matrix.getWidth();
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (_isDataRegion(x, y, size)) {
          if (_maskBit(maskPattern, x, y)) {
            matrix.flip(x, y); // XOR = invert bit
          }
        }
      }
    }
  }

  static bool _isDataRegion(int x, int y, int size) {
    // Skip finder patterns, timing patterns, and alignment patterns.
    // For now, use a rough exclusion for top-left finder area + timing lines.
    if ((x < 9 && y < 9) || // top-left
        (x > size - 9 && y < 9) || // top-right
        (x < 9 && y > size - 9) || // bottom-left
        (x == 6 || y == 6)) {
      return false;
    }
    return true;
  }

  static bool _maskBit(int pattern, int x, int y) {
    switch (pattern) {
      case 0: return (x + y) % 2 == 0;
      case 1: return y % 2 == 0;
      case 2: return x % 3 == 0;
      case 3: return (x + y) % 3 == 0;
      case 4: return ((y ~/ 2) + (x ~/ 3)) % 2 == 0;
      case 5: return ((x * y) % 2 + (x * y) % 3) == 0;
      case 6: return (((x * y) % 2) + ((x * y) % 3)) % 2 == 0;
      case 7: return (((x + y) % 2) + ((x * y) % 3)) % 2 == 0;
      default: return false;
    }
  }
}
