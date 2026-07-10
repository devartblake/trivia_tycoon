import 'package:flutter/foundation.dart';
import '../../../decoder/format_information.dart';
import '../../../decoder/galois_field.dart';
import '../../../decoder/mask_util.dart';
import '../../../decoder/version.dart';
import '../decoder/reed_solomon_decoder.dart';
import '../decoder/decoded_bitstream_parser.dart';
import '../common/bit_matrix.dart';
import '../common/binary_bitmap.dart';

class QrDecoder {
  final ReedSolomonDecoder _ecc = ReedSolomonDecoder(GaloisField.qrField);

  Future<QrDecodeResult?> decode(BinaryBitmap bitmap) async {
    final matrix = bitmap.getBlackMatrix();

    // Step 1: Get version
    final version =
        Version.decode(matrix) ?? Version.fromDimension(matrix.getWidth());
    if (version == null) {
      if (kDebugMode) {
        print('Unsupported version.');
      }
      return null;
    }

    // Step 2: Dummy format info (in production, extract from matrix positions)
    final formatInfo =
        FormatInformation.decode(matrix); // hardcoded error correction + mask

    // Step 3: Unmask matrix using mask pattern (skip for now — assume unmasked)
    MaskUtil.unmask(matrix, formatInfo.maskPattern);

    // Step 4: Read codewords from matrix (basic snake pattern)
    final codewords = _readCodewords(matrix, version);

    // Step 5: Apply Reed-Solomon error correction using the version-specific
    // EC codeword count from the QR standard (ISO/IEC 18004 Table 9).
    // Note: multi-block interleaving is not yet implemented — each block must
    // be processed independently for versions with >1 block per level.
    final corrected = _correctErrors(codewords, version, formatInfo.ecLevel);
    if (corrected == null) {
      if (kDebugMode) print('Error correction failed.');
      return null;
    }

    // Step 6: Interpret bytes (first bytes usually contain metadata + ASCII text)
    final text = DecodedBitStreamParser(corrected).parse();
    return QrDecodeResult(
      text: text,
      version: version.versionNumber,
      maskPattern: formatInfo.maskPattern,
      ecLevel: formatInfo.ecLevel,
    );
  }

  /// Reads raw bytes from the matrix using a snake-like pattern, skipping reserved modules
  List<int> _readCodewords(BitMatrix matrix, Version version) {
    final result = <int>[];
    final size = matrix.getWidth();
    int col = size - 1;
    bool upward = true;
    int bitBuffer = 0, bitCount = 0;

    void addBit(bool bit) {
      bitBuffer = (bitBuffer << 1) | (bit ? 1 : 0);
      bitCount++;
      if (bitCount == 8) {
        result.add(bitBuffer);
        bitBuffer = 0;
        bitCount = 0;
      }
    }

    while (col > 0) {
      if (col == 6) col--; // skip timing column
      for (int i = 0; i < size; i++) {
        final r = upward ? (size - 1 - i) : i;
        for (int c = 0; c < 2; c++) {
          final x = col - c;
          if (!_isReserved(x, r, size, version.versionNumber)) {
            addBit(matrix.get(x, r));
          }
        }
      }
      col -= 2;
      upward = !upward;
    }

    return result;
  }

  bool _isReserved(int x, int y, int size, int version) {
    // Finder patterns + separators (9×9 corners)
    if (x < 9 && y < 9) return true;
    if (x >= size - 8 && y < 9) return true;
    if (x < 9 && y >= size - 8) return true;
    // Timing patterns
    if (x == 6 || y == 6) return true;
    // Format information blocks (always present)
    if ((x < 9 && y == 8) || (x == 8 && y < 9)) return true;
    if ((x >= size - 8 && y == 8) || (x == 8 && y >= size - 8)) return true;
    // Version info blocks (version >= 7)
    if (version >= 7) {
      if (y < 6 && x >= size - 11 && x < size - 8) return true;
      if (x < 6 && y >= size - 11 && y < size - 8) return true;
    }
    // Alignment patterns (version >= 2)
    if (version >= 2) {
      final centers = Version.alignmentPatternCenters(version);
      for (final cy in centers) {
        for (final cx in centers) {
          // Skip alignment patterns that overlap finder corners
          if ((cy < 9 && cx < 9) ||
              (cy < 9 && cx >= size - 8) ||
              (cy >= size - 8 && cx < 9)) {
            continue;
          }
          if ((y - cy).abs() <= 2 && (x - cx).abs() <= 2) return true;
        }
      }
    }
    return false;
  }

  /// Applies Reed-Solomon correction using the correct per-block EC codeword
  /// count for [version] and [ecLevel] from ISO/IEC 18004:2015 Table 9.
  List<int>? _correctErrors(
      List<int> codewords, Version version, String ecLevel) {
    final int ecCodewords = version.ecCodewordsPerBlockFor(ecLevel);
    final copy = List<int>.from(codewords);
    final success = _ecc.decode(copy, ecCodewords);
    return success ? copy : null;
  }
}

class QrDecodeResult {
  final String text;
  final int version;
  final int maskPattern;
  final String ecLevel;

  QrDecodeResult({
    required this.text,
    required this.version,
    required this.maskPattern,
    required this.ecLevel,
  });
}
