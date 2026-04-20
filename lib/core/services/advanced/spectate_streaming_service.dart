import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class PlayerState {
  final String id;
  final String name;
  final String? avatar;
  final int score;
  final int correctAnswers;
  final int streak;
  final bool isAnswering;

  const PlayerState({
    required this.id,
    required this.name,
    this.avatar,
    required this.score,
    this.correctAnswers = 0,
    this.streak = 0,
    this.isAnswering = false,
  });

  PlayerState copyWith({
    String? id,
    String? name,
    String? avatar,
    int? score,
    int? correctAnswers,
    int? streak,
    bool? isAnswering,
  }) {
    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      streak: streak ?? this.streak,
      isAnswering: isAnswering ?? this.isAnswering,
    );
  }
}

class QuestionState {
  final int index;
  final String question;
  final List<String> options;
  final String? correctAnswer;
  final bool isRevealed;
  final Map<String, String> playerAnswers; // playerId -> answer
  final DateTime startTime;
  final Duration timeLimit;

  const QuestionState({
    required this.index,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.isRevealed = false,
    this.playerAnswers = const {},
    required this.startTime,
    required this.timeLimit,
  });

  Duration get timeRemaining {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = timeLimit - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isTimeUp => timeRemaining == Duration.zero;
}

class GameSpectateState {
  final String gameId;
  final String gameTitle;
  final String category;
  final List<PlayerState> players;
  final QuestionState? currentQuestion;
  final int totalQuestions;
  final int currentQuestionIndex;
  final int spectatorCount;
  final bool hasStarted;
  final bool hasEnded;
  final String? winner;
  final DateTime startTime;

  const GameSpectateState({
    required this.gameId,
    required this.gameTitle,
    required this.category,
    required this.players,
    this.currentQuestion,
    required this.totalQuestions,
    this.currentQuestionIndex = 0,
    this.spectatorCount = 0,
    this.hasStarted = false,
    this.hasEnded = false,
    this.winner,
    required this.startTime,
  });

  double get progress =>
      totalQuestions > 0 ? currentQuestionIndex / totalQuestions : 0.0;
}

class SpectateStreamingService extends ChangeNotifier {
  static final SpectateStreamingService _instance =
      SpectateStreamingService._internal();
  factory SpectateStreamingService() => _instance;
  SpectateStreamingService._internal();

  final Map<String, GameSpectateState> _activeGames = {};
  final Map<String, StreamController<GameSpectateState>> _gameStreams = {};
  final Map<String, Set<String>> _spectators =
      {}; // gameId -> Set of spectatorIds

  Timer? _updateTimer;

  void initialize() {
    _startGameUpdates();
    LogManager.debug('SpectateStreamingService initialized');
  }

  void dispose() {
    _updateTimer?.cancel();
    for (final controller in _gameStreams.values) {
      controller.close();
    }
    _gameStreams.clear();
    super.dispose();
  }

  // Join spectate mode
  void joinSpectate({
    required String gameId,
    required String spectatorId,
    required String spectatorName,
  }) {
    _spectators[gameId] ??= {};
    _spectators[gameId]!.add(spectatorId);

    // Update spectator count
    if (_activeGames.containsKey(gameId)) {
      final game = _activeGames[gameId]!;
      _activeGames[gameId] = GameSpectateState(
        gameId: game.gameId,
        gameTitle: game.gameTitle,
        category: game.category,
        players: game.players,
        currentQuestion: game.currentQuestion,
        totalQuestions: game.totalQuestions,
        currentQuestionIndex: game.currentQuestionIndex,
        spectatorCount: _spectators[gameId]!.length,
        hasStarted: game.hasStarted,
        hasEnded: game.hasEnded,
        winner: game.winner,
        startTime: game.startTime,
      );
      _broadcastGameUpdate(gameId);
    }

    LogManager.debug('$spectatorName joined spectate mode for game $gameId');
  }

  // Leave spectate mode
  void leaveSpectate({
    required String gameId,
    required String spectatorId,
  }) {
    _spectators[gameId]?.remove(spectatorId);

    // Update spectator count
    if (_activeGames.containsKey(gameId)) {
      final game = _activeGames[gameId]!;
      _activeGames[gameId] = GameSpectateState(
        gameId: game.gameId,
        gameTitle: game.gameTitle,
        category: game.category,
        players: game.players,
        currentQuestion: game.currentQuestion,
        totalQuestions: game.totalQuestions,
        currentQuestionIndex: game.currentQuestionIndex,
        spectatorCount: _spectators[gameId]?.length ?? 0,
        hasStarted: game.hasStarted,
        hasEnded: game.hasEnded,
        winner: game.winner,
        startTime: game.startTime,
      );
      _broadcastGameUpdate(gameId);
    }

    LogManager.debug('Spectator $spectatorId left game $gameId');
  }

  // Watch a specific game
  Stream<GameSpectateState> watchGame(String gameId) {
    _gameStreams[gameId] ??= StreamController<GameSpectateState>.broadcast();

    // Create mock game if it doesn't exist (for demo)
    if (!_activeGames.containsKey(gameId)) {
      _createMockGame(gameId);
    }

    // Send initial state
    if (_activeGames.containsKey(gameId)) {
      Future.delayed(Duration.zero, () {
        _broadcastGameUpdate(gameId);
      });
    }

    return _gameStreams[gameId]!.stream;
  }

