import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/color_utils.dart';

void main() {
  // -------------------------------------------------------------------------
  // ColorShade enum
  // -------------------------------------------------------------------------

  group('ColorShade enum', () {
    test('has exactly 10 values', () {
      expect(ColorShade.values.length, 10);
    });

    test('all values are distinct', () {
      expect(ColorShade.values.toSet().length, ColorShade.values.length);
    });

    test('contains lightest and darkest', () {
      expect(ColorShade.values,
          containsAll([ColorShade.lightest, ColorShade.darkest]));
    });
  });

  // -------------------------------------------------------------------------
  // shades map
  // -------------------------------------------------------------------------

  group('shades map', () {
    test('has 10 entries (one per ColorShade value)', () {
      expect(shades.length, 10);
    });

    test('contains all ColorShade values as keys', () {
      for (final shade in ColorShade.values) {
        expect(shades.containsKey(shade), isTrue,
            reason: '$shade missing from shades map');
      }
    });

    test('lightest maps to 50', () {
      expect(shades[ColorShade.lightest], 50);
    });

    test('darkest maps to 900', () {
      expect(shades[ColorShade.darkest], 900);
    });

    test('normal maps to 500', () {
      expect(shades[ColorShade.normal], 500);
    });

    test('all shade values are positive integers', () {
      for (final val in shades.values) {
        expect(val, isPositive);
      }
    });
  });

  // -------------------------------------------------------------------------
  // ColorUtils.shiftHsl
  // -------------------------------------------------------------------------

  group('ColorUtils.shiftHsl', () {
    test('returns a Color', () {
      expect(ColorUtils.shiftHsl(Colors.red), isA<Color>());
    });

    test('positive shift lightens the color', () {
      final original = Colors.red;
      final shifted = ColorUtils.shiftHsl(original, 0.2);
      final origL = HSLColor.fromColor(original).lightness;
      final newL = HSLColor.fromColor(shifted).lightness;
      expect(newL, greaterThan(origL));
    });

    test('negative shift darkens the color', () {
      final original = Colors.red;
      final shifted = ColorUtils.shiftHsl(original, -0.2);
      final origL = HSLColor.fromColor(original).lightness;
      final newL = HSLColor.fromColor(shifted).lightness;
      expect(newL, lessThan(origL));
    });

    test('shift by 1.0 clamps lightness to 1.0', () {
      final shifted = ColorUtils.shiftHsl(Colors.red, 1.0);
      final hsl = HSLColor.fromColor(shifted);
      expect(hsl.lightness, closeTo(1.0, 0.001));
    });

    test('shift by -1.0 clamps lightness to 0.0', () {
      final shifted = ColorUtils.shiftHsl(Colors.red, -1.0);
      final hsl = HSLColor.fromColor(shifted);
      expect(hsl.lightness, closeTo(0.0, 0.001));
    });

    test('zero shift returns equivalent color', () {
      final original = Colors.blue;
      final shifted = ColorUtils.shiftHsl(original, 0);
      expect(HSLColor.fromColor(shifted).lightness,
          closeTo(HSLColor.fromColor(original).lightness, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // ColorUtils.parseHex
  // -------------------------------------------------------------------------

  group('ColorUtils.parseHex', () {
    test('parses "#FF0000" as red', () {
      final c = ColorUtils.parseHex('#FF0000');
      expect(c.red, 255);
      expect(c.green, 0);
      expect(c.blue, 0);
    });

    test('parses "#00FF00" as green', () {
      final c = ColorUtils.parseHex('#00FF00');
      expect(c.red, 0);
      expect(c.green, 255);
      expect(c.blue, 0);
    });

    test('parses "#0000FF" as blue', () {
      final c = ColorUtils.parseHex('#0000FF');
      expect(c.red, 0);
      expect(c.green, 0);
      expect(c.blue, 255);
    });

    test('parses "#FFFFFF" as white', () {
      final c = ColorUtils.parseHex('#FFFFFF');
      expect(c.red, 255);
      expect(c.green, 255);
      expect(c.blue, 255);
    });

    test('parsed color has full alpha', () {
      final c = ColorUtils.parseHex('#123456');
      expect(c.alpha, 255);
    });
  });

  // -------------------------------------------------------------------------
  // ColorUtils.blend
  // -------------------------------------------------------------------------

  group('ColorUtils.blend', () {
    test('blend(white, black, 0.0) returns white', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      final result = ColorUtils.blend(white, black, 0.0);
      expect(result.red, 255);
      expect(result.green, 255);
      expect(result.blue, 255);
    });

    test('blend(white, black, 1.0) returns black', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      final result = ColorUtils.blend(white, black, 1.0);
      expect(result.red, 0);
      expect(result.green, 0);
      expect(result.blue, 0);
    });

    test('blend(white, black, 0.5) returns near-mid-gray', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      final result = ColorUtils.blend(white, black, 0.5);
      expect(result.red, inInclusiveRange(120, 135));
    });

    test('blend result has full alpha', () {
      final result = ColorUtils.blend(Colors.red, Colors.blue, 0.5);
      expect(result.alpha, 255);
    });
  });

  // -------------------------------------------------------------------------
  // estimateBrightnessForColor
  // -------------------------------------------------------------------------

  group('estimateBrightnessForColor', () {
    test('white is Brightness.light', () {
      expect(estimateBrightnessForColor(Colors.white), Brightness.light);
    });

    test('black is Brightness.dark', () {
      expect(estimateBrightnessForColor(Colors.black), Brightness.dark);
    });

    test('yellow is Brightness.light (high luminance)', () {
      expect(estimateBrightnessForColor(Colors.yellow), Brightness.light);
    });

    test('navy/dark blue is Brightness.dark', () {
      expect(
        estimateBrightnessForColor(const Color(0xFF001F5B)),
        Brightness.dark,
      );
    });
  });

  // -------------------------------------------------------------------------
  // darken
  // -------------------------------------------------------------------------

  group('darken', () {
    test('darkens a color (lightness decreases)', () {
      const color = Color(0xFF808080);
      final darkened = darken(color, 0.2);
      final origL = HSLColor.fromColor(color).lightness;
      final newL = HSLColor.fromColor(darkened).lightness;
      expect(newL, lessThan(origL));
    });

    test('darken by 0 returns equivalent lightness', () {
      final color = Colors.green;
      final darkened = darken(color, 0);
      expect(HSLColor.fromColor(darkened).lightness,
          closeTo(HSLColor.fromColor(color).lightness, 0.001));
    });

    test('darken clamps at 0.0 lightness', () {
      final darkened = darken(Colors.black, 0.5);
      expect(HSLColor.fromColor(darkened).lightness, closeTo(0.0, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // lighten
  // -------------------------------------------------------------------------

  group('lighten', () {
    test('lightens a color (lightness increases)', () {
      const color = Color(0xFF808080);
      final lightened = lighten(color, 0.2);
      final origL = HSLColor.fromColor(color).lightness;
      final newL = HSLColor.fromColor(lightened).lightness;
      expect(newL, greaterThan(origL));
    });

    test('lighten by 0 returns equivalent lightness', () {
      final color = Colors.blue;
      final lightened = lighten(color, 0);
      expect(HSLColor.fromColor(lightened).lightness,
          closeTo(HSLColor.fromColor(color).lightness, 0.001));
    });

    test('lighten clamps at 1.0 lightness', () {
      final lightened = lighten(Colors.white, 0.5);
      expect(HSLColor.fromColor(lightened).lightness, closeTo(1.0, 0.001));
    });
  });
}
