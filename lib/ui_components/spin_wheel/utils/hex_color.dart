import 'dart:ui';

class HexColor extends Color {
  HexColor(final String hex) : super(_parseHex(hex));

  static int _parseHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // add full opacity if not provided
    return int.parse(hex, radix: 16);
  }

  /// ✅ Static helper method to match your model use
  static Color fromHex(String hexString) {
    return HexColor(hexString);
  }

  static String toHex(Color color, {bool leadingHashSign = true}) {
    final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '${leadingHashSign ? '#' : ''}$hex';
  }
}
