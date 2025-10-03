import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'dialogs/game_result_dialog.dart';

class SudokuPuzzleScreen extends StatefulWidget {
  const SudokuPuzzleScreen({super.key});

  @override
  State<SudokuPuzzleScreen> createState() => _SudokuPuzzleScreenState();
}

class _SudokuPuzzleScreenState extends State<SudokuPuzzleScreen> {
  static const int gridSize = 9;

  // Timer variables
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  bool _puzzleCompleted = false;

  // Game state
  List<List<int>> puzzle = [];
  List<List<int>> solution = [];
  List<List<bool>> isFixed = [];
  Point<int>? selectedCell;
  List<List<List<int>>> history = [];

  // Difficulty levels
  String currentDifficulty = 'Easy';
  final Map<String, int> difficultyCells = {
    'Easy': 40,
    'Medium': 30,
    'Hard': 25,
  };

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
    // Generate a complete valid Sudoku solution
    solution = _generateCompleteSudoku();

    // Create puzzle by removing numbers
    puzzle = List.generate(
      gridSize,
          (i) => List.generate(gridSize, (j) => solution[i][j]),
    );

    isFixed = List.generate(
      gridSize,
          (_) => List.generate(gridSize, (_) => false),
    );

    // Remove numbers based on difficulty
    final cellsToShow = difficultyCells[currentDifficulty]!;
    final random = Random();
    List<Point<int>> positions = [];

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        positions.add(Point(i, j));
      }
    }

    positions.shuffle(random);

    // Keep only the specified number of cells
    for (int i = 0; i < cellsToShow; i++) {
      final pos = positions[i];
      isFixed[pos.x][pos.y] = true;
    }

    // Clear non-fixed cells
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!isFixed[i][j]) {
          puzzle[i][j] = 0;
        }
      }
    }

    selectedCell = null;
    _secondsElapsed = 0;
    _puzzleCompleted = false;
    history.clear();
  }

  List<List<int>> _generateCompleteSudoku() {
    List<List<int>> board = List.generate(
      gridSize,
          (_) => List.generate(gridSize, (_) => 0),
    );

    _fillSudoku(board);
    return board;
  }

  bool _fillSudoku(List<List<int>> board) {
    final random = Random();

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
          numbers.shuffle(random);

          for (int num in numbers) {
            if (_isValidPlacement(board, row, col, num)) {
              board[row][col] = num;

              if (_fillSudoku(board)) {
                return true;
              }

              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < gridSize; x++) {
      if (board[row][x] == num) return false;
    }

    // Check column
    for (int x = 0; x < gridSize; x++) {
      if (board[x][col] == num) return false;
    }

    // Check 3x3 box
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  void _selectCell(int row, int col) {
    if (_puzzleCompleted) return;

    // Start timer on first selection
    if (!_isTimerRunning && _secondsElapsed == 0) {
      _startTimer();
    }

    setState(() {
      if (selectedCell?.x == row && selectedCell?.y == col) {
        selectedCell = null;
      } else {
        selectedCell = Point(row, col);
      }
    });
  }

  void _placeNumber(int number) {
    if (selectedCell == null || _puzzleCompleted) return;
    if (isFixed[selectedCell!.x][selectedCell!.y]) return;

    setState(() {
      // Save history
      history.add(puzzle.map((r) => List<int>.from(r)).toList());

      puzzle[selectedCell!.x][selectedCell!.y] = number;

      // Check completion
      _checkCompletion();
    });
  }

  void _clearCell() {
    if (selectedCell == null || _puzzleCompleted) return;
    if (isFixed[selectedCell!.x][selectedCell!.y]) return;

    setState(() {
      history.add(puzzle.map((r) => List<int>.from(r)).toList());
      puzzle[selectedCell!.x][selectedCell!.y] = 0;
    });
  }

  void _checkCompletion() {
    // Check if all cells are filled
    for (var row in puzzle) {
      for (var cell in row) {
        if (cell == 0) return;
      }
    }

    // Check if solution is correct
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (puzzle[i][j] != solution[i][j]) {
          _showMessage('Some numbers are incorrect. Keep trying!');
          return;
        }
      }
    }

    // Puzzle completed!
    _stopTimer();
    setState(() {
      _puzzleCompleted = true;
    });
    _showCompletionDialog();
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

  void _undo() {
    if (history.isNotEmpty && !_puzzleCompleted) {
      setState(() {
        puzzle = history.removeLast();
      });
    }
  }

  void _showCompletionDialog() {
    final time = _formatTime(_secondsElapsed);

    String achievementTitle = 'Sudoku Master!';
    String achievementSubtitle = 'You solved the puzzle perfectly';

    switch (currentDifficulty) {
      case 'Easy':
        if (_secondsElapsed < 300) {
          achievementTitle = 'Speed Solver!';
          achievementSubtitle = 'Easy puzzle completed quickly';
        } else {
          achievementTitle = 'Sudoku Solver!';
          achievementSubtitle = 'Easy puzzle completed';
        }
        break;
      case 'Medium':
        if (_secondsElapsed < 600) {
          achievementTitle = 'Quick Thinker!';
          achievementSubtitle = 'Medium puzzle solved efficiently';
        } else {
          achievementTitle = 'Logic Champion!';
          achievementSubtitle = 'Medium puzzle mastered';
        }
        break;
      case 'Hard':
        if (_secondsElapsed < 900) {
          achievementTitle = 'Sudoku Genius!';
          achievementSubtitle = 'Hard puzzle conquered quickly';
        } else {
          achievementTitle = 'Sudoku Legend!';
          achievementSubtitle = 'Hard puzzle conquered';
        }
        break;
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Sudoku - $currentDifficulty',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.grid_4x4,
      ),
      onShare: () {
        debugPrint('Share tapped');
      },
      onClose: () {
        debugPrint('Close tapped');
      },
      onPlayAgain: () {
        setState(() {
          _stopTimer();
          _generatePuzzle();
        });
      },
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
                    color: const Color(0xFF6366F1).withOpacity(0.1),
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
            _buildRule('Fill the 9×9 grid with digits from 1 to 9.'),
            _buildRule('Each row must contain all digits from 1 to 9 without repetition.'),
            _buildRule('Each column must contain all digits from 1 to 9 without repetition.'),
            _buildRule('Each 3×3 box must contain all digits from 1 to 9 without repetition.'),
            _buildRule('Tap a cell to select it, then tap a number below to place it.'),
            _buildRule('Gray cells are fixed and cannot be changed.'),
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

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Select Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption('Easy', Colors.green),
            _buildDifficultyOption('Medium', Colors.orange),
            _buildDifficultyOption('Hard', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String difficulty, Color color) {
    final isSelected = currentDifficulty == difficulty;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: color,
      ),
      title: Text(
        difficulty,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          currentDifficulty = difficulty;
          _stopTimer();
          _generatePuzzle();
        });
      },
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
          'Sudoku',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'difficulty') {
                _showDifficultyDialog();
              } else if (value == 'new') {
                setState(() {
                  _stopTimer();
                  _generatePuzzle();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'difficulty',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 20),
                    SizedBox(width: 8),
                    Text('Difficulty'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('New Puzzle'),
                  ],
                ),
              ),
            ],
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
                      GestureDetector(
                        onTap: _showHowToPlay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
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

                      // Difficulty indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getDifficultyColor().withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          currentDifficulty,
                          style: TextStyle(
                            color: _getDifficultyColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sudoku Grid
                      Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildSudokuGrid(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Number pad and controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Number buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(9, (i) => _buildNumberButton(i + 1)),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton('Undo', Icons.undo, _undo,
                            enabled: history.isNotEmpty && !_puzzleCompleted),
                        _buildActionButton('Clear', Icons.clear, _clearCell,
                            enabled: selectedCell != null && !_puzzleCompleted),
                        _buildActionButton('Check', Icons.check_circle, _checkCompletion,
                            enabled: !_puzzleCompleted),
                      ],
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

  Widget _buildSudokuGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, index) {
        int row = index ~/ gridSize;
        int col = index % gridSize;

        return _buildCell(row, col);
      },
    );
  }

  Widget _buildCell(int row, int col) {
    final isSelected = selectedCell?.x == row && selectedCell?.y == col;
    final isFixedCell = isFixed[row][col];
    final value = puzzle[row][col];

    // Thick borders for 3x3 boxes
    final isRightBorder = (col + 1) % 3 == 0 && col < 8;
    final isBottomBorder = (row + 1) % 3 == 0 && row < 8;

    return GestureDetector(
      onTap: () => _selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.2)
              : isFixedCell
              ? Colors.grey.shade200
              : Colors.white,
          border: Border(
            right: BorderSide(
              width: isRightBorder ? 2 : 0.5,
              color: isRightBorder ? Colors.black : Colors.grey.shade300,
            ),
            bottom: BorderSide(
              width: isBottomBorder ? 2 : 0.5,
              color: isBottomBorder ? Colors.black : Colors.grey.shade300,
            ),
          ),
        ),
        child: Center(
          child: value != 0
              ? Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: isFixedCell ? FontWeight.bold : FontWeight.normal,
              color: isFixedCell
                  ? Colors.black
                  : const Color(0xFF6366F1),
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return GestureDetector(
      onTap: () => _placeNumber(number),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE0DDD9) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: enabled ? const Color(0xFF4A4A4A) : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? const Color(0xFF4A4A4A) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (currentDifficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
