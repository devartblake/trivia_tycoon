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
    final dimension = matrix.getWidth();

    // Step 1: Get version
    final version = Version.decode(matrix) ?? Version.fromDimension(matrix.getWidth());
    if (version == null) {
      if (kDebugMode) { print('Unsupported version.'); }
      return null;
    }

    // Step 2: Dummy format info (in production, extract from matrix positions)
    final formatInfo = FormatInformation.decode(matrix); // hardcoded error correction + mask

    // Step 3: Unmask matrix using mask pattern (skip for now — assume unmasked)
    MaskUtil.unmask(matrix, formatInfo.maskPattern);

    // Step 4: Read codewords from matrix (basic snake pattern)
    final codewords = _readCodewords(matrix);

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

  /// Reads raw bytes from the matrix using a snake-like pattern
  List<int> _readCodewords(BitMatrix matrix) {
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
          final y = r;
          addBit(matrix.get(x, y));
        }
      }
      col -= 2;
      upward = !upward;
    }

    return result;
  }

  /// Applies Reed-Solomon correction using the correct per-block EC codeword
  /// count for [version] and [ecLevel] from ISO/IEC 18004:2015 Table 9.
  List<int>? _correctErrors(List<int> codewords, Version version, String ecLevel) {
    final int ecCodewords = version.ecCodewordsPerBlockFor(ecLevel);
    final copy = List<int>.from(codewords);
    final success = _ecc.decode(copy, ecCodewords);
    return success ? copy : null;
  }

  String _decodeBytes(List<int> bytes) {
    final buffer = StringBuffer();

    // Basic byte-mode decoder for demo (skipping ECI, Kanji, etc.)
    for (final b in bytes) {
      if (b >= 32 && b <= 126) {
        buffer.writeCharCode(b);
      }
    }
    return buffer.toString();
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
