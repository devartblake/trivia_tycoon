import '../math/galois_field.dart';
import '../math/gf_poly.dart';

class ReedSolomonDecoder {
  final GaloisField field;

  ReedSolomonDecoder(this.field);

  /// Attempts to correct `numECCodewords` errors in [received].
  /// Modifies the list in-place with corrected values.
  bool decode(List<int> received, int numECCodewords) {
    final poly = GFPoly(field, received);
    final syndrome = List<int>.filled(numECCodewords, 0);
    bool noError = true;

    for (int i = 0; i < numECCodewords; i++) {
      int eval = poly.evaluateAt(field.exp(i))[0];
      syndrome[syndrome.length - 1 - i] = eval;
      if (eval != 0) noError = false;
    }

    if (noError) return true; // No errors

    final syndromePoly = GFPoly(field, syndrome);
    final monomial = GFPoly(field, [1])
        .multiplyByMonomial(numECCodewords, 1);
    final errorLocator = _runEuclideanAlgorithm(monomial, syndromePoly, numECCodewords);

    if (errorLocator == null) return false;

    final errorPositions = _findErrorLocations(errorLocator);
    if (errorPositions == null) return false;

    final errorMagnitudes = _findErrorMagnitudes(
      syndromePoly,
      errorLocator,
      errorPositions,
    );

    for (int i = 0; i < errorPositions.length; i++) {
      final position = received.length - 1 - field.log(errorPositions[i]);
      if (position < 0) return false;
      received[position] ^= errorMagnitudes[i];
    }

    return true;
  }

  GFPoly? _runEuclideanAlgorithm(GFPoly a, GFPoly b, int R) {
    var rLast = a;
    var r = b;
    var tLast = GFPoly(field, [0]);
    var t = GFPoly(field, [1]);

    while (r.degree >= R ~/ 2) {
      if (r.isZero) return null;

      var q = GFPoly(field, [0]);
      var denominatorLeadingTerm = r.getCoefficient(r.degree);
      var dltInverse = field.inverse(denominatorLeadingTerm);

      while (rLast.degree >= r.degree && !rLast.isZero) {
        final degreeDiff = rLast.degree - r.degree;
        final scale = field.multiply(rLast.getCoefficient(rLast.degree), dltInverse);
        final term = r.multiplyByMonomial(degreeDiff, scale);
        q = q.addOrSubtract(GFPoly(field, [...List.filled(degreeDiff, 0), scale]));
        rLast = rLast.addOrSubtract(term);
      }

      final temp = q.multiply(t).addOrSubtract(tLast);
      tLast = t;
      t = temp;
      final tmpR = r;
      r = rLast;
      rLast = tmpR;
    }

    final sigma = t;
    return sigma;
  }

  List<int>? _findErrorLocations(GFPoly errorLocator) {
    final numErrors = errorLocator.degree;
    if (numErrors == 0) return null;

    final result = <int>[];

    for (int i = 1; i < field.size && result.length < numErrors; i++) {
      if (errorLocator.evaluateAt(i)[0] == 0) {
        result.add(field.inverse(i));
      }
    }

    return result.length == numErrors ? result : null;
  }

  List<int> _findErrorMagnitudes(
      GFPoly errorEvaluator,
      GFPoly errorLocator,
      List<int> errorLocations,
      ) {
    final result = <int>[];
    for (var xi in errorLocations) {
      final xiInverse = field.inverse(xi);
      int denominator = 1;

      for (var xj in errorLocations) {
        if (xi != xj) {
          final term = field.multiply(xj, xiInverse);
          denominator = field.multiply(denominator, field.addOrSubtract(1, term));
        }
      }

      final magnitude = field.multiply(
        errorEvaluator.evaluateAt(xiInverse)[0],
        field.inverse(denominator),
      );

      result.add(magnitude);
    }

    return result;
  }
}
