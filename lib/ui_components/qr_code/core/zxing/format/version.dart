import '../common/bit_matrix.dart';

class Version {
  final int versionNumber;

  Version(this.versionNumber);

  /// For Version 1–6, infer from matrix size
  static Version? fromDimension(int size) {
    if ((size - 17) % 4 != 0) return null;
    final num = (size - 17) ~/ 4 + 1;
    return Version(num);
  }

  /// For Version ≥ 7: read version bits from matrix
  static Version? decode(BitMatrix matrix) {
    final dimension = matrix.getWidth();
    if (dimension < 45) return null; // Version 1–6 have no version bits

    int bits1 = 0, bits2 = 0;
    for (int y = 0; y < 6; y++) {
      for (int x = dimension - 11; x <= dimension - 9; x++) {
        bits1 = (bits1 << 1) | (matrix.get(x, y) ? 1 : 0);
        bits2 = (bits2 << 1) | (matrix.get(y, x) ? 1 : 0);
      }
    }

    final ver1 = _decodeVersionBits(bits1);
    final ver2 = _decodeVersionBits(bits2);

    return ver1 ?? ver2;
  }

  /// Decode version bits into a version number (use Hamming distance check)
  static Version? _decodeVersionBits(int bits) {
    for (final entry in _versionPatterns.entries) {
      final distance = _hamming(bits, entry.key);
      if (distance <= 3) return Version(entry.value); // tolerate ≤3 errors
    }
    return null;
  }

  static int _hamming(int a, int b) {
    return (a ^ b).toRadixString(2).replaceAll('0', '').length;
  }

  static final Map<int, int> _versionPatterns = {
    0x07C94: 7,
    0x085BC: 8,
    0x09A99: 9,
    0x0A4D3: 10,
    0x0BBF6: 11,
    0x0C762: 12,
    0x0D847: 13,
    0x0E60D: 14,
    0x0F928: 15,
    0x10B78: 16,
    0x1145D: 17,
    0x12A17: 18,
    0x13532: 19,
    0x149A6: 20,
    // ... up to version 40
  };
}
