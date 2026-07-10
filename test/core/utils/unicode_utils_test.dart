import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/unicode_utils.dart';

void main() {
  // -------------------------------------------------------------------------
  // sanitizeString
  // -------------------------------------------------------------------------

  group('UnicodeUtils.sanitizeString', () {
    test('empty string returns empty string', () {
      expect(UnicodeUtils.sanitizeString(''), '');
    });

    test('pure ASCII string is returned unchanged', () {
      expect(UnicodeUtils.sanitizeString('Hello, world!'), 'Hello, world!');
    });

    test('regular Unicode characters are preserved', () {
      expect(UnicodeUtils.sanitizeString('café'), 'café');
    });

    test('lone high surrogate (0xD800–0xDBFF) without low surrogate is removed',
        () {
      // Build a string with a lone high surrogate (codeUnit 0xD800)
      final lone = String.fromCharCode(0xD800);
      final result = UnicodeUtils.sanitizeString(lone);
      expect(result, '');
    });

    test('lone low surrogate (0xDC00–0xDFFF) is removed', () {
      final lone = String.fromCharCode(0xDC00);
      final result = UnicodeUtils.sanitizeString(lone);
      expect(result, '');
    });

    test('valid surrogate pair is preserved', () {
      // A valid emoji is a surrogate pair: 0xD83D 0xDE00 = 😀
      final emoji = '😀';
      final result = UnicodeUtils.sanitizeString(emoji);
      expect(result, emoji);
    });

    test('mixed: ASCII + lone surrogate → ASCII preserved, surrogate removed',
        () {
      final lone = String.fromCharCode(0xD800);
      final input = 'abc${lone}xyz';
      final result = UnicodeUtils.sanitizeString(input);
      expect(result, 'abcxyz');
    });

    test('valid pair followed by ASCII is both preserved', () {
      final emoji = '😀';
      final result = UnicodeUtils.sanitizeString('${emoji}ok');
      expect(result.length, greaterThan(0));
      expect(result.endsWith('ok'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // replaceProblematicChars
  // -------------------------------------------------------------------------

  group('UnicodeUtils.replaceProblematicChars', () {
    test('clean ASCII is returned unchanged', () {
      expect(UnicodeUtils.replaceProblematicChars('Hello!'), 'Hello!');
    });

    test('control characters (U+0000–U+001F) are removed', () {
      final withControl = 'abc\x00\x1Fxyz';
      expect(UnicodeUtils.replaceProblematicChars(withControl), 'abcxyz');
    });

    test('non-character U+FFFE is removed', () {
      final withNonChar = 'ab￾cd';
      expect(UnicodeUtils.replaceProblematicChars(withNonChar), 'abcd');
    });

    test('non-character U+FFFF is removed', () {
      final withNonChar = 'ab￿cd';
      expect(UnicodeUtils.replaceProblematicChars(withNonChar), 'abcd');
    });

    test('empty string returns empty string', () {
      expect(UnicodeUtils.replaceProblematicChars(''), '');
    });

    test('regular Unicode in U+00A0–U+FFFD range is preserved', () {
      expect(UnicodeUtils.replaceProblematicChars('café©'), 'café©');
    });
  });
}
