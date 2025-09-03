import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../core/services/question/question_service.dart';
import '../../core/services/question/quiz_session_service.dart';
import '../logic/power_up_effect_applier.dart';
import '../models/question_model.dart';
import '../state/question_state.dart';

class QuestionController extends StateNotifier<QuestionState> {
  final Ref ref;
  final QuestionService _questionService;
  Timer? _timer;

  QuestionController({required this.ref})
      : _questionService = QuestionService(
    apiService: ref.read(apiServiceProvider),
    quizProgressService: ref.read(quizProgressServiceProvider),
  ),
        super(QuestionState.initial());

  Future<void> loadQuestions(String category) async {
    final fallback = await _questionService.fetchLocalQuestions();
    final fetched = await _questionService.fetchQuestionsFromServer(category);
    final loaded = fetched.isNotEmpty ? fetched : fallback;

    final powerUp = ref.read(equippedPowerUpProvider);
    final first = PowerUpEffectApplier.apply(powerUp, loaded.first);

    state = state.copyWith(
      questions: [first, ...loaded.skip(1)],
      currentIndex: 0,
      selectedAnswer: null,
      powerUpUsed: false,
      timeLeft: 30,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _evaluateAnswer();
      }
    });
  }

  void selectAnswer(String answer) {
    if (state.timeLeft > 0 && state.selectedAnswer == null) {
      state = state.copyWith(selectedAnswer: answer);
    }
  }

  bool isSelected(String answer) => state.selectedAnswer == answer;

  Future<void> _evaluateAnswer() async {
    _timer?.cancel();

    final correct = state.currentQuestion?.isCorrectAnswer(state.selectedAnswer ?? '') ?? false;
    final updatedScore = correct ? state.score + 10 : state.score;
    final updatedMoney = correct ? state.money + 5 : state.money;
    final updatedDiamonds = correct ? state.diamonds + 1 : state.diamonds;

    state = state.copyWith(
      score: updatedScore,
      money: updatedMoney,
      diamonds: updatedDiamonds,
    );

    await QuizSessionService.saveSession(
      'session_${DateTime.now().millisecondsSinceEpoch}',
      state.questions,
    );

    Future.delayed(const Duration(seconds: 3), nextQuestion);
  }

  void nextQuestion() {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.questions.length) return;

    final next = state.questions[nextIndex];
    final powerUp = ref.read(equippedPowerUpProvider);
    final affected = PowerUpEffectApplier.apply(powerUp, next);
    final updatedQuestions = [...state.questions];
    updatedQuestions[nextIndex] = affected;

    state = state.copyWith(
      questions: updatedQuestions,
      currentIndex: nextIndex,
      selectedAnswer: null,
      powerUpUsed: false,
      timeLeft: 30,
    );

    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    state = QuestionState.initial();
  }

  void usePowerUp(String type) {
    if (state.powerUpUsed || state.currentQuestion == null) return;

    /// Hint power-up
    QuestionModel updated = state.currentQuestion!;
    switch (type) {
      case 'hint':
        updated = updated.copyWith(showHint: true);
        break;

      /// Eliminate power-up
      case 'eliminate':
        final incorrect = updated.options.where((c) => c != updated.correctAnswer).toList();
        incorrect.shuffle();
        final reduced = updated.options
            .where((c) => c == updated.correctAnswer || c == incorrect.first)
            .toList();
        updated = updated.copyWith(options: reduced, reducedOptions: reduced);
        break;

      /// Extra time power-up
      case 'extra_time':
        state = state.copyWith(timeLeft: state.timeLeft + 10);
        return;
    }

    // 🛠️ Replace the updated question in the list
    final updatedQuestions = [...state.questions];
    updatedQuestions[state.currentIndex] = updated;

    // ✅ Update state
    state = state.copyWith(questions: updatedQuestions, powerUpUsed: true);
  }
}
