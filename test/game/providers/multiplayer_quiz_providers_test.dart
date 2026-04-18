import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/providers/multiplayer_quiz_providers.dart';
import 'package:trivia_tycoon/game/services/multiplayer_quiz_service.dart';

class _FakeMultiplayerQuizService extends MultiplayerQuizService {
  _FakeMultiplayerQuizService({
    required this.matchData,
    required this.questions,
  });

  final MatchData matchData;
  final List<QuestionModel> questions;
  final StreamController<OpponentUpdate> _updates =
      StreamController<OpponentUpdate>.broadcast();

  String? submittedAnswer;
  int? submittedQuestionIndex;
  String? registeredMatchId;

  @override
  Future<MatchData> initializeMatch(String gameMode) async => matchData;

  @override
  Future<List<QuestionModel>> getQuestionsForGameMode(String gameMode) async =>
      questions;

  @override
  Stream<OpponentUpdate> getOpponentUpdates(String matchId) => _updates.stream;

  @override
  Future<void> submitAnswer(
    String matchId,
    String answer,
    int questionIndex,
  ) async {
    submittedAnswer = answer;
    submittedQuestionIndex = questionIndex;
  }

  @override
  void registerMatchQuestions(String matchId, List<QuestionModel> questions) {
    registeredMatchId = matchId;
  }

  void emitOpponentAnswer(String answer) {
    _updates.add(
      OpponentUpdate(
        type: OpponentUpdateType.answered,
        answer: answer,
      ),
    );
  }

  @override
  void dispose() {
    _updates.close();
    super.dispose();
  }
}

QuestionModel _question({
  required String id,
  required String correctAnswer,
  List<String>? options,
}) {
  final values = options ?? <String>[correctAnswer, 'Wrong 1', 'Wrong 2'];
  return QuestionModel.fromJson({
    'id': id,
    'category': 'General',
    'question': 'Question $id',
    'answers': values
        .map(
          (value) => {
            'text': value,
            'isCorrect': value == correctAnswer,
          },
        )
        .toList(),
    'correctAnswer': correctAnswer,
    'type': 'multiple_choice',
    'difficulty': 2,
  });
}

void main() {
  test('correct multiplayer answer resolves only after opponent update', () async {
    final service = _FakeMultiplayerQuizService(
      matchData: MatchData(
        matchId: 'match-1',
        opponentName: 'Opponent',
        gameMode: 'arena',
        totalQuestions: 1,
      ),
      questions: [
        _question(
          id: 'q1',
          correctAnswer: 'Correct',
          options: const ['Correct', 'Wrong 1', 'Wrong 2', 'Wrong 3'],
        ),
      ],
    );

    final notifier = MultiplayerQuizNotifier(service);

    await notifier.startMultiplayerQuiz('arena');

    expect(notifier.state.currentQuestion?.correctAnswer, 'Correct');
    expect(service.registeredMatchId, 'match-1');

    await notifier.submitAnswer('Correct');

    expect(notifier.state.hasPlayerAnswered, isTrue);
    expect(notifier.state.waitingForOpponent, isTrue);
    expect(notifier.state.isRoundResolved, isFalse);
    expect(notifier.state.playerScore, 0);

    service.emitOpponentAnswer('Wrong 1');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.isRoundResolved, isTrue);
    expect(notifier.state.isPlayerCorrect, isTrue);
    expect(notifier.state.isOpponentCorrect, isFalse);
    expect(notifier.state.playerScore, 100);
    expect(notifier.state.opponentScore, 0);

    service.emitOpponentAnswer('Wrong 2');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.playerScore, 100);
    expect(notifier.state.opponentScore, 0);

    notifier.dispose();
    service.dispose();
  });
}
