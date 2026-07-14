import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/utils/theme_utils.dart';

void main() {
  group('ThemeUtils.getAccentColor', () {
    test('"kids" → pinkAccent', () {
      expect(ThemeUtils.getAccentColor('kids'), Colors.pinkAccent);
    });

    test('"teens" → blueAccent', () {
      expect(ThemeUtils.getAccentColor('teens'), Colors.blueAccent);
    });

    test('"adults" → green', () {
      expect(ThemeUtils.getAccentColor('adults'), Colors.green);
    });

    test('unknown string defaults to blueAccent', () {
      expect(ThemeUtils.getAccentColor('unknown'), Colors.blueAccent);
    });

    test('empty string defaults to blueAccent', () {
      expect(ThemeUtils.getAccentColor(''), Colors.blueAccent);
    });

    test('"Kids" (capitalized) → pinkAccent', () {
      expect(ThemeUtils.getAccentColor('Kids'), Colors.pinkAccent);
    });
  });
}
