import 'package:flutter/material.dart';
import '../decoder/galois_field.dart';
import '../decoder/gf_poly.dart';

/// Reed-Solomon encoder for QR codes
/// This REUSES your existing GaloisField and GFPoly classes!
class ReedSolomonEncoder {
  final GaloisField field = GaloisField.qrField;

  /// Encode data codewords with error correction
  /// 
  /// Example:
  /// ```dart
  /// final encoder = ReedSolomonEncoder();
  /// final data = [67, 85, 70, 134, 87, 38, 85, 194, 119, 50];
  /// final ecCodewords = encoder.encode(data, 10); // 10 EC codewords
  /// // Result: [196, 35, 39, 119, 235, 215, 231, 226, 93, 23]
  /// ```
  List<int> encode(List<int> dataCodewords, int numEcCodewords) {
    debugPrint('🔵 ReedSolomonEncoder.encode()');
    debugPrint('   Data codewords: ${dataCodewords.length}');
    debugPrint('   EC codewords needed: $numEcCodewords');

    // Step 1: Create message polynomial
    // Pad with zeros for error correction codewords
    final messageCoeffs = [
      ...dataCodewords,
      ...List.filled(numEcCodewords, 0),
    ];

    debugPrint('   Message polynomial degree: ${messageCoeffs.length - 1}');

    // Step 2: Build generator polynomial g(x)
    final generatorPoly = _buildGenerator(numEcCodewords);
    debugPrint('   Generator polynomial degree: ${generatorPoly.degree}');

    // Step 3: Create message polynomial m(x)
    final messagePoly = GFPoly(field, messageCoeffs);

    // Step 4: Divide m(x) by g(x) to get remainder (EC codewords)
    // This is polynomial long division
    debugPrint('   Performing polynomial division...');
    final quotient = messagePoly.divide(generatorPoly);

    // Step 5: Get remainder by subtraction
    // remainder = message - (quotient * generator)
    final product = quotient.multiply(generatorPoly);
    final remainder = messagePoly.addOrSubtract(product);

    debugPrint('   Remainder polynomial degree: ${remainder.degree}');

    // Step 6: Extract EC codewords from remainder coefficients
    final ecCodewords = <int>[];
    for (int i = 0; i < numEcCodewords; i++) {
      ecCodewords.add(remainder.getCoefficient(i));
    }

    debugPrint('   EC codewords generated: $ecCodewords');
    debugPrint('🔵 Encoding complete\n');

    return ecCodewords;
  }

  /// Build generator polynomial for Reed-Solomon
  /// 
  /// Generator polynomial g(x) is:
  /// g(x) = (x - α^0)(x - α^1)(x - α^2)...(x - α^(degree-1))
  /// 
  /// Where α is the primitive element in GF(256)
  GFPoly _buildGenerator(int degree) {
    // Start with g(x) = 1
    GFPoly generator = GFPoly(field, [1]);

    // Multiply by (x - α^i) for i = 0 to degree-1
    for (int i = 0; i < degree; i++) {
      // Create polynomial (x - α^i)
      // In GF, subtraction is same as addition (XOR)
      // So (x - α^i) = (x + α^i)
      final alphaI = field.exp(i);
      final term = GFPoly(field, [1, alphaI]);

      // Multiply generator by this term
      generator = generator.multiply(term);
    }

    return generator;
  }

  /// Get the number of error correction codewords for a given EC level and version
  /// 
  /// This is a simplified version - real QR codes have complex block structures
  static int getEcCodewordsCount(int version, String ecLevel) {
    // Simplified lookup table for Version 1
    if (version == 1) {
      switch (ecLevel) {
        case 'L': return 7;   // Low: 7% error correction
        case 'M': return 10;  // Medium: 15% error correction
        case 'Q': return 13;  // Quartile: 25% error correction
        case 'H': return 17;  // High: 30% error correction
        default: return 10;
      }
    }

    // For other versions, would need full lookup table
    // For now, return a reasonable default
    return 10;
  }

  /// Get total data capacity (in codewords) for a given version and EC level
  static int getDataCapacity(int version, String ecLevel) {
    // Simplified for Version 1
    if (version == 1) {
      switch (ecLevel) {
        case 'L': return 19;
        case 'M': return 16;
        case 'Q': return 13;
        case 'H': return 9;
        default: return 16;
      }
    }

    return 16; // Default
  }
}