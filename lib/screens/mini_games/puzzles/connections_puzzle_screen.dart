import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../dialogs/game_result_dialog.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class ConnectionsPuzzleScreen extends StatefulWidget {
  const ConnectionsPuzzleScreen({super.key});

  @override
  State<ConnectionsPuzzleScreen> createState() =>
      _ConnectionsPuzzleScreenState();
}

class _ConnectionsPuzzleScreenState extends State<ConnectionsPuzzleScreen> {
  // Timer variables
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  bool _puzzleCompleted = false;

  // Game state
  List<String> selectedWords = [];
  List<Category> solvedCategories = [];
  int mistakesRemaining = 4;
  List<String> shuffledWords = [];

  // Current puzzle
  late List<Category> currentPuzzle;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (!_isTimerRunning && !_puzzleCompleted) {
      _isTimerRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _secondsElapsed++;
          });
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _generatePuzzle() {
    // Sample puzzles - you can add more
    final puzzles = [
      [
        Category(
          name: 'Fruits',
          words: ['Apple', 'Banana', 'Orange', 'Cherry'],
          color: const Color(0xFF60A5FA),
          difficulty: 1,
        ),
        Category(
          name: 'Colors',
          words: ['Red', 'Blue', 'Green', 'Yellow'],
          color: const Color(0xFF34D399),
          difficulty: 2,
        ),
        Category(
          name: 'Metals',
          words: ['Gold', 'Silver', 'Iron', 'Copper'],
          color: const Color(0xFFFBBF24),
          difficulty: 3,
        ),
        Category(
          name: 'Planets',
          words: ['Mars', 'Venus', 'Earth', 'Saturn'],
          color: const Color(0xFFA78BFA),
          difficulty: 4,
        ),
      ],
      [
        Category(
          name: 'Programming Languages',
          words: ['Python', 'Java', 'Swift', 'Ruby'],
          color: const Color(0xFF60A5FA),
          difficulty: 1,
        ),
        Category(
          name: 'Animals',
          words: ['Tiger', 'Elephant', 'Lion', 'Giraffe'],
          color: const Color(0xFF34D399),
          difficulty: 2,
        ),
        Category(
          name: 'US States',
          words: ['Texas', 'Florida', 'Georgia', 'Maine'],
          color: const Color(0xFFFBBF24),
          difficulty: 3,
        ),
        Category(
          name: 'Card Games',
          words: ['Poker', 'Bridge', 'Hearts', 'Spades'],
          color: const Color(0xFFA78BFA),
          difficulty: 4,
        ),
      ],
      [
        Category(
          name: 'Math Terms',
          words: ['Sum', 'Product', 'Quotient', 'Difference'],
          color: const Color(0xFF60A5FA),
          difficulty: 1,
        ),
        Category(
          name: 'Weather',
          words: ['Sunny', 'Rainy', 'Cloudy', 'Windy'],
          color: const Color(0xFF34D399),
          difficulty: 2,
        ),
        Category(
          name: 'Instruments',
          words: ['Piano', 'Guitar', 'Drums', 'Violin'],
          color: const Color(0xFFFBBF24),
          difficulty: 3,
        ),
        Category(
          name: 'Emotions',
          words: ['Happy', 'Sad', 'Angry', 'Excited'],
          color: const Color(0xFFA78BFA),
          difficulty: 4,
        ),
      ],
    ];

    final random = Random();
    currentPuzzle = puzzles[random.nextInt(puzzles.length)];

    // Shuffle all words together
    shuffledWords = [];
    for (var category in currentPuzzle) {
      shuffledWords.addAll(category.words);
    }
    shuffledWords.shuffle(random);

    // Reset game state
    selectedWords.clear();
    solvedCategories.clear();
    mistakesRemaining = 4;
    _secondsElapsed = 0;
    _puzzleCompleted = false;
  }

  void _toggleWord(String word) {
    if (_puzzleCompleted) return;

    // Start timer on first selection
    if (!_isTimerRunning && _secondsElapsed == 0) {
      _startTimer();
    }

    setState(() {
      if (selectedWords.contains(word)) {
        selectedWords.remove(word);
      } else {
        if (selectedWords.length < 4) {
          selectedWords.add(word);
        }
      }
    });
  }

  void _submitGuess() {
    if (selectedWords.length != 4) {
      _showMessage('Select exactly 4 words');
      return;
    }

    // Check if this matches any unsolved category
    for (var category in currentPuzzle) {
      if (solvedCategories.contains(category)) continue;

      final categoryWords = Set.from(category.words);
      final selectedSet = Set.from(selectedWords);

      if (categoryWords.difference(selectedSet).isEmpty &&
          selectedSet.difference(categoryWords).isEmpty) {
        // Correct!
        setState(() {
          solvedCategories.add(category);
          shuffledWords.removeWhere((word) => selectedWords.contains(word));
          selectedWords.clear();
        });

        // Check if puzzle completed
        if (solvedCategories.length == currentPuzzle.length) {
          _stopTimer();
          _puzzleCompleted = true;
          _showCompletionDialog();
        }
        return;
      }
    }

    // Wrong guess
    setState(() {
      mistakesRemaining--;
      selectedWords.clear();
    });

    if (mistakesRemaining == 0) {
      _stopTimer();
      _puzzleCompleted = true;
      _showFailureDialog();
    } else {
      _showMessage(
          'Not quite! $mistakesRemaining ${mistakesRemaining == 1 ? "attempt" : "attempts"} remaining');
    }
  }

  void _deselectAll() {
    setState(() {
      selectedWords.clear();
    });
  }

  void _shuffle() {
    setState(() {
      shuffledWords.shuffle(Random());
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCompletionDialog() {
    final time = _formatTime(_secondsElapsed);
    final mistakes = 4 - mistakesRemaining;

    String achievementTitle = 'Connection Master!';
    String achievementSubtitle = 'All groups found successfully';

    if (mistakes == 0) {
      achievementTitle = 'Perfect Game!';
      achievementSubtitle = 'No mistakes - flawless victory';
    } else if (mistakes == 1) {
      achievementTitle = 'Excellent Work!';
      achievementSubtitle = 'Found all connections with ease';
    } else if (mistakes <= 2) {
      achievementTitle = 'Great Job!';
      achievementSubtitle = 'Strong pattern recognition';
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Connections Puzzle',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.link,
      ),
      onShare: () {
        LogManager.debug('Share tapped');
      },
      onClose: () {
        LogManager.debug('Close tapped');
      },
      onPlayAgain: () {
        setState(() {
          _stopTimer();
          _generatePuzzle();
        });
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Game Over'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You\'ve run out of attempts!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'The categories were:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...currentPuzzle.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${category.name}: ${category.words.join(", ")}',
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _stopTimer();
                _generatePuzzle();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'How to Play',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRule(
                'Find groups of four words that share something in common.'),
            _buildRule(
                'Select four words and tap Submit to check if your guess is correct.'),
            _buildRule('Each puzzle has exactly four groups to find.'),
            _buildRule(
                'You have 4 attempts to find all groups. Every wrong guess costs you an attempt.'),
            _buildRule(
                'The groups are color-coded by difficulty from easiest to hardest.'),
            _buildRule('Complete the puzzle as fast as you can!'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Mistakes remaining
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$mistakesRemaining',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Timer display
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_secondsElapsed),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _stopTimer();
                _generatePuzzle();
              });
            },
            tooltip: 'New Puzzle',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // How to Play Button
                      GestureDetector(
                        onTap: _showHowToPlay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'How to Play',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Solved categories
                      ...solvedCategories
                          .map((category) => _buildSolvedCategory(category)),

                      // Available words grid
                      if (shuffledWords.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.8,
                            ),
                            itemCount: shuffledWords.length,
                            itemBuilder: (context, index) {
                              final word = shuffledWords[index];
                              final isSelected = selectedWords.contains(word);

                              return GestureDetector(
                                onTap: () => _toggleWord(word),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          'Shuffle',
                          Icons.shuffle,
                          onPressed: shuffledWords.isNotEmpty ? _shuffle : null,
                        ),
                        const SizedBox(width: 12),
                        _buildControlButton(
                          'Deselect All',
                          Icons.clear,
                          onPressed:
                              selectedWords.isNotEmpty ? _deselectAll : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            selectedWords.length == 4 && !_puzzleCompleted
                                ? _submitGuess
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolvedCategory(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.words.join(', '),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String text, IconData icon,
      {VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled
            ? const Color(0xFFE0DDD9)
            : const Color(0xFFE0DDD9).withValues(alpha: 0.5),
        foregroundColor: isEnabled
            ? const Color(0xFF4A4A4A)
            : const Color(0xFF4A4A4A).withValues(alpha: 0.5),
        elevation: isEnabled ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class Category {
  final String name;
  final List<String> words;
  final Color color;
  final int difficulty;

  Category({
    required this.name,
    required this.words,
    required this.color,
    required this.difficulty,
  });
}
