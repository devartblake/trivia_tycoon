import 'galois_field.dart';

class GFPoly {
  final GaloisField field;
  final List<int> coefficients;

  GFPoly(this.field, List<int> coeffs)
      : coefficients = _stripLeadingZeros(coeffs) {
    if (coefficients.isEmpty) throw ArgumentError("Zero-length polynomial");
  }

  static List<int> _stripLeadingZeros(List<int> coeffs) {
    int firstNonZero = coeffs.indexWhere((c) => c != 0);
    return firstNonZero == -1 ? [0] : coeffs.sublist(firstNonZero);
  }

  int get degree => coefficients.length - 1;

  bool get isZero => coefficients[0] == 0;

  int getCoefficient(int degree) {
    return coefficients[coefficients.length - 1 - degree];
  }

  GFPoly addOrSubtract(GFPoly other) {
    if (field != other.field) {
      throw ArgumentError('Polynomials do not have same Galois field');
    }

    final smaller = coefficients.length > other.coefficients.length ? other : this;
    final larger = this == smaller ? other : this;

    final sum = List<int>.from(larger.coefficients);
    final diff = larger.coefficients.length - smaller.coefficients.length;

    for (int i = 0; i < smaller.coefficients.length; i++) {
      sum[i + diff] = field.addOrSubtract(smaller.coefficients[i], sum[i + diff]);
    }

    return GFPoly(field, sum);
  }

  GFPoly multiply(GFPoly other) {
    if (field != other.field) {
      throw ArgumentError('Polynomials do not have same Galois field');
    }

    final result = List<int>.filled(coefficients.length + other.coefficients.length - 1, 0);

    for (int i = 0; i < coefficients.length; i++) {
      int aCoeff = coefficients[i];
      for (int j = 0; j < other.coefficients.length; j++) {
        result[i + j] ^= field.multiply(aCoeff, other.coefficients[j]);
      }
    }

    return GFPoly(field, result);
  }

  GFPoly multiplyScalar(int scalar) {
    if (scalar == 0) return GFPoly(field, [0]);
    if (scalar == 1) return this;

    final product = coefficients.map((c) => field.multiply(c, scalar)).toList();
    return GFPoly(field, product);
  }

  GFPoly multiplyByMonomial(int degree, int coefficient) {
    if (coefficient == 0) return GFPoly(field, [0]);

    final result = List<int>.filled(coefficients.length + degree, 0);
    for (int i = 0; i < coefficients.length; i++) {
      result[i] = field.multiply(coefficients[i], coefficient);
    }

    return GFPoly(field, result);
  }

  GFPoly divide(GFPoly other) {
    if (field != other.field) {
      throw ArgumentError('Polynomials do not have same Galois field');
    }
    if (other.isZero) {
      throw ArgumentError('Divide by 0 polynomial');
    }

    GFPoly quotient = GFPoly(field, [0]);
    GFPoly remainder = this;

    final denominatorLeadingTerm = other.getCoefficient(other.degree);
    final inverseDenominatorLeadingTerm = field.inverse(denominatorLeadingTerm);

    while (remainder.degree >= other.degree && !remainder.isZero) {
      final degreeDiff = remainder.degree - other.degree;
      final scale = field.multiply(remainder.getCoefficient(remainder.degree), inverseDenominatorLeadingTerm);
      final term = other.multiplyByMonomial(degreeDiff, scale);
      final iterationQuotient = GFPoly(
        field,
        [...List.filled(degreeDiff, 0), scale],
      );

      quotient = quotient.addOrSubtract(iterationQuotient);
      remainder = remainder.addOrSubtract(term);
    }

    return quotient;
  }

  List<int> evaluateAt(int a) {
    if (a == 0) return [coefficients.last];
    if (a == 1) return [coefficients.reduce((a, b) => field.addOrSubtract(a, b))];

    int result = coefficients[0];
    for (int i = 1; i < coefficients.length; i++) {
      result = field.addOrSubtract(field.multiply(a, result), coefficients[i]);
    }
    return [result];
  }
}
