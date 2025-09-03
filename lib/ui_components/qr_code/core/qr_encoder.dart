import '../models/qr_matrix.dart';

class QrEncoder {
  static const int version = 1; // 21x21
  static const int moduleCount = 21;

  QrMatrix encode(String data) {
    final matrix = QrMatrix(moduleCount);

    _addFinderPatterns(matrix);
    _addTimingPatterns(matrix);
    _addDataBits(matrix, _mockDataBits(data)); // Mock for now

    return matrix;
  }

  void _addFinderPatterns(QrMatrix matrix) {
    final positions = [0, matrix.size - 7];

    for (var x in positions) {
      for (var y in positions) {
        if (x == 0 && y == matrix.size - 7) continue; // skip bottom-left
        _drawFinder(matrix, x, y);
      }
    }

    _drawFinder(matrix, 0, matrix.size - 7); // bottom-left
  }

  void _drawFinder(QrMatrix matrix, int startX, int startY) {
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        final isBorder = x == 0 || y == 0 || x == 6 || y == 6;
        final isCenter = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        matrix.set(startX + x, startY + y, isBorder || isCenter);
      }
    }
  }

  void _addTimingPatterns(QrMatrix matrix) {
    for (int i = 8; i < matrix.size - 8; i++) {
      matrix.set(i, 6, i % 2 == 0);
      matrix.set(6, i, i % 2 == 0);
    }
  }

  void _addDataBits(QrMatrix matrix, List<bool> dataBits) {
    int row = matrix.size - 1;
    int col = matrix.size - 1;
    bool upward = true;
    int i = 0;

    while (col > 0) {
      if (col == 6) col--; // skip vertical timing pattern

      for (int j = 0; j < matrix.size; j++) {
        final r = upward ? row - j : j;
        for (int c = 0; c < 2; c++) {
          final x = col - c;
          final y = r;

          if (!_isOccupied(matrix, x, y) && i < dataBits.length) {
            matrix.set(x, y, dataBits[i++]);
          }
        }
      }

      col -= 2;
      upward = !upward;
    }
  }

  bool _isOccupied(QrMatrix matrix, int x, int y) {
    return matrix.get(x, y); // crude version: assume any set bit is occupied
  }

  List<bool> _mockDataBits(String data) {
    // This is a temporary binary converter for demo
    final bytes = data.codeUnits;
    final bits = <bool>[];
    for (var byte in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add((byte & (1 << i)) != 0);
      }
    }

    // Add dummy padding
    while (bits.length < 128) {
      bits.add(false);
    }

    return bits;
  }
}
