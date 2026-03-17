import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/game/providers/question_providers.dart';
import 'package:trivia_tycoon/game/providers/game_bonus_providers.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';
import '../../core/repositories/question_repository.dart';
import '../../core/services/question/quiz_session_service.dart';
import '../logic/power_up_effect_applier.dart';
import '../models/question_model.dart';
import '../state/question_state.dart';

class QuestionController extends StateNotifier<QuestionState> {
  final Ref ref;
  final QuestionRepository _questionRepository;
  Timer? _timer;

  QuestionController({required this.ref})
      : _questionRepository = ref.read(questionRepositoryProvider),
        super(QuestionState.initial());

  Future<void> loadQuestions(String category) async {
    final loaded = await _questionRepository.getQuestionsForCategory(
      category: category,
      amount: 10,
    );

    if (loaded.isEmpty) {
      state = state.copyWith(
        questions: const [],
        currentIndex: 0,
        selectedAnswer: null,
        powerUpUsed: false,
        timeLeft: 30,
      );
      return;
    }

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
      // Drain any pending timer bonus from skill tree effects
      final bonus = ref.read(pendingTimerBonusProvider);
      if (bonus > 0) {
        ref.read(pendingTimerBonusProvider.notifier).state = 0;
        state = state.copyWith(timeLeft: state.timeLeft + bonus);
      }

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

    int updatedScore = state.score;
    int updatedMoney = state.money;
    int updatedDiamonds = state.diamonds;

    if (correct) {
      const basePoints = 10;

      // Power-up multiplier (set on the question by PowerUpEffectApplier)
      final powerUpMultiplier = state.currentQuestion?.multiplier ?? 1;

      // Skill-tree score bonus multiplier (set by streakMult / sportsScoreBoost / hardBonus)
      final skillScoreBonus = ref.read(scoreBonusMultiplierProvider);

      // Streak multiplier from skill tree
      final streakMult = ref.read(streakMultiplierProvider);

      final scorePoints = (basePoints * powerUpMultiplier * skillScoreBonus * streakMult).round();

      updatedScore = state.score + scorePoints;
      updatedMoney = state.money + 5;
      updatedDiamonds = state.diamonds + 1;

      // Award XP — XPService applies its own active boost internally
      final xpService = ref.read(xpServiceProvider);
      xpService.addXP(scorePoints);
      ref.read(playerXPProvider.notifier).state = xpService.playerXP;
    }

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
