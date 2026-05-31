import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/helpers/login_color_helper.dart';

void main() {
  // -------------------------------------------------------------------------
  // ColorShade enum
  // -------------------------------------------------------------------------

  group('ColorShade enum', () {
    test('has exactly 10 values', () {
      expect(ColorShade.values, hasLength(10));
    });

    test('shades map has 10 entries', () {
      expect(shades.length, 10);
    });

    test('lightest shade is 50', () {
      expect(shades[ColorShade.lightest], 50);
    });

    test('darkest shade is 900', () {
      expect(shades[ColorShade.darkest], 900);
    });

    test('normal shade is 500', () {
      expect(shades[ColorShade.normal], 500);
    });

    test('shade values are monotonically increasing', () {
      final values = ColorShade.values.map((s) => shades[s]!).toList();
      for (int i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
    });
  });

  // -------------------------------------------------------------------------
  // estimateBrightnessForColor
  // -------------------------------------------------------------------------

  group('estimateBrightnessForColor', () {
    test('white → Brightness.light', () {
      expect(estimateBrightnessForColor(Colors.white), Brightness.light);
    });

    test('black → Brightness.dark', () {
      expect(estimateBrightnessForColor(Colors.black), Brightness.dark);
    });

    test('blue → Brightness.dark (low luminance)', () {
      expect(estimateBrightnessForColor(Colors.blue), Brightness.dark);
    });

    test('yellow (high luminance) → Brightness.light', () {
      expect(estimateBrightnessForColor(Colors.yellow), Brightness.light);
    });
  });

  // -------------------------------------------------------------------------
  // darken
  // -------------------------------------------------------------------------

  group('darken', () {
    test('darkened color has lower luminance than original', () {
      final original = Colors.blue;
      final darkened = darken(original, 0.1);
      expect(darkened.computeLuminance(),
          lessThan(original.computeLuminance()));
    });

    test('darken by 0 returns same luminance', () {
      final original = Colors.blue;
      final result = darken(original, 0.0);
      expect(result.computeLuminance(),
          closeTo(original.computeLuminance(), 1e-6));
    });

    test('darken clamps lightness at 0 (does not go negative)', () {
      final black = Colors.black;
      final result = darken(black, 0.5);
      expect(result.computeLuminance(), greaterThanOrEqualTo(0.0));
    });

    test('darken 0.2 > darken 0.1 (more darkening)', () {
      final original = Colors.teal;
      final darker1 = darken(original, 0.1);
      final darker2 = darken(original, 0.2);
      expect(darker2.computeLuminance(),
          lessThan(darker1.computeLuminance()));
    });
  });

  // -------------------------------------------------------------------------
  // lighten
  // -------------------------------------------------------------------------

  group('lighten', () {
    test('lightened color has higher luminance than original', () {
      final original = Colors.blue;
      final lightened = lighten(original, 0.1);
      expect(lightened.computeLuminance(),
          greaterThan(original.computeLuminance()));
    });

    test('lighten by 0 returns same luminance', () {
      final original = Colors.blue;
      final result = lighten(original, 0.0);
      expect(result.computeLuminance(),
          closeTo(original.computeLuminance(), 1e-6));
    });

    test('lighten clamps lightness at 1 (does not exceed white)', () {
      final white = Colors.white;
      final result = lighten(white, 0.5);
      expect(result.computeLuminance(), closeTo(1.0, 1e-3));
    });

    test('lighten 0.2 > lighten 0.1 (more lightening)', () {
      final original = Colors.teal;
      final lighter1 = lighten(original, 0.1);
      final lighter2 = lighten(original, 0.2);
      expect(lighter2.computeLuminance(),
          greaterThan(lighter1.computeLuminance()));
    });
  });

  // -------------------------------------------------------------------------
  // getMaterialColor
  // -------------------------------------------------------------------------

  group('getMaterialColor', () {
    test('returns a MaterialColor for a non-primary color', () {
      const custom = Color(0xFF123456);
      final result = getMaterialColor(custom);
      expect(result, isA<MaterialColor>());
    });

    test('custom color MaterialColor contains all 10 shade keys', () {
      const custom = Color(0xFF654321);
      final mc = getMaterialColor(custom);
      for (final shade in shades.values) {
        expect(mc[shade], isNotNull, reason: 'shade $shade missing');
      }
    });

    test('MaterialColor from custom color returns that color at each shade', () {
      const custom = Color(0xFFABCDEF);
      final mc = getMaterialColor(custom);
      for (final shade in shades.values) {
        expect(mc[shade], custom);
      }
    });
  });

  // -------------------------------------------------------------------------
  // getDarkShades
  // -------------------------------------------------------------------------

  group('getDarkShades', () {
    test('returns non-empty list for a mid-tone color', () {
      final shadeList = getDarkShades(Colors.blue);
      expect(shadeList, isNotEmpty);
    });

    test('all returned shades are dark (Brightness.dark)', () {
      final shadeList = getDarkShades(Colors.blue);
      for (final color in shadeList) {
        if (color != null) {
          expect(
            estimateBrightnessForColor(color),
            Brightness.dark,
            reason: 'expected dark shade',
          );
        }
      }
    });
  });
}
