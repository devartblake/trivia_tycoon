import '../core/zxing/common/bit_matrix.dart';

class FormatInformation {
  final String ecLevel; // 'L', 'M', 'Q', 'H'
  final int maskPattern;

  FormatInformation(this.ecLevel, this.maskPattern);

  static const _formatMask = 0x5412;

  static FormatInformation decode(BitMatrix matrix) {
    final bits1 = _readFormatBits(matrix, true);
    final bits2 = _readFormatBits(matrix, false);

    final decoded1 = _decodeFormatBits(bits1 ^ _formatMask);
    final decoded2 = _decodeFormatBits(bits2 ^ _formatMask);

    // ✅ Try Hamming fallback if both null
    if (decoded1 == null && decoded2 == null) {
      return _fallbackByHamming(bits1) ??
          _fallbackByHamming(bits2) ??
          FormatInformation('M', 0);
    }

    return decoded1 ?? decoded2 ?? FormatInformation('M', 0);
  }

  static int _readBit(BitMatrix matrix, int x, int y) =>
      matrix.get(x, y) ? 1 : 0;

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

  static FormatInformation? _decodeFormatBits(int unmaskedBits) {
    final entry = _formatTable[unmaskedBits & 0x7FFF];
    return entry == null ? null : FormatInformation(entry.ec, entry.mask);
  }

  static FormatInformation? _fallbackByHamming(int maskedBits) {
    final unm = maskedBits ^ _formatMask;
    int minDist = 4;
    FormatInformation? best;

    for (final code in _formatTable.keys) {
      final dist = _hamming(unm, code);
      if (dist < minDist) {
        minDist = dist;
        final entry = _formatTable[code];
        if (entry != null) best = FormatInformation(entry.ec, entry.mask);
      }
    }

    return best;
  }

  static int _hamming(int a, int b) {
    return (a ^ b).toRadixString(2).replaceAll('0', '').length;
  }

  static final Map<int, _FmtEntry> _formatTable = {
    // M (EC=00)
    0x5412: _FmtEntry('M', 0), 0x5125: _FmtEntry('M', 1),
    0x5E7C: _FmtEntry('M', 2), 0x5B4B: _FmtEntry('M', 3),
    0x45F9: _FmtEntry('M', 4), 0x40CE: _FmtEntry('M', 5),
    0x4F97: _FmtEntry('M', 6), 0x4AA0: _FmtEntry('M', 7),
    // L (EC=01)
    0x77C4: _FmtEntry('L', 0), 0x72F3: _FmtEntry('L', 1),
    0x7DAA: _FmtEntry('L', 2), 0x789D: _FmtEntry('L', 3),
    0x662F: _FmtEntry('L', 4), 0x6318: _FmtEntry('L', 5),
    0x6C41: _FmtEntry('L', 6), 0x6976: _FmtEntry('L', 7),
    // H (EC=10)
    0x1689: _FmtEntry('H', 0), 0x13BE: _FmtEntry('H', 1),
    0x1CE7: _FmtEntry('H', 2), 0x19D0: _FmtEntry('H', 3),
    0x07C2: _FmtEntry('H', 4), 0x04B5: _FmtEntry('H', 5),
    0x0B3C: _FmtEntry('H', 6), 0x0EE3: _FmtEntry('H', 7),
    // Q (EC=11)
    0x355F: _FmtEntry('Q', 0), 0x3068: _FmtEntry('Q', 1),
    0x3B31: _FmtEntry('Q', 2), 0x3E06: _FmtEntry('Q', 3),
    0x20B4: _FmtEntry('Q', 4), 0x25C3: _FmtEntry('Q', 5),
    0x2AAA: _FmtEntry('Q', 6), 0x2F9D: _FmtEntry('Q', 7),
  };
}

class _FmtEntry {
  final String ec;
  final int mask;
  _FmtEntry(this.ec, this.mask);
}
