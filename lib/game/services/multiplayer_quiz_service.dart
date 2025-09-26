import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../screens/multiplayer/widgets/base_multiplayer_question_widget.dart';
import '../../screens/question/widgets/adapted_question_widgets.dart';
import '../models/answer.dart';
import '../models/question_model.dart';
import '../providers/multiplayer_quiz_providers.dart';

class MultiplayerQuizService {
  final String baseUrl;
  final http.Client _client;
  final Map<String, StreamController<OpponentUpdate>> _updateStreams = {};

  MultiplayerQuizService({
    this.baseUrl = 'https://your-api-endpoint.com',
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Initialize a multiplayer match
  Future<MatchData> initializeMatch(String gameMode) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/multiplayer/matches'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameMode': gameMode,
          'playerCount': _getPlayerCountForGameMode(gameMode),
          'questionCount': _getQuestionCountForGameMode(gameMode),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MatchData.fromJson(data);
      } else if (response.statusCode == 404) {
        // No match found, create a mock match for demo
        return _createMockMatch(gameMode);
      } else {
        throw Exception('Failed to initialize match: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock match for development/demo
      return _createMockMatch(gameMode);
    }
  }

  // Get questions for a specific game mode
  Future<List<QuestionModel>> getQuestionsForGameMode(String gameMode) async {
    try {
      final category = _getCategoryForGameMode(gameMode);
      final difficulty = _getDifficultyForGameMode(gameMode);
      final count = _getQuestionCountForGameMode(gameMode);

      final response = await _client.get(
        Uri.parse('$baseUrl/api/questions').replace(queryParameters: {
          'category': category,
          'difficulty': difficulty,
          'count': count.toString(),
          'gameMode': gameMode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questionsData = data['questions'] as List;

        return questionsData
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch questions: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock questions for development
      return _generateMockQuestions(gameMode);
    }
  }

  // Submit an answer for the current question
  Future<void> submitAnswer(String matchId, String answer, int questionIndex) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/multiplayer/matches/$matchId/answers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'answer': answer,
          'questionIndex': questionIndex,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit answer: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, simulate successful submission
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate opponent answer after a delay
      Timer(Duration(seconds: 1 + Random().nextInt(3)), () {
        _simulateOpponentAnswer(matchId, questionIndex);
      });
    }
  }

  // Get real-time updates from opponent
  Stream<OpponentUpdate> getOpponentUpdates(String matchId) {
    if (_updateStreams[matchId] == null) {
      _updateStreams[matchId] = StreamController<OpponentUpdate>.broadcast();
      _startListeningForUpdates(matchId);
    }

    return _updateStreams[matchId]!.stream;
  }

  // Forfeit the current match
  Future<void> forfeitMatch(String matchId) async {
    try {
      await _client.post(
        Uri.parse('$baseUrl/api/multiplayer/matches/$matchId/forfeit'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Handle forfeit silently for demo
    } finally {
      _cleanupMatch(matchId);
    }
  }

  // Private helper methods

  int _getPlayerCountForGameMode(String gameMode) {
    switch (gameMode) {
      case 'teams':
        return 4; // 2v2 teams
      case 'arena':
      default:
        return 2; // 1v1
    }
  }

  int _getQuestionCountForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return 15; // Treasure Mine: More questions
      case 'teams':
        return 20; // Survival Arena: Even more
      default:
        return 10;
    }
  }

  String _getCategoryForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return 'mixed'; // Treasure Mine uses mixed categories
      case 'teams':
        return 'general'; // Survival Arena uses general knowledge
      default:
        return 'mixed';
    }
  }

