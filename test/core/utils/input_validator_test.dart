import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/input_validator.dart';

void main() {
  // -------------------------------------------------------------------------
  // isValidUnicode
  // -------------------------------------------------------------------------

  group('InputValidator.isValidUnicode', () {
    test('pure ASCII is valid', () {
      expect(InputValidator.isValidUnicode('Hello, world!'), isTrue);
    });

    test('empty string is valid', () {
      expect(InputValidator.isValidUnicode(''), isTrue);
    });

    test('standard Unicode characters are valid', () {
      expect(InputValidator.isValidUnicode('café résumé'), isTrue);
    });

    test('emoji (surrogate pair in some environments) is handled', () {
      // isValidUnicode tries utf8.encode/decode; standard strings pass
      expect(InputValidator.isValidUnicode('Hello 😀'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // cleanInput
  // -------------------------------------------------------------------------

  group('InputValidator.cleanInput', () {
    test('valid input is returned unchanged', () {
      const input = 'Valid ASCII input';
      expect(InputValidator.cleanInput(input), input);
    });

    test('empty string is returned as-is', () {
      expect(InputValidator.cleanInput(''), '');
    });

    test('valid Unicode is returned unchanged', () {
      const input = 'résumé';
      expect(InputValidator.cleanInput(input), input);
    });
  });

  // -------------------------------------------------------------------------
  // safeString
  // -------------------------------------------------------------------------

  group('InputValidator.safeString', () {
    test('valid ASCII passes through unchanged', () {
      expect(InputValidator.safeString('safe input'), 'safe input');
    });

    test('empty string passes through', () {
      expect(InputValidator.safeString(''), '');
    });

    test('valid Unicode passes through', () {
      expect(InputValidator.safeString('naïve'), 'naïve');
    });

    test('string with lone surrogate is sanitized (no exception thrown)', () {
      final lone = String.fromCharCode(0xD800);
      expect(() => InputValidator.safeString(lone), returnsNormally);
    });
  });
}
