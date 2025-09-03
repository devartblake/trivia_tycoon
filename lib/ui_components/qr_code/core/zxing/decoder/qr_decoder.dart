import 'package:flutter/foundation.dart';
import '../format/mask_util.dart';
import '../math/galois_field.dart';
import '../decoder/reed_solomon_decoder.dart';
import '../decoder/decoded_bitstream_parser.dart';
import '../common/bit_matrix.dart';
import '../common/binary_bitmap.dart';
import '../format/format_information.dart';
import '../format/version.dart';

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

    // Step 5: Create DataBlock (no error correction decoding for now)
    final corrected = _correctErrors(codewords);
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
    int row = size - 1;
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

  /// Applies Reed-Solomon correction to codewords (stubbed EC length)
  List<int>? _correctErrors(List<int> codewords) {
    // TODO: Use version info to get EC length dynamically
    const int ecCodewords = 10; // Temporary placeholder
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
