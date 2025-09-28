class UnicodeUtils {
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    final codeUnits = <int>[];
    for (int i = 0; i < input.length; i++) {
      final unit = input.codeUnitAt(i);

      // Check for high surrogate
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        // Should be followed by low surrogate
        if (i + 1 < input.length) {
          final nextUnit = input.codeUnitAt(i + 1);
          if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
            // Valid surrogate pair
            codeUnits.add(unit);
            codeUnits.add(nextUnit);
            i++; // Skip next unit
          }
          // Invalid high surrogate without low surrogate - skip
        }
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        // Lone low surrogate - skip
      } else {
        // Regular character
        codeUnits.add(unit);
      }
    }

    return String.fromCharCodes(codeUnits);
  }

  static String replaceProblematicChars(String input) {
    return input
        .replaceAll(RegExp(r'[^\u0000-\uD7FF\uE000-\uFFFF]'), '') // Remove surrogates
        .replaceAll(RegExp(r'[\uFFFE\uFFFF]'), '') // Remove non-characters
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), ''); // Remove control chars
  }
}