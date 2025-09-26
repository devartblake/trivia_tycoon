import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/question_model.dart';
import '../services/multiplayer_quiz_service.dart';

// Multiplayer Quiz State
class MultiplayerQuizState {
  final bool isLoading;
  final String? error;
  final List<QuestionModel> questions;
  final int currentIndex;
  final QuestionModel? currentQuestion;
  final String? playerAnswer;
  final String? opponentAnswer;
  final bool hasPlayerAnswered;
  final bool hasOpponentAnswered;
  final bool waitingForOpponent;
  final int timeRemaining;
  final bool isTimerExpired;
  final int playerScore;
  final int opponentScore;
  final String? opponentName;
  final String gameMode;
  final int totalQuestions;
  final bool isGameComplete;
  final bool isPlayerCorrect;
  final bool isOpponentCorrect;
  final String? matchId;

  const MultiplayerQuizState({
    this.isLoading = false,
    this.error,
    this.questions = const [],
    this.currentIndex = 0,
    this.currentQuestion,
    this.playerAnswer,
    this.opponentAnswer,
    this.hasPlayerAnswered = false,
    this.hasOpponentAnswered = false,
    this.waitingForOpponent = false,
    this.timeRemaining = 30,
    this.isTimerExpired = false,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.opponentName,
    this.gameMode = '',
    this.totalQuestions = 10,
    this.isGameComplete = false,
    this.isPlayerCorrect = false,
    this.isOpponentCorrect = false,
    this.matchId,
  });

  MultiplayerQuizState copyWith({
    bool? isLoading,
    String? error,
    List<QuestionModel>? questions,
    int? currentIndex,
    QuestionModel? currentQuestion,
    String? playerAnswer,
    String? opponentAnswer,
    bool? hasPlayerAnswered,
    bool? hasOpponentAnswered,
    bool? waitingForOpponent,
    int? timeRemaining,
    bool? isTimerExpired,
    int? playerScore,
    int? opponentScore,
    String? opponentName,
    String? gameMode,
    int? totalQuestions,
    bool? isGameComplete,
    bool? isPlayerCorrect,
    bool? isOpponentCorrect,
    String? matchId,
  }) {
    return MultiplayerQuizState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      playerAnswer: playerAnswer,
      opponentAnswer: opponentAnswer,
      hasPlayerAnswered: hasPlayerAnswered ?? this.hasPlayerAnswered,
      hasOpponentAnswered: hasOpponentAnswered ?? this.hasOpponentAnswered,
      waitingForOpponent: waitingForOpponent ?? this.waitingForOpponent,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isTimerExpired: isTimerExpired ?? this.isTimerExpired,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentName: opponentName ?? this.opponentName,
      gameMode: gameMode ?? this.gameMode,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isGameComplete: isGameComplete ?? this.isGameComplete,
      isPlayerCorrect: isPlayerCorrect ?? this.isPlayerCorrect,
      isOpponentCorrect: isOpponentCorrect ?? this.isOpponentCorrect,
      matchId: matchId ?? this.matchId,
    );
  }
}

// Multiplayer Quiz Notifier
class MultiplayerQuizNotifier extends StateNotifier<MultiplayerQuizState> {
  final MultiplayerQuizService _quizService;
  Timer? _timer;
  StreamSubscription? _opponentSubscription;

  MultiplayerQuizNotifier(this._quizService) : super(const MultiplayerQuizState());