  String _getDifficultyForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return 'medium'; // Treasure Mine: Moderate difficulty
      case 'teams':
        return 'hard'; // Survival Arena: High difficulty
      default:
        return 'easy';
    }
  }

  MatchData _createMockMatch(String gameMode) {
    final opponentNames = [
      'QuizMaster',
      'BrainBot',
      'ThinkTank',
      'SmartPlayer',
      'WiseOwl',
      'KnowledgeKing',
      'FactFinder',
      'TriviaTitan'
    ];

    return MatchData(
      matchId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      opponentName: opponentNames[Random().nextInt(opponentNames.length)],
      opponentAvatar: null,
      gameMode: gameMode,
      totalQuestions: _getQuestionCountForGameMode(gameMode),
    );
  }

  List<QuestionModel> _generateMockQuestions(String gameMode) {
    final count = _getQuestionCountForGameMode(gameMode);
    final questions = <QuestionModel>[];

    // Generate questions based on game mode theme
    final gameThemes = _getGameThemes(gameMode);

    for (int i = 0; i < count; i++) {
      final theme = gameThemes[i % gameThemes.length];
      questions.add(_createMockQuestion(i + 1, gameMode, theme));
    }

    return questions;
  }

  List<Map<String, dynamic>> _getGameThemes(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return [
          {'category': 'Science', 'icon': '🔬'},
          {'category': 'History', 'icon': '🏛️'},
          {'category': 'Geography', 'icon': '🌍'},
          {'category': 'Mathematics', 'icon': '🧮'},
          {'category': 'Literature', 'icon': '📚'},
        ];
      case 'teams':
        return [
          {'category': 'Sports', 'icon': '⚽'},
          {'category': 'Movies', 'icon': '🎬'},
          {'category': 'Music', 'icon': '🎵'},
          {'category': 'Technology', 'icon': '💻'},
          {'category': 'Nature', 'icon': '🌿'},
        ];
      default:
        return [
          {'category': 'General', 'icon': '🧠'},
        ];
    }
  }

  QuestionModel _createMockQuestion(int number, String gameMode, Map<String, dynamic> theme) {
    final sampleQuestions = _getSampleQuestions(theme['category']);
    final sample = sampleQuestions[Random().nextInt(sampleQuestions.length)];
    final options = List<String>.from(sample['options']);
    final correctAnswer = sample['correct'];
    final correctIndex = options.indexOf(correctAnswer);

    // Create Answer objects for the answers field
    final answers = options.asMap().entries.map((entry) {
      return Answer(
        text: entry.value,
        isCorrect: entry.value == correctAnswer,
      );
    }).toList();

    return QuestionModel(
      id: 'mock_${gameMode}_$number',
      category: theme['category'],
      question: sample['question'],
      answers: answers, // List<Answer> objects
      correctAnswer: correctAnswer,
      options: options, // List<String> for compatibility
      type: 'multiple_choice',
      difficulty: _getDifficultyLevelForGameMode(gameMode),
      correctIndex: correctIndex,
      powerUpHint: sample['hint'],
    );
  }

  // Add this helper method to return integer difficulty
  int _getDifficultyLevelForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return 2; // Medium difficulty
      case 'teams':
        return 3; // Hard difficulty
      default:
        return 1; // Easy difficulty
    }
  }

  String _getClassLevelForGameMode(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return '8'; // Middle school level for Treasure Mine
      case 'teams':
        return '10'; // High school level for Survival Arena
      default:
        return '6';
    }
  }

  List<Map<String, dynamic>> _getSampleQuestions(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return [
          {
            'question': 'What is the chemical symbol for gold?',
            'options': ['Go', 'Gd', 'Au', 'Ag'],
            'correct': 'Au',
            'hint': 'From the Latin word "aurum"',
          },
          {
            'question': 'Which planet is known as the Red Planet?',
            'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
            'correct': 'Mars',
            'hint': 'Named after the Roman god of war',
          },
        ];
      case 'history':
        return [
          {
            'question': 'Who was the first President of the United States?',
            'options': ['John Adams', 'Thomas Jefferson', 'George Washington', 'Benjamin Franklin'],
            'correct': 'George Washington',
            'hint': 'Known as the "Father of His Country"',
          },
          {
            'question': 'In which year did World War II end?',
            'options': ['1944', '1945', '1946', '1947'],
            'correct': '1945',
            'hint': 'The same year the atomic bombs were dropped',
          },
        ];
      case 'geography':
        return [
          {
            'question': 'What is the capital of Australia?',
            'options': ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
            'correct': 'Canberra',
            'hint': 'Not the largest city, but the planned capital',
          },
          {
            'question': 'Which river is the longest in the world?',
            'options': ['Amazon', 'Nile', 'Mississippi', 'Yangtze'],
            'correct': 'Nile',
            'hint': 'Flows through Egypt',
          },
        ];
      case 'mathematics':
        return [
          {
            'question': 'What is the value of π (pi) to 2 decimal places?',
            'options': ['3.14', '3.15', '3.16', '3.13'],
            'correct': '3.14',
            'hint': 'The ratio of circumference to diameter',
          },
          {
            'question': 'What is 12 × 8?',
            'options': ['84', '96', '104', '88'],
            'correct': '96',
            'hint': 'Think of it as 12 × 10 - 12 × 2',
          },
        ];
      case 'sports':
        return [
          {
            'question': 'How many players are on a basketball team on the court at once?',
            'options': ['4', '5', '6', '7'],
            'correct': '5',
            'hint': 'Same as the number of positions in basketball',
          },
          {
            'question': 'Which country hosted the 2016 Summer Olympics?',
            'options': ['China', 'UK', 'Brazil', 'Japan'],
            'correct': 'Brazil',
            'hint': 'Famous for Rio de Janeiro and Carnival',
          },
        ];
      default:
        return [
          {
            'question': 'What is the largest mammal in the world?',
            'options': ['Elephant', 'Blue Whale', 'Giraffe', 'Hippo'],
            'correct': 'Blue Whale',
            'hint': 'Lives in the ocean despite being a mammal',
          },
        ];
    }
  }

  void _startListeningForUpdates(String matchId) {
    // In a real implementation, this would establish WebSocket connection
    // For demo, we'll simulate updates periodically

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_updateStreams.containsKey(matchId)) {
        timer.cancel();
        return;
      }

      // Simulate random opponent activities
      if (Random().nextDouble() < 0.3) { // 30% chance per interval
        // This is handled in submitAnswer method
      }
    });
  }

  void _simulateOpponentAnswer(String matchId, int questionIndex) {
    final controller = _updateStreams[matchId];
    if (controller != null && !controller.isClosed) {
      // Simulate opponent answering (sometimes correct, sometimes not)
      final isCorrect = Random().nextDouble() < 0.6; // 60% accuracy
      final answers = ['A', 'B', 'C', 'D'];
      final selectedAnswer = isCorrect
          ? answers[0] // Assume first option is correct for simplicity
          : answers[Random().nextInt(answers.length)];

      controller.add(OpponentUpdate(
        type: OpponentUpdateType.answered,
        answer: selectedAnswer,
      ));
    }
  }

  void _cleanupMatch(String matchId) {
    final controller = _updateStreams[matchId];
    if (controller != null) {
      controller.close();
      _updateStreams.remove(matchId);
    }
  }

  void dispose() {
    for (final controller in _updateStreams.values) {
      controller.close();
    }
    _updateStreams.clear();
    _client.close();
  }
}

// Provider for the service
final multiplayerQuizServiceProvider = Provider<MultiplayerQuizService>((ref) {
  final service = MultiplayerQuizService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Enhanced AdaptedQuestionWidget to support multiplayer
extension AdaptedQuestionWidgetMultiplayer on AdaptedQuestionWidget {
  static Widget create({
    required QuestionModel question,
    required Function(String)? onAnswerSelected,
    bool showFeedback = false,
    String? selectedAnswer,
    bool isMultiplayer = false,
  }) {
    // Create the appropriate question widget based on type
    switch (question.type.toLowerCase()) {
      case 'multiple_choice':
        return MultipleChoiceQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      case 'true_false':
        return TrueFalseQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      case 'fill_blank':
        return FillBlankQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      default:
        return MultipleChoiceQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
    }
  }
}
