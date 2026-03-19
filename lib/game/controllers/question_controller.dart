import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/game/providers/question_providers.dart';
import 'package:trivia_tycoon/game/providers/game_bonus_providers.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';import '../../core/repositories/question_repository.dart';
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

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadQuestions(String category) async {
    final loaded = await _questionRepository.getQuestionsForCategory(
      category: category,
      amount: 10,
    );

    if (loaded.isEmpty) {
      state = QuestionState.initial();
      return;
    }

    // Reset per-session bonus state
    ref.read(streakCountProvider.notifier).state =
        ref.read(streakCountProvider);        // keep startingStreak already set
    ref.read(timerFrozenProvider.notifier).state = false;

    final powerUp = ref.read(equippedPowerUpProvider);
    final first = PowerUpEffectApplier.apply(powerUp, loaded.first);

    state = state.copyWith(
      questions: [first, ...loaded.skip(1)],
      currentIndex: 0,
      selectedAnswer: null,
      powerUpUsed: false,
      timeLeft: 30,
      streakCount: ref.read(streakCountProvider),
      correctCount: 0,
      totalAnswered: 0,
    );

    // Apply passive question-level pending effects for the first question
    _applyPendingQuestionEffects(0);

    // If randomBenefit was armed, fire a random positive effect now
    if (ref.read(randomBenefitActiveProvider)) {
      _triggerRandomBenefit();
      ref.read(randomBenefitActiveProvider.notifier).state = false;
    }

    _startTimer();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Drain pending timer bonus from skill effects
      final bonus = ref.read(pendingTimerBonusProvider);
      if (bonus > 0) {
        ref.read(pendingTimerBonusProvider.notifier).state = 0;
        state = state.copyWith(timeLeft: state.timeLeft + bonus);
      }

      // Frozen timer — don't decrement
      if (ref.read(timerFrozenProvider)) return;

      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _evaluateAnswer();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Answer selection
  // ---------------------------------------------------------------------------

  void selectAnswer(String answer) {
    if (state.timeLeft > 0 && state.selectedAnswer == null) {
      // hintSpeedBonus — add bonus seconds when hint is being shown
      final hintBonus = ref.read(hintSpeedBonusProvider);
      if (hintBonus > 0 && (state.currentQuestion?.showHint ?? false)) {
        state = state.copyWith(timeLeft: state.timeLeft + hintBonus);
      }
      state = state.copyWith(selectedAnswer: answer);
    }
  }

  bool isSelected(String answer) => state.selectedAnswer == answer;

  // ---------------------------------------------------------------------------
  // Evaluate
  // ---------------------------------------------------------------------------

  Future<void> _evaluateAnswer() async {
    _timer?.cancel();

    bool correct =
        state.currentQuestion?.isCorrectAnswer(state.selectedAnswer ?? '') ??
            false;
    bool shieldUsed = false;

    // ── autoCorrectChance ──────────────────────────────────────────────────
    if (!correct) {
      final chance = ref.read(autoCorrectChanceProvider);
      if (chance > 0 && Random().nextDouble() < chance) {
        correct = true;
      }
    }

    // ── retryWrongAnswer ──────────────────────────────────────────────────
    // If wrong and a retry is available, reset the question for another attempt.
    if (!correct && ref.read(pendingRetryProvider)) {
      ref.read(pendingRetryProvider.notifier).state = false;
      state = state.copyWith(selectedAnswer: null, timeLeft: 20);
      _startTimer();
      return; // don't advance — let player try again
    }

    // ── streakProtection shield ────────────────────────────────────────────
    if (!correct && ref.read(streakShieldProvider) > 0) {
      ref.read(streakShieldProvider.notifier).state -= 1;
      shieldUsed = true; // streak preserved; no XP awarded for this question
    }

    // ── Scoring ────────────────────────────────────────────────────────────
    int updatedScore = state.score;
    int updatedMoney = state.money;
    int updatedDiamonds = state.diamonds;

    if (correct) {
      const basePoints = 10;

      // Power-up multiplier (set on the question model by PowerUpEffectApplier)
      final powerUpMult = state.currentQuestion?.multiplier ?? 1;

      // Skill-tree multipliers
      final skillBonus  = ref.read(scoreBonusMultiplierProvider);
      final streakMult  = ref.read(streakMultiplierProvider);
      final speedBonus  = ref.read(speedBonusMultiplierProvider);

      // Category-specific bonus
      double catBonus = 1.0;
      final catBonusMap = ref.read(categoryBonusProvider);
      if (catBonusMap != null) {
        final bonusCategory = catBonusMap['category'] as String?;
        final bonusRate = (catBonusMap['bonus'] as num?)?.toDouble() ?? 0.0;
        if (bonusCategory == null ||
            bonusCategory == state.currentQuestion?.category) {
          catBonus = 1.0 + bonusRate;
        }
      }

      int scorePoints = (basePoints *
          powerUpMult *
          skillBonus *
          streakMult *
          speedBonus *
          catBonus)
          .round();

      // ── accuracyBonus ────────────────────────────────────────────────────
      final accBonus = ref.read(accuracyBonusProvider);
      if (accBonus > 0 && state.accuracy >= 0.7) {
        scorePoints = (scorePoints * (1.0 + accBonus)).round();
      }

      // ── doubleOrNothing ──────────────────────────────────────────────────
      if (ref.read(doubleOrNothingProvider)) {
        scorePoints *= 2;
      }

      updatedScore    = state.score + scorePoints;
      updatedMoney    = state.money + 5;
      updatedDiamonds = state.diamonds + 1;

      // Award XP (XPService applies its own active boost internally)
      final xpService = ref.read(xpServiceProvider);
      xpService.addXP(scorePoints);
      ref.read(playerXPProvider.notifier).state = xpService.playerXP;

    } else if (ref.read(doubleOrNothingProvider)) {
      // Wrong while doubleOrNothing is active → lose all accumulated score
      updatedScore = 0;
    }

    // ── Streak tracking ────────────────────────────────────────────────────
    final newStreakCount = (correct || shieldUsed)
        ? state.streakCount + (shieldUsed ? 0 : 1)
        : 0;
    ref.read(streakCountProvider.notifier).state = newStreakCount;

    final newCorrect   = (correct && !shieldUsed) ? state.correctCount + 1 : state.correctCount;
    final newTotal     = state.totalAnswered + 1;

    state = state.copyWith(
      score:        updatedScore,
      money:        updatedMoney,
      diamonds:     updatedDiamonds,
      streakCount:  newStreakCount,
      correctCount: newCorrect,
      totalAnswered: newTotal,
    );

    // ── periodicChaos ─────────────────────────────────────────────────────
    final chaosInterval = ref.read(periodicChaosIntervalProvider);
    if (chaosInterval > 0 && newTotal % chaosInterval == 0) {
      _triggerPeriodicChaos();
    }

    await QuizSessionService.saveSession(
      'session_${DateTime.now().millisecondsSinceEpoch}',
      state.questions,
    );

    Future.delayed(const Duration(seconds: 3), nextQuestion);
  }

  // ---------------------------------------------------------------------------
  // Advance
  // ---------------------------------------------------------------------------

  void nextQuestion() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) return;

    // Unfreeze timer for the new question
    ref.read(timerFrozenProvider.notifier).state = false;

    final next = state.questions[nextIndex];
    final powerUp = ref.read(equippedPowerUpProvider);
    final affected = PowerUpEffectApplier.apply(powerUp, next);
    final updatedQuestions = [...state.questions];
    updatedQuestions[nextIndex] = affected;

    state = state.copyWith(
      questions:    updatedQuestions,
      currentIndex: nextIndex,
      selectedAnswer: null,
      powerUpUsed:  false,
      timeLeft:     30,
    );

    _applyPendingQuestionEffects(nextIndex);
    _startTimer();
  }

  // ---------------------------------------------------------------------------
  // Power-up (manual / from UI)
  // ---------------------------------------------------------------------------

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
        final incorrect =
        updated.options.where((c) => c != updated.correctAnswer).toList();
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


  void reset() {
    _timer?.cancel();
    state = QuestionState.initial();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Apply any pending passive skill effects to the question at [index].
  /// Called on each new question (load + advance).
  void _applyPendingQuestionEffects(int index) {
    var q = state.questions[index];
    bool modified = false;

    // eliminateHalfWrong — remove ~half the wrong options
    if (ref.read(pendingEliminateHalfProvider)) {
      final wrongs = q.options.where((o) => o != q.correctAnswer).toList()
        ..shuffle();
      final keep = wrongs.take((wrongs.length / 2).ceil()).toList();
      final reduced = [q.correctAnswer, ...keep]..shuffle();
      q = q.copyWith(options: reduced, reducedOptions: reduced);
      ref.read(pendingEliminateHalfProvider.notifier).state = false;
      modified = true;
    }

    // eliminateOneWrong — remove a single wrong option
    if (ref.read(pendingEliminateOneProvider)) {
      final wrongs = q.options.where((o) => o != q.correctAnswer).toList()
        ..shuffle();
      if (wrongs.isNotEmpty) {
        final reduced = q.options.where((o) => o != wrongs.first).toList();
        q = q.copyWith(options: reduced, reducedOptions: reduced);
      }
      ref.read(pendingEliminateOneProvider.notifier).state = false;
      modified = true;
    }

    // extraHints — passive hint on every question (provider stays true)
    if (ref.read(pendingShowHintProvider)) {
      q = q.copyWith(showHint: true);
      modified = true;
    }

    if (modified) {
      final updatedQuestions = [...state.questions];
      updatedQuestions[index] = q;
      state = state.copyWith(questions: updatedQuestions);
    }
  }

  /// Apply a random positive effect — used by the Wild Card (randomBenefit) skill.
  void _triggerRandomBenefit() {
    final options = <Map<String, num>>[
      {'timeBonusSec': 10},
      {'bonusXP': 50},
      {'streakBoost': 2},
      {'scoreMultiplier': 1.5},
    ];
    final chosen = options[Random().nextInt(options.length)];
    final entry = chosen.entries.first;
    final key = entry.key;
    final val = entry.value;

    // Route directly through the appropriate provider/service
    switch (key) {
      case 'timeBonusSec':
        ref.read(pendingTimerBonusProvider.notifier).state += val.toInt();
        break;
      case 'bonusXP':
        ref.read(xpServiceProvider).addXP(val.toInt());
        ref.read(playerXPProvider.notifier).state =
            ref.read(xpServiceProvider).playerXP;
        break;
      case 'streakBoost':
        ref.read(streakCountProvider.notifier).state += val.toInt();
        break;
      case 'scoreMultiplier':
        final cur = ref.read(scoreBonusMultiplierProvider);
        ref.read(scoreBonusMultiplierProvider.notifier).state =
            cur * val.toDouble();
        break;
    }
  }

  /// Apply a random negative effect — triggered every N questions by periodicChaos.
  void _triggerPeriodicChaos() {
    final options = <void Function()>[
      // Penalty: lose 5s on next question
          () => state = state.copyWith(timeLeft: (state.timeLeft - 5).clamp(1, 999)),
      // Penalty: halve streak count
          () {
        final half = (state.streakCount / 2).floor();
        ref.read(streakCountProvider.notifier).state = half;
        state = state.copyWith(streakCount: half);
      },
      // Penalty: reduce score bonus multiplier by 10%
          () {
        final cur = ref.read(scoreBonusMultiplierProvider);
        if (cur > 1.0) {
          ref.read(scoreBonusMultiplierProvider.notifier).state =
              (cur * 0.9).clamp(1.0, 100.0);
        }
      },
    ];
    options[Random().nextInt(options.length)]();
  }
}
