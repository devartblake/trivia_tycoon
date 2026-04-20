import 'dart:convert';
import 'unicode_utils.dart';

class InputValidator {
  static bool isValidUnicode(String input) {
    try {
      // Try to encode/decode to catch issues
      final bytes = utf8.encode(input);
      final decoded = utf8.decode(bytes);
      return decoded == input;
    } catch (e) {
      return false;
    }
  }

  static String cleanInput(String input) {
    if (isValidUnicode(input)) {
      return input;
    }
    return UnicodeUtils.sanitizeString(input);
  }

  static String safeString(String input) {
    try {
      // First sanitize, then validate
      final sanitized = UnicodeUtils.sanitizeString(input);
      return isValidUnicode(sanitized) ? sanitized : _fallbackClean(input);
    } catch (e) {
      return _fallbackClean(input);
    }
  }

  static String _fallbackClean(String input) {
    // Last resort: replace any problematic characters with safe alternatives
    return input.replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\uFFFF]'), '?');
  }
}
