import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/helpers/dart_helper.dart';
import 'package:synaptix/core/helpers/math_helper.dart';

void main() {
  // -------------------------------------------------------------------------
  // math_helper.dart
  // -------------------------------------------------------------------------

  group('toRadian', () {
    test('0 degrees → 0 radians', () {
      expect(toRadian(0), 0.0);
    });

    test('180 degrees → π radians', () {
      expect(toRadian(180), closeTo(pi, 1e-10));
    });

    test('90 degrees → π/2 radians', () {
      expect(toRadian(90), closeTo(pi / 2, 1e-10));
    });

    test('360 degrees → 2π radians', () {
      expect(toRadian(360), closeTo(2 * pi, 1e-10));
    });

    test('negative degrees produces negative radians', () {
      expect(toRadian(-90), closeTo(-pi / 2, 1e-10));
    });
  });

  group('lerp', () {
    test('50% between 0 and 100 → 50', () {
      expect(lerp(0, 100, 0.5), 50.0);
    });

    test('0% → start value', () {
      expect(lerp(10, 20, 0.0), 10.0);
    });

    test('100% → end value', () {
      expect(lerp(10, 20, 1.0), 20.0);
    });

    test('25% between 0 and 200 → 50', () {
      expect(lerp(0, 200, 0.25), 50.0);
    });

    test('works with negative values', () {
      expect(lerp(-100, 100, 0.5), closeTo(0, 1e-10));
    });

    test('start == end → same value regardless of percent', () {
      expect(lerp(42, 42, 0.7), 42.0);
    });
  });

  // -------------------------------------------------------------------------
  // dart_helper.dart
  // -------------------------------------------------------------------------

  group('isNullOrEmpty', () {
    test('null → true', () {
      expect(isNullOrEmpty(null), isTrue);
    });

    test('empty string → true', () {
      expect(isNullOrEmpty(''), isTrue);
    });

    test('non-empty string → false', () {
      expect(isNullOrEmpty('hello'), isFalse);
    });

    test('whitespace-only string → false (whitespace is not empty)', () {
      expect(isNullOrEmpty('   '), isFalse);
    });

    test('single character → false', () {
      expect(isNullOrEmpty('x'), isFalse);
    });
  });
}
