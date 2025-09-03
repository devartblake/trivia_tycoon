import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import '../../core/services/settings/quiz_progress_service.dart';
import '../../game/models/power_up.dart';
import '../../game/models/achievement.dart';
import '../../game/models/question_model.dart';
import '../../game/models/player_progress.dart';
import '../../game/controllers/settings_controller.dart';
import '../../core/services/question/question_service.dart';
import '../../game/services/achievement_service.dart';
import '../providers/riverpod_providers.dart' as providers;

enum GameState { idle, playing, paused, ended }

/// Provides an instance of GameController using Riverpod.
final gameControllerProvider = ChangeNotifierProvider<GameController>((ref) {
  final settingsController = ref.read(providers.settingsControllerProvider);
  final questionService = ref.read(providers.questionServiceProvider);
  final achievementService = ref.read(providers.achievementServiceProvider);
  final quizProgressService = ref.read(providers.quizProgressServiceProvider);
  final router = ref.read(providers.routerProvider).value!;

  return GameController(
      settingsController: settingsController,
      questionService: questionService,
      achievementService: achievementService,
      quizProgressService: quizProgressService,
      router: router
  );
});

class GameController extends ChangeNotifier {
  static final _log = Logger('GameController');

  final SettingsController settingsController;
  final QuestionService questionService;
  final AchievementService achievementService;
  final QuizProgressService quizProgressService;
  final GoRouter router;

  GameState _gameState = GameState.idle;
  int _score = 0;
  int _streak = 0;
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  PowerUp? _equippedPowerUp;

  GameState get gameState => _gameState;
  int get score => _score;
  int get streak => _streak;
  PowerUp? get equippedPowerUp => _equippedPowerUp;
  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;

  GameController({
    required this.settingsController,
    required this.questionService,
    required this.achievementService,
    required this.quizProgressService,
    required this.router,
  }) {
    _loadProgress();
  }

  /// Loads player progress from persistent storage.
  Future<void> _loadProgress() async {
    final progress = await quizProgressService.getPlayerProgress();
    _score = progress['score'] as int? ?? 0; // Extract safely with a fallback
    _streak = progress['streak'] as int? ?? 0;
    notifyListeners();
    _log.fine('Loaded player progress: Score $_score, Streak $_streak');
  }

  Future<bool> isPowerUpExpired() async {
    final controller = providers.refContainer.read(providers.equippedPowerUpProvider.notifier);
    return controller.isExpired();
  }

  /// ✅ NEW: Access remaining power-up duration
  Future<Duration> getPowerUpRemainingTime() async {
    final controller = providers.refContainer.read(providers.equippedPowerUpProvider.notifier);
    return controller.getRemainingTime();
  }

  /// ✅ NEW: Clear the active power-up
  Future<void> clearEquippedPowerUp() async {
    final controller = providers.refContainer.read(providers.equippedPowerUpProvider.notifier);
    await controller.clearEquippedPowerUp();
    _equippedPowerUp = null;
    notifyListeners();
  }

  /// Starts a new game session.
  Future<void> startGame(List<PowerUp> availablePowerUps) async {
    // 🧠 Restore previously equipped power-up
    final powerUpController = providers.refContainer.read(providers.equippedPowerUpProvider.notifier);
    await powerUpController.restoreFromStorage(availablePowerUps);
    _equippedPowerUp = powerUpController.state;

    // 🚀 Begin game logic
    _gameState = GameState.playing;
    _score = 0;
    _streak = 0;
    _questions = await questionService.fetchQuestionsWithFallback();
    _currentQuestionIndex = 0;
    notifyListeners();
    _log.fine('Game started with ${_questions.length} questions.');
    router.go('/trivia-transition');
  }

  /// Submits an answer and checks correctness.
  void submitAnswer(String answer) {
    if (_gameState != GameState.playing) return;

    final correct = currentQuestion?.isCorrectAnswer(answer) ?? false;
    if (correct) {
      _score += 10;
      _streak++;
      _checkAchievements();
    } else {
      _streak = 0;
    }

    _nextQuestion();
  }

  /// Moves to the next question or ends the game if finished.
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _endGame();
    }
    notifyListeners();
  }

  /// Ends the game session.
  void _endGame() {
    _gameState = GameState.ended;
    _saveProgress();
    notifyListeners();
    _log.fine('Game ended with final score: $_score');
  }

  /// Saves player progress.
  Future<void> _saveProgress() async {
    final progress = PlayerProgress(score: _score, streak: _streak);
    await quizProgressService.savePlayerProgress(progress as Map<String, dynamic>);
  }

  /// Pauses the game.
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      notifyListeners();
      _log.fine('Game paused.');
    }
  }

  /// Resumes the game.
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      notifyListeners();
      _log.fine('Game resumed.');
    }
  }

  /// Checks if the player has unlocked achievements.
  void _checkAchievements() {
    if (_streak >= 5) {
      final achievement = Achievement(
        id: 'streak_5',
        title: '5 Correct Answer Streak',
        description: '5 Correct Answers in a Row',
      );
      achievementService.unlockAchievement(
        achievement,
        'PlayerName',
      ); // Replace with actual player name
      _log.fine('Achievement Unlocked: 5 Correct Answers in a Row!');
    }
  }

  /// Loads the next trivia question
  void loadNextQuestion() {
    _nextQuestion();
    router.go('/quiz');
  }

  /// Transition to the next question
  void startNextQuestionWithTransition() {
    router.go('/trivia-transition');
  }
}
