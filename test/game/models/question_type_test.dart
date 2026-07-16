import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/question_type.dart';

void main() {
  group('QuestionType', () {
    test('All question types are defined', () {
      expect(QuestionType.multipleChoice, isNotNull);
      expect(QuestionType.trueFalse, isNotNull);
      expect(QuestionType.imageChoice, isNotNull);
      expect(QuestionType.videoChoice, isNotNull);
      expect(QuestionType.audioChoice, isNotNull);
      expect(QuestionType.dragDrop, isNotNull);
      expect(QuestionType.sorting, isNotNull);
      expect(QuestionType.matching, isNotNull);
      expect(QuestionType.classification, isNotNull);
      expect(QuestionType.labeling, isNotNull);
      expect(QuestionType.freeText, isNotNull);
    });

    group('value getter', () {
      test('Returns correct API strings', () {
        expect(QuestionType.multipleChoice.value, equals('multiple_choice'));
        expect(QuestionType.trueFalse.value, equals('true_false'));
        expect(QuestionType.imageChoice.value, equals('image_choice'));
        expect(QuestionType.videoChoice.value, equals('video_choice'));
        expect(QuestionType.audioChoice.value, equals('audio_choice'));
        expect(QuestionType.dragDrop.value, equals('drag_drop'));
        expect(QuestionType.sorting.value, equals('sorting'));
        expect(QuestionType.matching.value, equals('matching'));
        expect(QuestionType.classification.value, equals('classification'));
        expect(QuestionType.labeling.value, equals('labeling'));
        expect(QuestionType.freeText.value, equals('free_text'));
      });
    });

    group('displayName getter', () {
      test('Returns user-friendly display names', () {
        expect(
            QuestionType.multipleChoice.displayName, equals('Multiple Choice'));
        expect(QuestionType.trueFalse.displayName, equals('True/False'));
        expect(QuestionType.imageChoice.displayName, equals('Image Question'));
        expect(QuestionType.videoChoice.displayName, equals('Video Question'));
        expect(QuestionType.audioChoice.displayName, equals('Audio Question'));
        expect(QuestionType.dragDrop.displayName, equals('Drag & Drop'));
        expect(QuestionType.sorting.displayName, equals('Sorting'));
        expect(QuestionType.matching.displayName, equals('Matching'));
        expect(
            QuestionType.classification.displayName, equals('Classification'));
        expect(QuestionType.labeling.displayName, equals('Labeling'));
        expect(QuestionType.freeText.displayName, equals('Free Text'));
      });
    });

    group('isMultimedia getter', () {
      test('Correctly identifies multimedia types', () {
        expect(QuestionType.multipleChoice.isMultimedia, isFalse);
        expect(QuestionType.trueFalse.isMultimedia, isFalse);
        expect(QuestionType.imageChoice.isMultimedia, isTrue);
        expect(QuestionType.videoChoice.isMultimedia, isTrue);
        expect(QuestionType.audioChoice.isMultimedia, isTrue);
        expect(QuestionType.dragDrop.isMultimedia, isFalse);
        expect(QuestionType.sorting.isMultimedia, isFalse);
        expect(QuestionType.matching.isMultimedia, isFalse);
        expect(QuestionType.classification.isMultimedia, isFalse);
        expect(QuestionType.labeling.isMultimedia, isFalse);
        expect(QuestionType.freeText.isMultimedia, isFalse);
      });

      test('Multimedia types are image, video, or audio', () {
        final multimediaTypes = [
          QuestionType.imageChoice,
          QuestionType.videoChoice,
          QuestionType.audioChoice,
        ];

        for (final type in multimediaTypes) {
          expect(type.isMultimedia, isTrue);
        }
      });
    });

    group('fromString parsing', () {
      test('Parses API format strings', () {
        expect(
          QuestionTypeExtension.fromString('multiple_choice'),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString('true_false'),
          equals(QuestionType.trueFalse),
        );
        expect(
          QuestionTypeExtension.fromString('image_choice'),
          equals(QuestionType.imageChoice),
        );
      });

      test('Parses camelCase variants', () {
        expect(
          QuestionTypeExtension.fromString('multiplechoice'),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString('truefalse'),
          equals(QuestionType.trueFalse),
        );
      });

      test('Parses short codes', () {
        expect(
          QuestionTypeExtension.fromString('mc'),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString('tf'),
          equals(QuestionType.trueFalse),
        );
      });

      test('Parses case-insensitively', () {
        expect(
          QuestionTypeExtension.fromString('MULTIPLE_CHOICE'),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString('IMAGE_CHOICE'),
          equals(QuestionType.imageChoice),
        );
      });

      test('Returns multipleChoice for invalid strings', () {
        expect(
          QuestionTypeExtension.fromString('invalid_type'),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString(''),
          equals(QuestionType.multipleChoice),
        );
        expect(
          QuestionTypeExtension.fromString(null),
          equals(QuestionType.multipleChoice),
        );
      });

      test('Parses boolean synonym for trueFalse', () {
        expect(
          QuestionTypeExtension.fromString('boolean'),
          equals(QuestionType.trueFalse),
        );
      });

      test('Parses media type shortcuts', () {
        expect(
          QuestionTypeExtension.fromString('image'),
          equals(QuestionType.imageChoice),
        );
        expect(
          QuestionTypeExtension.fromString('video'),
          equals(QuestionType.videoChoice),
        );
        expect(
          QuestionTypeExtension.fromString('audio'),
          equals(QuestionType.audioChoice),
        );
        expect(
          QuestionTypeExtension.fromString('text'),
          equals(QuestionType.freeText),
        );
      });

      test('Parses alternative spellings', () {
        expect(
          QuestionTypeExtension.fromString('labelling'),
          equals(QuestionType.labeling),
        );
      });
    });

    group('Round-trip serialization', () {
      test('value -> fromString preserves type', () {
        for (final type in QuestionType.values) {
          final serialized = type.value;
          final deserialized = QuestionTypeExtension.fromString(serialized);
          expect(deserialized, equals(type));
        }
      });
    });
  });
}
