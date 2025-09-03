import '../common/bit_matrix.dart';

class FormatInformation {
  final String ecLevel; // 'L', 'M', 'Q', 'H'
  final int maskPattern;

  FormatInformation(this.ecLevel, this.maskPattern);

  static const _formatMask = 0x5412;

  static final Map<int, String> _ecLevelMap = {
    0: 'M', // 0b00
    1: 'L', // 0b01
    2: 'H', // 0b10
    3: 'Q', // 0b11
  };

  static FormatInformation decode(BitMatrix matrix) {
    final bits1 = _readFormatBits(matrix, true);
    final bits2 = _readFormatBits(matrix, false);

    final decoded1 = _decodeFormatBits(bits1 ^ _formatMask);
    final decoded2 = _decodeFormatBits(bits2 ^ _formatMask);

    // ✅ Try Hamming fallback if both null
    if (decoded1 == null && decoded2 == null) {
      return _fallbackByHamming(bits1) ?? _fallbackByHamming(bits2) ?? FormatInformation('M', 0);
    }

    return decoded1 ?? decoded2 ?? FormatInformation('M', 0);
  }

  static int _readBit(BitMatrix matrix, int x, int y) => matrix.get(x, y) ? 1 : 0;

  static int _readFormatBits(BitMatrix matrix, bool primary) {
    int bits = 0;
    if (primary) {
      for (int i = 0; i <= 5; i++) {
        bits = (bits << 1) | _readBit(matrix, i, 8);
      }
      bits = (bits << 1) | _readBit(matrix, 7, 8);
      bits = (bits << 1) | _readBit(matrix, 8, 8);
      bits = (bits << 1) | _readBit(matrix, 8, 7);
      for (int i = 5; i >= 0; i--) {
        bits = (bits << 1) | _readBit(matrix, 8, i);
      }
    } else {
      final size = matrix.getWidth();
      for (int i = size - 1; i >= size - 8; i--) {
        bits = (bits << 1) | _readBit(matrix, 8, i);
      }
      for (int i = size - 8; i < size; i++) {
        bits = (bits << 1) | _readBit(matrix, i, 8);
      }
    }
    return bits;
  }

  static FormatInformation? _decodeFormatBits(int bits) {
    final ecBits = (bits >> 3) & 0x03;  // 0x03 = binary 00000011
    final maskBits = bits & 0x07;       // 0x07 = binary 00000111

    final level = _ecLevelMap[ecBits];
    if (level == null || maskBits > 7) return null;

    return FormatInformation(level, maskBits);
  }

  static FormatInformation? _fallbackByHamming(int maskedBits) {
    final unm = maskedBits ^ _formatMask;
    int minDist = 4;
    FormatInformation? best;

    for (final code in _formatPatterns.keys) {
      final dist = _hamming(unm, code);
      if (dist < minDist) {
        minDist = dist;
        final ecBits = (code >> 3) & 0x03;
        final maskBits = code & 0x07;
        final level = _ecLevelMap[ecBits];
        if (level != null) best = FormatInformation(level, maskBits);
      }
    }

    return best;
  }

  static int _hamming(int a, int b) {
    return (a ^ b).toRadixString(2).replaceAll('0', '').length;
  }

  static final Map<int, String> _formatPatterns = {
    0x77C4: 'L0', 0x72F3: 'L1', 0x7DAA: 'L2', 0x789D: 'L3',
    0x662F: 'L4', 0x6318: 'L5', 0x6C41: 'L6', 0x6976: 'L7',
    // ... other EC/mask combos
  };
}
