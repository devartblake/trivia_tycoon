import '../core/zxing/common/bit_matrix.dart';

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
    0x15683: 21,
    0x168C9: 22,
    0x177EC: 23,
    0x18EC4: 24,
    0x191E1: 25,
    0x1AFAB: 26,
    0x1B08E: 27,
    0x1CC1A: 28,
    0x1D33F: 29,
    0x1ED75: 30,
    0x1F250: 31,
    0x209D5: 32,
    0x216F0: 33,
    0x228BA: 34,
    0x2379F: 35,
    0x24B45: 36,
    0x2542E: 37,
    0x26A64: 38,
    0x27541: 39,
    0x28C69: 40,
  };

  // -------------------------------------------------------------------------
  // EC codewords per block — ISO/IEC 18004:2015 Table 9
  //
  // Key   = version number (1–40)
  // Value = { ecLevel ('L'|'M'|'Q'|'H') → EC codewords per block }
  //
  // All blocks within a given (version, level) share the same EC codeword
  // count. For single-block versions this equals the total EC codewords in
  // the symbol. For multi-block versions the decoder must process each block
  // independently using this per-block count.
  // -------------------------------------------------------------------------
  static const Map<int, Map<String, int>> _ecCodewordsPerBlock = {
    1: {'L': 7, 'M': 10, 'Q': 13, 'H': 17},
    2: {'L': 10, 'M': 16, 'Q': 22, 'H': 28},
    3: {'L': 15, 'M': 26, 'Q': 18, 'H': 22},
    4: {'L': 20, 'M': 18, 'Q': 26, 'H': 16},
    5: {'L': 26, 'M': 24, 'Q': 18, 'H': 22},
    6: {'L': 18, 'M': 16, 'Q': 24, 'H': 28},
    7: {'L': 20, 'M': 18, 'Q': 18, 'H': 26},
    8: {'L': 24, 'M': 22, 'Q': 22, 'H': 26},
    9: {'L': 30, 'M': 22, 'Q': 20, 'H': 24},
    10: {'L': 18, 'M': 26, 'Q': 24, 'H': 28},
    11: {'L': 20, 'M': 30, 'Q': 28, 'H': 24},
    12: {'L': 24, 'M': 22, 'Q': 26, 'H': 28},
    13: {'L': 26, 'M': 22, 'Q': 24, 'H': 22},
    14: {'L': 30, 'M': 24, 'Q': 20, 'H': 24},
    15: {'L': 22, 'M': 24, 'Q': 30, 'H': 24},
    16: {'L': 24, 'M': 28, 'Q': 24, 'H': 30},
    17: {'L': 28, 'M': 28, 'Q': 28, 'H': 28},
    18: {'L': 30, 'M': 26, 'Q': 28, 'H': 28},
    19: {'L': 28, 'M': 26, 'Q': 26, 'H': 26},
    20: {'L': 28, 'M': 26, 'Q': 30, 'H': 28},
    21: {'L': 28, 'M': 26, 'Q': 28, 'H': 30},
    22: {'L': 28, 'M': 28, 'Q': 30, 'H': 24},
    23: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    24: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    25: {'L': 26, 'M': 28, 'Q': 30, 'H': 30},
    26: {'L': 28, 'M': 28, 'Q': 28, 'H': 30},
    27: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    28: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    29: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    30: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    31: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    32: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    33: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    34: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    35: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    36: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    37: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    38: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    39: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
    40: {'L': 30, 'M': 28, 'Q': 30, 'H': 30},
  };

  /// Returns the number of EC codewords per block for this version and
  /// [ecLevel] ('L', 'M', 'Q', or 'H'). Falls back to 10 (version 1–M) if
  /// the combination is not found in the table.
  int ecCodewordsPerBlockFor(String ecLevel) {
    return _ecCodewordsPerBlock[versionNumber]?[ecLevel] ?? 10;
  }

  /// Returns the alignment pattern center coordinates for [version].
  /// ISO/IEC 18004:2015 Annex E defines centers for each version.
  static List<int> alignmentPatternCenters(int version) {
    const centers = {
      2: [6, 18],
      3: [6, 22],
      4: [6, 26],
      5: [6, 30],
      6: [6, 34],
      7: [6, 22, 38],
      8: [6, 24, 42],
      9: [6, 26, 46],
      10: [6, 28, 50],
      11: [6, 30, 54],
      12: [6, 32, 58],
      13: [6, 34, 62],
      14: [6, 26, 46, 66],
      15: [6, 26, 48, 70],
      16: [6, 26, 50, 74],
      17: [6, 30, 54, 78],
      18: [6, 30, 56, 82],
      19: [6, 30, 58, 86],
      20: [6, 34, 62, 90],
      21: [6, 28, 50, 72, 94],
      22: [6, 26, 50, 74, 98],
      23: [6, 30, 54, 78, 102],
      24: [6, 28, 54, 80, 106],
      25: [6, 32, 58, 84, 110],
      26: [6, 30, 58, 86, 114],
      27: [6, 34, 62, 90, 118],
      28: [6, 26, 50, 74, 98, 122],
      29: [6, 30, 54, 78, 102, 126],
      30: [6, 26, 52, 78, 104, 130],
      31: [6, 30, 56, 82, 108, 134],
      32: [6, 34, 60, 86, 112, 138],
      33: [6, 30, 58, 86, 114, 142],
      34: [6, 34, 62, 90, 118, 146],
      35: [6, 30, 54, 78, 102, 126, 150],
      36: [6, 24, 50, 76, 102, 128, 154],
      37: [6, 28, 54, 80, 106, 132, 158],
      38: [6, 32, 58, 84, 110, 136, 162],
      39: [6, 26, 54, 82, 110, 138, 166],
      40: [6, 30, 58, 86, 114, 142, 170],
    };
    return centers[version] ?? [];
  }
}