  // Get list of available games to spectate
  List<GameSpectateState> getAvailableGames() {
    return _activeGames.values
        .where((game) => game.hasStarted && !game.hasEnded)
        .toList()
      ..sort((a, b) => b.spectatorCount.compareTo(a.spectatorCount));
  }

  // Send reaction during spectate
  void sendReaction({
    required String gameId,
    required String spectatorId,
    required String reaction,
  }) {
    // In a real app, this would broadcast the reaction to other spectators
    LogManager.debug(
        'Spectator $spectatorId sent reaction $reaction to game $gameId');
  }

  // Simulate game updates
  void _startGameUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateGameProgress();
    });
  }

  void _simulateGameProgress() {
    for (final gameId in _activeGames.keys.toList()) {
      final game = _activeGames[gameId]!;

      if (game.hasEnded || !game.hasStarted) continue;

      // Simulate question progress
      if (game.currentQuestion != null && game.currentQuestion!.isTimeUp) {
        _moveToNextQuestion(gameId);
      }
    }
  }

  void _moveToNextQuestion(String gameId) {
    final game = _activeGames[gameId]!;

    if (game.currentQuestionIndex >= game.totalQuestions - 1) {
      // Game ended
      _endGame(gameId);
      return;
    }

    // Update scores randomly for demo
    final updatedPlayers = game.players.map((player) {
      return player.copyWith(
        score: player.score + (50 + (player.score % 100)),
        correctAnswers: player.correctAnswers + 1,
      );
    }).toList();

    _activeGames[gameId] = GameSpectateState(
      gameId: game.gameId,
      gameTitle: game.gameTitle,
      category: game.category,
      players: updatedPlayers,
      currentQuestion: _generateMockQuestion(game.currentQuestionIndex + 1),
      totalQuestions: game.totalQuestions,
      currentQuestionIndex: game.currentQuestionIndex + 1,
      spectatorCount: game.spectatorCount,
      hasStarted: true,
      hasEnded: false,
      startTime: game.startTime,
    );

    _broadcastGameUpdate(gameId);
  }

  void _endGame(String gameId) {
    final game = _activeGames[gameId]!;
    final winner = game.players.reduce((a, b) => a.score > b.score ? a : b);

    _activeGames[gameId] = GameSpectateState(
      gameId: game.gameId,
      gameTitle: game.gameTitle,
      category: game.category,
      players: game.players,
      currentQuestion: null,
      totalQuestions: game.totalQuestions,
      currentQuestionIndex: game.totalQuestions,
      spectatorCount: game.spectatorCount,
      hasStarted: true,
      hasEnded: true,
      winner: winner.name,
      startTime: game.startTime,
    );

    _broadcastGameUpdate(gameId);
  }

  void _broadcastGameUpdate(String gameId) {
    final game = _activeGames[gameId];
    if (game != null) {
      final controller = _gameStreams[gameId];
      if (controller != null && !controller.isClosed) {
        controller.add(game);
      }
    }
  }

  // Mock data generation for demo
  void _createMockGame(String gameId) {
    _activeGames[gameId] = GameSpectateState(
      gameId: gameId,
      gameTitle: 'Science Showdown',
      category: 'Science',
      players: [
        PlayerState(id: '1', name: 'Alex', score: 450),
        PlayerState(id: '2', name: 'Jordan', score: 380),
      ],
      currentQuestion: _generateMockQuestion(0),
      totalQuestions: 10,
      currentQuestionIndex: 0,
      spectatorCount: _spectators[gameId]?.length ?? 0,
      hasStarted: true,
      hasEnded: false,
      startTime: DateTime.now(),
    );
  }

  QuestionState _generateMockQuestion(int index) {
    final questions = [
      'What is the chemical symbol for gold?',
      'Which planet is known as the Red Planet?',
      'What is the speed of light?',
      'Who developed the theory of relativity?',
      'What is the largest organ in the human body?',
      'How many bones are in the adult human body?',
      'What is the powerhouse of the cell?',
      'What gas do plants absorb from the atmosphere?',
      'What is the boiling point of water?',
      'What is the smallest unit of life?',
    ];

    final optionsList = [
      ['Au', 'Ag', 'Fe', 'Cu'],
      ['Mars', 'Venus', 'Jupiter', 'Saturn'],
      ['299,792 km/s', '150,000 km/s', '500,000 km/s', '1,000,000 km/s'],
      ['Einstein', 'Newton', 'Galileo', 'Hawking'],
      ['Skin', 'Liver', 'Heart', 'Brain'],
      ['206', '186', '256', '306'],
      ['Mitochondria', 'Nucleus', 'Ribosome', 'Golgi'],
      ['CO2', 'O2', 'N2', 'H2'],
      ['100°C', '212°F', 'Both A & B', 'None'],
      ['Cell', 'Atom', 'Molecule', 'Tissue'],
    ];

    return QuestionState(
      index: index,
      question: questions[index % questions.length],
      options: optionsList[index % optionsList.length],
      startTime: DateTime.now(),
      timeLimit: const Duration(seconds: 15),
    );
  }
}
