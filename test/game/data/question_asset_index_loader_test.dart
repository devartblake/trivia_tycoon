import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/data/question_asset_index_loader.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestionAssetIndexLoader', () {
    test('resolves science path from question_paths_index.json', () async {
      final loader = QuestionAssetIndexLoader();

      final path = await loader.resolveAssetPath('Science');

      expect(path, 'assets/questions/science/science_question.json');
    });

    test('resolves technology path through index aliasing', () async {
      final loader = QuestionAssetIndexLoader();

      final path = await loader.resolveAssetPath('Technology');

      expect(path, 'assets/questions/tech/tech_question.json');
    });

    test('resolves class dataset path through index aliasing', () async {
      final loader = QuestionAssetIndexLoader();

      final path = await loader.resolveAssetPath('Class 7');

      expect(path, 'assets/questions/classes/class_7_questions.json');
    });
  });

  group('QuestionPresentationRandomizer', () {
    test('shuffles answers while preserving the correct answer mapping', () {
      final question = QuestionModel(
        id: 'q1',
        category: 'science',
        question: 'What is the correct answer?',
        answers: [
          Answer(text: 'Correct', isCorrect: true),
          Answer(text: 'Wrong 1', isCorrect: false),
          Answer(text: 'Wrong 2', isCorrect: false),
          Answer(text: 'Wrong 3', isCorrect: false),
        ],
        correctAnswer: 'Correct',
        type: 'multiple_choice',
        difficulty: 1,
        options: const ['Correct', 'Wrong 1', 'Wrong 2', 'Wrong 3'],
        correctIndex: 0,
      );

      final randomized = QuestionPresentationRandomizer.shuffleQuestionAnswers(
        question,
      );

      expect(randomized.answers.length, 4);
      expect(randomized.options.length, 4);
      expect(randomized.correctAnswer, 'Correct');
      expect(randomized.correctIndex, greaterThanOrEqualTo(0));
      expect(randomized.correctIndex, lessThan(4));
      expect(randomized.answers[randomized.correctIndex].isCorrect, isTrue);
      expect(
        randomized.options[randomized.correctIndex],
        randomized.correctAnswer,
      );
    });
  });
}
