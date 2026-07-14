import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/helpers/hex_math_helper.dart';
import 'package:synaptix/core/helpers/matrix_helper.dart';

void main() {
  // -------------------------------------------------------------------------
  // polarOffset — converts polar coordinates to Cartesian Offset
  // -------------------------------------------------------------------------

  group('polarOffset — angle 0°', () {
    test('0° with radius 100 → Offset(100, 0)', () {
      final result = polarOffset(0, 100);
      expect(result.dx, closeTo(100.0, 1e-9));
      expect(result.dy, closeTo(0.0, 1e-9));
    });

    test('0° with radius 50 → Offset(50, 0)', () {
      final result = polarOffset(0, 50);
      expect(result.dx, closeTo(50.0, 1e-9));
      expect(result.dy, closeTo(0.0, 1e-9));
    });

    test('radius 0 always returns Offset.zero', () {
      final result = polarOffset(45, 0);
      expect(result.dx, closeTo(0.0, 1e-9));
      expect(result.dy, closeTo(0.0, 1e-9));
    });
  });

  group('polarOffset — cardinal angles', () {
    test('90° with radius 100 → Offset(≈0, 100)', () {
      final result = polarOffset(90, 100);
      expect(result.dx, closeTo(0.0, 1e-9));
      expect(result.dy, closeTo(100.0, 1e-9));
    });

    test('180° with radius 100 → Offset(-100, ≈0)', () {
      final result = polarOffset(180, 100);
      expect(result.dx, closeTo(-100.0, 1e-9));
      expect(result.dy, closeTo(0.0, 1e-9));
    });

    test('270° with radius 100 → Offset(≈0, -100)', () {
      final result = polarOffset(270, 100);
      expect(result.dx, closeTo(0.0, 1e-9));
      expect(result.dy, closeTo(-100.0, 1e-9));
    });

    test('360° equals 0°', () {
      final at0 = polarOffset(0, 80);
      final at360 = polarOffset(360, 80);
      expect(at360.dx, closeTo(at0.dx, 1e-9));
      expect(at360.dy, closeTo(at0.dy, 1e-9));
    });
  });

  group('polarOffset — 45° diagonal', () {
    test('45° dx and dy are equal and positive', () {
      final result = polarOffset(45, 100);
      expect(result.dx, closeTo(cos(pi / 4) * 100, 1e-9));
      expect(result.dy, closeTo(sin(pi / 4) * 100, 1e-9));
      expect(result.dx, closeTo(result.dy, 1e-9));
    });
  });

  // -------------------------------------------------------------------------
  // perspective — returns a Matrix4 with perspective entry set
  // -------------------------------------------------------------------------

  group('perspective — default weight', () {
    test('default weight is 0.001', () {
      final m = perspective();
      expect(m.entry(3, 2), closeTo(0.001, 1e-12));
    });

    test('identity entries are unchanged (0,0), (1,1), (2,2), (3,3)', () {
      final m = perspective();
      expect(m.entry(0, 0), closeTo(1.0, 1e-12));
      expect(m.entry(1, 1), closeTo(1.0, 1e-12));
      expect(m.entry(2, 2), closeTo(1.0, 1e-12));
      expect(m.entry(3, 3), closeTo(1.0, 1e-12));
    });

    test('off-diagonal entries are 0 except (3,2)', () {
      final m = perspective();
      expect(m.entry(0, 1), closeTo(0.0, 1e-12));
      expect(m.entry(1, 0), closeTo(0.0, 1e-12));
      expect(m.entry(2, 3), closeTo(0.0, 1e-12));
    });
  });

  group('perspective — custom weight', () {
    test('weight 0.005 → entry(3,2) == 0.005', () {
      final m = perspective(0.005);
      expect(m.entry(3, 2), closeTo(0.005, 1e-12));
    });

    test('weight 0 → entry(3,2) == 0 (flat projection)', () {
      final m = perspective(0);
      expect(m.entry(3, 2), closeTo(0.0, 1e-12));
    });

    test('weight 0.01 → entry(3,2) == 0.01', () {
      final m = perspective(0.01);
      expect(m.entry(3, 2), closeTo(0.01, 1e-12));
    });
  });
}
