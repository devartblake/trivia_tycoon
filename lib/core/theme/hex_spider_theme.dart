import 'package:flutter/material.dart';

/// Single source of truth for the background theme.
enum HexSpiderTheme { brand, jamaica, usa, pinterest, neon, monochrome }

class HexSpiderPalette {
  final Color bg0;
  final Color bg1;
  final Color grid;
  final List<Color> ringGradient;
  final List<Color> rayGradient;

  const HexSpiderPalette({
    required this.bg0,
    required this.bg1,
    required this.grid,
    required this.ringGradient,
    required this.rayGradient,
  });
}

// You can tweak these to match your brand:
const _brand = HexSpiderPalette(
  bg0: Color(0xFF0D1021),
  bg1: Color(0xFF101432),
  grid: Color(0x33FFFFFF),
  ringGradient: [Color(0x3357C7FF), Color(0x0057C7FF)],
  rayGradient:  [Color(0x33A77BFF), Color(0x00A77BFF)],
);

const _jamaica = HexSpiderPalette(
  bg0: Color(0xFF00230E),
  bg1: Color(0xFF003919),
  grid: Color(0x3342B72A),
  ringGradient: [Color(0x33FFD700), Color(0x00FFD700)],
  rayGradient:  [Color(0x3300A859), Color(0x0000A859)],
);

const _usa = HexSpiderPalette(
  bg0: Color(0xFF0B1020),
  bg1: Color(0xFF111632),
  grid: Color(0x334477AA),
  ringGradient: [Color(0x33CC0000), Color(0x00CC0000)],
  rayGradient:  [Color(0x332266AA), Color(0x002266AA)],
);

const _pinterest = HexSpiderPalette(
  bg0: Color(0xFF281016),
  bg1: Color(0xFF3A1420),
  grid: Color(0x33E60023),
  ringGradient: [Color(0x33E60023), Color(0x00E60023)],
  rayGradient:  [Color(0x33FFD1CF), Color(0x00FFD1CF)],
);

const _neon = HexSpiderPalette(
  bg0: Color(0xFF030712),
  bg1: Color(0xFF0A0F1F),
  grid: Color(0x3328F0A5),
  ringGradient: [Color(0x3328F0A5), Color(0x0000FFC2)],
  rayGradient:  [Color(0x333B82F6), Color(0x003B82F6)],
);

const _mono = HexSpiderPalette(
  bg0: Color(0xFF0E0E10),
  bg1: Color(0xFF141418),
  grid: Color(0x33333333),
  ringGradient: [Color(0x33333333), Color(0x00333333)],
  rayGradient:  [Color(0x33999999), Color(0x00999999)],
);

HexSpiderPalette paletteFor(HexSpiderTheme t) {
  switch (t) {
    case HexSpiderTheme.brand:     return _brand;
    case HexSpiderTheme.jamaica:   return _jamaica;
    case HexSpiderTheme.usa:       return _usa;
    case HexSpiderTheme.pinterest: return _pinterest;
    case HexSpiderTheme.neon:      return _neon;
    case HexSpiderTheme.monochrome:return _mono;
  }
}
