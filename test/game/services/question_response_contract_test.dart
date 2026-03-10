import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/question_response_contract.dart';

void main() {
  group('QuestionResponseContract.parseCollection', () {
    test('parses valid items collection without meta when not required', () {
      final envelope = QuestionResponseContract.parseCollection(
        {
          'items': [1, 2, 3],
        },
        endpoint: '/quiz/categories',
        itemKeys: const ['items', 'data'],
      );

      expect(envelope.items, [1, 2, 3]);
      expect(envelope.meta, isEmpty);
    });

    test('throws when collection key is missing', () {
      expect(
        () => QuestionResponseContract.parseCollection(
          {'meta': {'page': 1}},
          endpoint: '/quiz/mixed',
          itemKeys: const ['items', 'questions'],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when meta is required and missing', () {
      expect(
        () => QuestionResponseContract.parseCollection(
          {
            'questions': [
              {'id': 'q-1'}
            ],
          },
          endpoint: '/quiz/daily',
          itemKeys: const ['items', 'questions'],
          requireMeta: true,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when meta is not a map', () {
      expect(
        () => QuestionResponseContract.parseCollection(
          {
            'items': const [],
            'meta': 'invalid',
          },
          endpoint: '/quiz/daily',
          itemKeys: const ['items'],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
