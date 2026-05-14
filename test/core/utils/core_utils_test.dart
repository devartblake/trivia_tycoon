import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/question_schema_validator.dart';
import 'package:trivia_tycoon/core/utils/unicode_utils.dart';
import 'package:trivia_tycoon/core/utils/input_validator.dart';
import 'package:trivia_tycoon/core/utils/crypto_address_validator.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_network.dart';

Map<String, dynamic> _validQuestion() => {
      'id': 'q1',
      'question': 'What?',
      'correctAnswer': 'A',
      'answers': ['A', 'B'],
      'type': 'text',
      'quizFormat': 'multiple_choice',
      'difficulty': 1,
      'category': 'general',
    };

void main() {
  // -------------------------------------------------------------------------
  // QuestionSchemaValidator
  // -------------------------------------------------------------------------

  group('QuestionSchemaValidator', () {
    test('valid map returns true', () {
      expect(QuestionSchemaValidator.isValid(_validQuestion()), isTrue);
    });

    test('empty map returns false', () {
      expect(QuestionSchemaValidator.isValid({}), isFalse);
    });

    for (final field in [
      'id',
      'question',
      'correctAnswer',
      'answers',
      'type',
      'quizFormat',
      'difficulty',
      'category',
    ]) {
      test('missing required field "$field" returns false', () {
        final map = Map<String, dynamic>.from(_validQuestion())..remove(field);
        expect(QuestionSchemaValidator.isValid(map), isFalse);
      });
    }

    test('answers as non-List returns false', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['answers'] = 'notAList';
      expect(QuestionSchemaValidator.isValid(map), isFalse);
    });

    test('answers as empty List returns false', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['answers'] = <dynamic>[];
      expect(QuestionSchemaValidator.isValid(map), isFalse);
    });

    test('invalid type value returns false', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['type'] = 'gif';
      expect(QuestionSchemaValidator.isValid(map), isFalse);
    });

    test('invalid quizFormat returns false', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['quizFormat'] = 'unknown_format';
      expect(QuestionSchemaValidator.isValid(map), isFalse);
    });

    test('type "image" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['type'] = 'image';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });

    test('type "video" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['type'] = 'video';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });

    test('type "audio" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['type'] = 'audio';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });

    test('quizFormat "true_false" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['quizFormat'] = 'true_false';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });

    test('quizFormat "fill_in_the_blanks" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['quizFormat'] = 'fill_in_the_blanks';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });

    test('quizFormat "match_pair" is valid', () {
      final map = Map<String, dynamic>.from(_validQuestion())
        ..['quizFormat'] = 'match_pair';
      expect(QuestionSchemaValidator.isValid(map), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // UnicodeUtils
  // -------------------------------------------------------------------------

  group('UnicodeUtils.sanitizeString', () {
    test('empty string returns empty', () {
      expect(UnicodeUtils.sanitizeString(''), '');
    });

    test('normal ASCII string is unchanged', () {
      expect(UnicodeUtils.sanitizeString('hello'), 'hello');
    });

    test('valid unicode is preserved', () {
      expect(UnicodeUtils.sanitizeString('café'), 'café');
    });
  });

  group('UnicodeUtils.replaceProblematicChars', () {
    test('empty string returns empty', () {
      expect(UnicodeUtils.replaceProblematicChars(''), '');
    });

    test('normal ASCII string is unchanged', () {
      expect(UnicodeUtils.replaceProblematicChars('hello world'), 'hello world');
    });

    test('removes U+FFFE non-character', () {
      final input = 'abc￾def';
      final result = UnicodeUtils.replaceProblematicChars(input);
      expect(result.contains('￾'), isFalse);
    });

    test('removes U+FFFF non-character', () {
      final input = 'abc￿def';
      final result = UnicodeUtils.replaceProblematicChars(input);
      expect(result.contains('￿'), isFalse);
    });

    test('removes null control character', () {
      final input = 'abc\x00def';
      final result = UnicodeUtils.replaceProblematicChars(input);
      expect(result.contains('\x00'), isFalse);
    });

    test('removes SOH control character', () {
      final input = 'abc\x01def';
      final result = UnicodeUtils.replaceProblematicChars(input);
      expect(result.contains('\x01'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // InputValidator
  // -------------------------------------------------------------------------

  group('InputValidator', () {
    test('isValidUnicode returns true for normal string', () {
      expect(InputValidator.isValidUnicode('hello'), isTrue);
    });

    test('isValidUnicode returns true for empty string', () {
      expect(InputValidator.isValidUnicode(''), isTrue);
    });

    test('cleanInput returns valid input unchanged', () {
      expect(InputValidator.cleanInput('hello world'), 'hello world');
    });

    test('cleanInput does not throw on empty string', () {
      expect(() => InputValidator.cleanInput(''), returnsNormally);
    });

    test('safeString returns normal string unchanged', () {
      expect(InputValidator.safeString('hello'), 'hello');
    });

    test('safeString does not throw on empty string', () {
      expect(() => InputValidator.safeString(''), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoAddressValidator — additional coverage beyond the dedicated file
  // -------------------------------------------------------------------------

  group('CryptoAddressValidator (extended)', () {
    // Solana
    test('Solana: empty string is invalid', () {
      expect(CryptoAddressValidator.isValid('', CryptoNetwork.solana), isFalse);
    });

    test('Solana: whitespace-only is invalid', () {
      expect(
          CryptoAddressValidator.isValid('   ', CryptoNetwork.solana), isFalse);
    });

    test('Solana: 32 leading-one base58 string decodes to 32 zero bytes', () {
      // 32 '1's in base58 = 32 zero bytes; isValid returns true
      const addr = '11111111111111111111111111111111';
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.solana), isTrue);
    });

    // XRP
    test('XRP: empty string is invalid', () {
      expect(CryptoAddressValidator.isValid('', CryptoNetwork.xrp), isFalse);
    });

    test('XRP: 25-char address starting with r is valid', () {
      const addr = 'rAAAAAAAAAAAAAAAAAAAAAAAAA'; // r + 24 chars = 25
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.xrp), isTrue);
    });

    test('XRP: address shorter than 25 chars is invalid', () {
      const addr = 'rABCD'; // 5 chars
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.xrp), isFalse);
    });

    test('XRP: address with wrong prefix is invalid', () {
      const addr = 'xAAAAAAAAAAAAAAAAAAAAAAAAA'; // starts with x
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.xrp), isFalse);
    });

    // SHIB
    test('SHIB: empty string is invalid', () {
      expect(CryptoAddressValidator.isValid('', CryptoNetwork.shib), isFalse);
    });

    test('SHIB: valid 0x + 40 hex chars is valid', () {
      const addr = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.shib), isTrue);
    });

    test('SHIB: missing 0x prefix is invalid', () {
      const addr = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.shib), isFalse);
    });

    test('SHIB: address too short is invalid', () {
      expect(
          CryptoAddressValidator.isValid('0xaaa', CryptoNetwork.shib), isFalse);
    });

    // SNX (same base58 rules as Solana)
    test('SNX: empty string is invalid', () {
      expect(CryptoAddressValidator.isValid('', CryptoNetwork.snx), isFalse);
    });

    test('SNX: 32-byte base58 address is valid', () {
      const addr = '11111111111111111111111111111111';
      expect(CryptoAddressValidator.isValid(addr, CryptoNetwork.snx), isTrue);
    });

    // validationMessage
    test('validationMessage returns null for valid Solana address', () {
      const addr = '11111111111111111111111111111111';
      expect(
          CryptoAddressValidator.validationMessage(addr, CryptoNetwork.solana),
          isNull);
    });

    test('validationMessage returns non-empty string for invalid Solana', () {
      final msg =
          CryptoAddressValidator.validationMessage('bad', CryptoNetwork.solana);
      expect(msg, isNotNull);
      expect(msg!.isNotEmpty, isTrue);
    });

    test('validationMessage returns null for valid XRP address', () {
      const addr = 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh';
      expect(
          CryptoAddressValidator.validationMessage(addr, CryptoNetwork.xrp),
          isNull);
    });

    test('validationMessage returns null for valid SHIB address', () {
      const addr = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';
      expect(
          CryptoAddressValidator.validationMessage(addr, CryptoNetwork.shib),
          isNull);
    });
  });
}
