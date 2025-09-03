import 'package:flutter/material.dart';

enum ColorShade {
  lightest,
  secondLightest,
  thirdLightest,
  fourthLightest,
  fifthLightest,
  normal,
  fourthDarkest,
  thirdDarkest,
  secondDarkest,
  darkest,
}

const Map<ColorShade, int> shades = {
  ColorShade.lightest: 50,
  ColorShade.secondLightest: 100,
  ColorShade.thirdLightest: 200,
  ColorShade.fourthLightest: 300,
  ColorShade.fifthLightest: 400,
  ColorShade.normal: 500,
  ColorShade.fourthDarkest: 600,
  ColorShade.thirdDarkest: 700,
  ColorShade.secondDarkest: 800,
  ColorShade.darkest: 900,
};

class ColorUtils {
  static Color shiftHsl(Color c, [double amt = 0]) {
    var hslc = HSLColor.fromColor(c);
    return hslc.withLightness((hslc.lightness + amt).clamp(0.0, 1.0)).toColor();
  }

  static Color parseHex(String value) => Color(int.parse(value.substring(1, 7), radix: 16) + 0xFF000000);

  static Color blend(Color dst, Color src, double opacity) {
    return Color.fromARGB(
      255,
      (dst.r.toDouble() * (1.0 - opacity) + src.r.toDouble() * opacity).toInt(),
      (dst.g.toDouble() * (1.0 - opacity) + src.g.toDouble() * opacity).toInt(),
      (dst.b.toDouble() * (1.0 - opacity) + src.b.toDouble() * opacity).toInt(),
    );
  }
}

MaterialColor getMaterialColor(Color color) {
  return Colors.primaries.firstWhere(
        (c) => c.r == color.r && c.g == color.g && c.b == color.b,
    orElse: () => MaterialColor(
      color.value,
      Map.fromEntries(
        shades.entries.map(
              (entry) => MapEntry(entry.value, Color.fromRGBO(color.red, color.green, color.blue, 1)),
        ),
      ),
    ),
  );
}

/// Determines whether the given [Color] is [Brightness.light] or [Brightness.dark].
/// Copied from [ThemeData.estimateBrightnessForColor(color)]
/// Changed [kThreshold] from 0.15 to 0.45 to accept more colors with [Brightness.dark].
Brightness estimateBrightnessForColor(Color color) {
  final relativeLuminance = color.computeLuminance();
  const double kThreshold = 0.45;
  return (relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold
      ? Brightness.light
      : Brightness.dark;
}

/// Gets the dark shades version of the given color.
List<Color> getDarkShades(
    Color color, [
      ColorShade minShade = ColorShade.fifthLightest,
    ]) {
  final materialColor = color is MaterialColor ? color : getMaterialColor(color);
  final List<Color> darkShades = [];

  for (final shade in shades.values) {
    if (shade < shades[minShade]!) continue;

    final Color? colorShade = materialColor[shade];
    if (colorShade != null && estimateBrightnessForColor(colorShade) == Brightness.dark) {
      darkShades.add(colorShade);
    }
  }

  return darkShades.isNotEmpty
      ? darkShades
      : [materialColor[shades[ColorShade.darkest]!]!];
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1.');

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1.');

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}