  Future<void> startMultiplayerQuiz(String gameMode) async {
    state = state.copyWith(isLoading: true, error: null, gameMode: gameMode);

    try {
      // Initialize the multiplayer match
      final matchData = await _quizService.initializeMatch(gameMode);

      // Get questions for the game mode
      final questions = await _quizService.getQuestionsForGameMode(gameMode);

      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No questions available for this game mode',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        questions: questions,
        currentQuestion: questions.first,
        totalQuestions: questions.length,
        opponentName: matchData.opponentName,
        matchId: matchData.matchId,
      );

      // Start the timer for the first question
      _startTimer();

      // Listen for opponent actions
      _subscribeToOpponentUpdates();

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(timeRemaining: 30, isTimerExpired: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        state = state.copyWith(isTimerExpired: true);
        timer.cancel();

        // Auto-submit empty answer if time expires
        if (!state.hasPlayerAnswered) {
          submitAnswer('');
        }
      }
    });
  }

  void _subscribeToOpponentUpdates() {
    _opponentSubscription?.cancel();

    if (state.matchId != null) {
      _opponentSubscription = _quizService
          .getOpponentUpdates(state.matchId!)
          .listen(_handleOpponentUpdate);
    }
  }

  void _handleOpponentUpdate(OpponentUpdate update) {
    switch (update.type) {
      case OpponentUpdateType.answered:
        state = state.copyWith(
          hasOpponentAnswered: true,
          opponentAnswer: update.answer,
        );

        // If both players have answered, process the round
        if (state.hasPlayerAnswered && state.hasOpponentAnswered) {
          _processRoundResults();
        }
        break;

      case OpponentUpdateType.disconnected:
        state = state.copyWith(
          error: 'Opponent disconnected. You win by forfeit!',
          isGameComplete: true,
        );
        break;

      case OpponentUpdateType.nextQuestion:
      // Opponent is ready for next question
        break;
    }
  }

  Future<void> submitAnswer(String answer) async {
    if (state.hasPlayerAnswered || state.matchId == null) return;

    _timer?.cancel();

    state = state.copyWith(
      playerAnswer: answer,
      hasPlayerAnswered: true,
      waitingForOpponent: !state.hasOpponentAnswered,
    );

    try {
      await _quizService.submitAnswer(state.matchId!, answer, state.currentIndex);

      // If opponent has already answered, process results immediately
      if (state.hasOpponentAnswered) {
        _processRoundResults();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to submit answer: $e');
    }
  }

  void _processRoundResults() {
    if (state.currentQuestion == null) return;

    final isPlayerCorrect = state.currentQuestion!.isCorrectAnswer(state.playerAnswer ?? '');
    final isOpponentCorrect = state.currentQuestion!.isCorrectAnswer(state.opponentAnswer ?? '');

    int newPlayerScore = state.playerScore;
    int newOpponentScore = state.opponentScore;

    // Calculate scores based on game mode
    if (isPlayerCorrect) {
      newPlayerScore += _calculateScoreForGameMode(state.gameMode);
    }
    if (isOpponentCorrect) {
      newOpponentScore += _calculateScoreForGameMode(state.gameMode);
    }

    final isLastQuestion = state.currentIndex >= state.questions.length - 1;

    state = state.copyWith(
      isPlayerCorrect: isPlayerCorrect,
      isOpponentCorrect: isOpponentCorrect,
      playerScore: newPlayerScore,
      opponentScore: newOpponentScore,
      isGameComplete: isLastQuestion,
      waitingForOpponent: false,
    );
  }

  int _calculateScoreForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return 100; // Treasure Mine: Higher stakes
      case 'teams':
        return 150; // Survival Arena: Even higher stakes
      default:
        return 50;
    }
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      final nextIndex = state.currentIndex + 1;

      state = state.copyWith(
        currentIndex: nextIndex,
        currentQuestion: state.questions[nextIndex],
        playerAnswer: null,
        opponentAnswer: null,
        hasPlayerAnswered: false,
        hasOpponentAnswered: false,
        waitingForOpponent: false,
        isPlayerCorrect: false,
        isOpponentCorrect: false,
      );

      _startTimer();
    }
  }

  Future<void> forfeitMatch() async {
    _timer?.cancel();
    _opponentSubscription?.cancel();

    if (state.matchId != null) {
      try {
        await _quizService.forfeitMatch(state.matchId!);
      } catch (e) {
        // Handle forfeit error silently
      }
    }

    state = const MultiplayerQuizState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _opponentSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final multiplayerQuizProvider = StateNotifierProvider<MultiplayerQuizNotifier, MultiplayerQuizState>((ref) {
  final quizService = ref.read(multiplayerQuizServiceProvider);
  return MultiplayerQuizNotifier(quizService);
});

// Match Data Model
class MatchData {
  final String matchId;
  final String opponentName;
  final String? opponentAvatar;
  final String gameMode;
  final int totalQuestions;

  MatchData({
    required this.matchId,
    required this.opponentName,
    this.opponentAvatar,
    required this.gameMode,
    required this.totalQuestions,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      matchId: json['matchId'] as String,
      opponentName: json['opponentName'] as String,
      opponentAvatar: json['opponentAvatar'] as String?,
      gameMode: json['gameMode'] as String,
      totalQuestions: json['totalQuestions'] as int? ?? 10,
    );
  }
}

// Opponent Update Model
enum OpponentUpdateType {
  answered,
  disconnected,
  nextQuestion,
}

class OpponentUpdate {
  final OpponentUpdateType type;
  final String? answer;
  final Map<String, dynamic>? data;

  OpponentUpdate({
    required this.type,
    this.answer,
    this.data,
  });

  factory OpponentUpdate.fromJson(Map<String, dynamic> json) {
    return OpponentUpdate(
      type: OpponentUpdateType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => OpponentUpdateType.answered,
      ),
      answer: json['answer'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
