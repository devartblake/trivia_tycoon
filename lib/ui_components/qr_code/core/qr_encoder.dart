import '../models/qr_matrix.dart';
import 'dart:math';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class QrEncoder {
  static const int version = 1; // 21x21
  static const int moduleCount = 21;

  QrMatrix encode(String data) {
    LogManager.debug('🔵 QrEncoder.encode() called');
    LogManager.debug('   Data: $data');
    LogManager.debug('   Data length: ${data.length}');

    final matrix = QrMatrix(moduleCount);
    LogManager.debug('   Matrix created: ${matrix.size}x${matrix.size}');

    _addFinderPatterns(matrix);
    LogManager.debug('   Finder patterns added');

    _addTimingPatterns(matrix);
    LogManager.debug('   Timing patterns added');

    final dataBits = _mockDataBits(data);
    LogManager.debug('   Data bits generated: ${dataBits.length} bits');

    _addDataBits(matrix, dataBits);
    LogManager.debug('   Data bits added to matrix');

    // Add some debug info
    int setCount = 0;
    for (int y = 0; y < matrix.size; y++) {
      for (int x = 0; x < matrix.size; x++) {
        if (matrix.get(x, y)) setCount++;
      }
    }
    LogManager.debug(
        '   Total modules set: $setCount out of ${matrix.size * matrix.size}');
    LogManager.debug('🔵 Encoding complete\n');

    return matrix;
  }

  void _addFinderPatterns(QrMatrix matrix) {
    // Top-left
    _drawFinder(matrix, 0, 0);

    // Top-right
    _drawFinder(matrix, matrix.size - 7, 0);

    // Bottom-left
    _drawFinder(matrix, 0, matrix.size - 7);
  }

  void _drawFinder(QrMatrix matrix, int startX, int startY) {
    // Outer border (7x7)
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        final isBorder = x == 0 || y == 0 || x == 6 || y == 6;
        final isCenter = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        matrix.set(startX + x, startY + y, isBorder || isCenter);
      }
    }

    // Add separator (white border around finder)
    for (int i = 0; i < 8; i++) {
      if (startX == 0 && startY == 0) {
        // Top-left separator
        matrix.set(7, i, false);
        matrix.set(i, 7, false);
      } else if (startX > 0 && startY == 0) {
        // Top-right separator
        matrix.set(startX - 1, i, false);
        matrix.set(startX + i, 7, false);
      } else if (startX == 0 && startY > 0) {
        // Bottom-left separator
        matrix.set(i, startY - 1, false);
        matrix.set(7, startY + i, false);
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
    int bitIndex = 0;

    // Fill in a zigzag pattern from bottom-right
    for (int col = matrix.size - 1; col > 0; col -= 2) {
      if (col == 6) col--; // Skip timing column

      for (int row = 0; row < matrix.size; row++) {
        for (int c = 0; c < 2; c++) {
          int x = col - c;
          int y = (col > 6 && ((col - 7) ~/ 2) % 2 == 0)
              ? matrix.size - 1 - row
              : row;

          if (!_isReserved(matrix, x, y) && bitIndex < dataBits.length) {
            matrix.set(x, y, dataBits[bitIndex]);
            bitIndex++;
          }
        }
      }
    }

    LogManager.debug('   Placed $bitIndex data bits');
  }

  bool _isReserved(QrMatrix matrix, int x, int y) {
    // Check if this position is used by finder patterns or timing patterns

    // Finder patterns (including separators)
    if ((x < 8 && y < 8) || // Top-left
        (x >= matrix.size - 8 && y < 8) || // Top-right
        (x < 8 && y >= matrix.size - 8)) {
      // Bottom-left
      return true;
    }

    // Timing patterns
    if (x == 6 || y == 6) {
      return true;
    }

    return false;
  }

  List<bool> _mockDataBits(String data) {
    // Enhanced mock: Create a more visible pattern
    final bits = <bool>[];

    // Add header (mode + length)
    // Mode: 0100 (byte mode)
    bits.addAll([false, true, false, false]);

    // Length: 8 bits for character count
    final charCount = min(data.length, 255);
    for (int i = 7; i >= 0; i--) {
      bits.add((charCount & (1 << i)) != 0);
    }

    // Add actual data
    for (var char in data.codeUnits) {
      for (int i = 7; i >= 0; i--) {
        bits.add((char & (1 << i)) != 0);
      }
    }

    // Add terminator (0000)
    bits.addAll([false, false, false, false]);

    // Pad to required length
    // For version 1 with low error correction, we need about 152 bits
    while (bits.length < 152) {
      bits.addAll([true, true, true, false, true, true, false, false]); // 0xEC
      if (bits.length < 152) {
        bits.addAll(
            [false, false, false, true, false, false, false, true]); // 0x11
      }
    }

    // Ensure we have enough bits but not too many
    if (bits.length > 152) {
      bits.removeRange(152, bits.length);
    }

    LogManager.debug(
        'Generated ${bits.length} data bits from ${data.length} chars');

    return bits;
  }
}
