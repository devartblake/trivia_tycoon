import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../dialogs/crossword_settings_dialog.dart';
import '../dialogs/game_result_dialog.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({super.key});

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  late CrosswordController _controller;
  bool _isLoading = true;
  String? _error;
  final FocusNode _focusNode = FocusNode();
  CrosswordCategory _category = CrosswordCategory.scienceTech;

  void _showResultDialog() {
    final completedWords = _controller.completedWords;
    final totalWords = _controller.totalWords;
    final time = _controller.formattedTime;

    String achievementTitle = 'Word Wizard!';
    String achievementSubtitle = 'You solved the crossword puzzle';

    if (completedWords == totalWords) {
      if (_controller._secondsElapsed < 180) {
        achievementTitle = 'Speed Solver!';
        achievementSubtitle = 'Completed in under 3 minutes';
      } else if (_controller._secondsElapsed < 300) {
        achievementTitle = 'Crossword Champion!';
        achievementSubtitle = 'All words correctly completed';
      } else {
        achievementTitle = 'Puzzle Master!';
        achievementSubtitle = 'You solved the entire puzzle';
      }
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Crossword Puzzle',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.grid_on,
      ),
      onShare: () {
        LogManager.debug('Share tapped');
      },
      onClose: () {
        LogManager.debug('Close tapped');
      },
      onPlayAgain: () {
        setState(() {
          _isLoading = true;
        });
        _initGame();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    try {
      // Logic to get the correct asset path from the enum
      String categoryString;
      switch (_category) {
        case CrosswordCategory.scienceTech:
          categoryString = 'science_tech';
          break;
        case CrosswordCategory.vocabulary:
          categoryString = 'vocabulary';
          break;
        case CrosswordCategory.historyGeo:
          categoryString = 'history_geo';
          break;
        case CrosswordCategory.literaturePhilosophy:
          categoryString = 'literature_philosophy';
          break;
        case CrosswordCategory.cultureMisc:
          categoryString = 'culture_misc';
          break;
      }

      final assetPath =
          'assets/data/mini-games/crossword_hard_${categoryString}_packs.json';
      final data = await CrosswordDataLoader.loadCrossword(assetPath);
      _controller =
          CrosswordController(data, onPuzzleComplete: _showResultDialog);
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load puzzle for this category.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!_isLoading && _error == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showSettingsDialog() async {
    final newCategory = await showDialog<CrosswordCategory>(
      context: context,
      builder: (context) => CrosswordSettingsDialog(initialCategory: _category),
    );

    if (newCategory != null) {
      _category = newCategory;
      _initGame();
    }
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
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            const SizedBox(height: 24),
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
            ...[
              'Click or tap a cell to select it.',
              'Click a cell twice to toggle direction (across/down).',
              'Type letters using your keyboard.',
              'Use arrow keys to navigate between cells.',
              'Press Backspace to delete letters.',
              'Correct letters appear in black, incorrect in red.',
              'Complete all words to win!',
            ].map((text) => _buildRule(text)),
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
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crossword'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crossword'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initGame,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _controller.backspace();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _controller.moveSelection(Direction.up);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _controller.moveSelection(Direction.down);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _controller.moveSelection(Direction.left);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _controller.moveSelection(Direction.right);
          } else if (event.character != null &&
              event.character!.length == 1 &&
              RegExp(r'^[a-zA-Z]$').hasMatch(event.character!)) {
            _controller.typeChar(event.character!);
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          appBar: AppBar(
            title: const Text(
              'Crossword',
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, size: 22),
                onPressed: _showHowToPlay,
              ),
              IconButton(
                icon: const Icon(Icons.category_outlined, size: 22),
                onPressed: _showSettingsDialog,
                tooltip: 'Change Category',
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          '${_controller.completedWords}/${_controller.totalWords}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CrosswordGrid(controller: _controller),
                        const SizedBox(height: 24),
                        CrosswordClues(controller: _controller),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data Loader
class CrosswordDataLoader {
  static Future<CrosswordData> loadCrossword(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);

      final puzzles = jsonData['puzzles'] as List;
      if (puzzles.isEmpty) {
        throw Exception('No puzzles found in this category.');
      }
      final randomPuzzle = puzzles[Random().nextInt(puzzles.length)];

      return CrosswordData.fromJson(randomPuzzle);
    } catch (e) {
      LogManager.debug('Error loading crossword: $e');
      // Fallback data for testing if a file is missing or empty
      return CrosswordData(
        gridSize: 8,
        words: [
          CrosswordWord(
            word: 'FLUTTER',
            clue: 'Google\'s UI toolkit',
            startRow: 0,
            startCol: 0,
            direction: WordDirection.across,
          ),
          CrosswordWord(
            word: 'DART',
            clue: 'Programming language',
            startRow: 0,
            startCol: 0,
            direction: WordDirection.down,
          ),
          CrosswordWord(
            word: 'WIDGET',
            clue: 'UI building block',
            startRow: 2,
            startCol: 1,
            direction: WordDirection.across,
          ),
        ],
      );
    }
  }
}

// Controller
class CrosswordController extends ChangeNotifier {
  final CrosswordData data;
  final VoidCallback? onPuzzleComplete;

  List<List<CrosswordCell>> grid = [];
  Map<CrosswordWord, int> wordNumbers = {};
  int? selectedRow;
  int? selectedCol;
  WordDirection currentDirection = WordDirection.across;

  // Add timer
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _puzzleCompleted = false;

  CrosswordController(this.data, {this.onPuzzleComplete}) {
    _buildGrid();
    _selectFirstCell();
    _startTimer();
  }

  String get formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_puzzleCompleted) {
        _secondsElapsed++;
        notifyListeners();
      }
    });
  }

  int get completedWords => data.words.where((w) => _isWordComplete(w)).length;
  int get totalWords => data.words.length;

  void _buildGrid() {
    grid = List.generate(
      data.gridSize,
      (i) => List.generate(
        data.gridSize,
        (j) => CrosswordCell(row: i, col: j),
      ),
    );
    wordNumbers.clear();
    final Map<String, int> positionNumbers = {};
    int counter = 1;

    // Sort words by position to ensure consistent numbering
    data.words.sort((a, b) {
      if (a.startRow != b.startRow) return a.startRow.compareTo(b.startRow);
      return a.startCol.compareTo(b.startCol);
    });

    for (final word in data.words) {
      final posKey = '${word.startRow}-${word.startCol}';
      if (!positionNumbers.containsKey(posKey)) {
        positionNumbers[posKey] = counter++;
      }
      wordNumbers[word] = positionNumbers[posKey]!;
    }

    for (final word in data.words) {
      for (int i = 0; i < word.word.length; i++) {
        final row = word.direction == WordDirection.across
            ? word.startRow
            : word.startRow + i;
        final col = word.direction == WordDirection.across
            ? word.startCol + i
            : word.startCol;

        if (row < data.gridSize && col < data.gridSize) {
          grid[row][col].correctLetter = word.word[i];
          grid[row][col].isActive = true;

          if (i == 0) {
            grid[row][col].number = wordNumbers[word];
          }
        }
      }
    }
  }

  void _selectFirstCell() {
    for (int i = 0; i < data.gridSize; i++) {
      for (int j = 0; j < data.gridSize; j++) {
        if (grid[i][j].isActive) {
          selectCell(i, j);
          return;
        }
      }
    }
  }

  void selectCell(int row, int col) {
    if (!grid[row][col].isActive) return;

    if (selectedRow == row && selectedCol == col) {
      // Toggle direction only if both directions are possible from this cell
      final words = _getWordsAtPosition(row, col);
      bool hasAcross = words.any((w) => w.direction == WordDirection.across);
      bool hasDown = words.any((w) => w.direction == WordDirection.down);
      if (hasAcross && hasDown) {
        currentDirection = currentDirection == WordDirection.across
            ? WordDirection.down
            : WordDirection.across;
      }
    } else {
      selectedRow = row;
      selectedCol = col;
      // When selecting a new cell, prioritize the 'across' direction if available
      final words = _getWordsAtPosition(row, col);
      if (words.any((w) => w.direction == WordDirection.across)) {
        currentDirection = WordDirection.across;
      } else if (words.isNotEmpty) {
        currentDirection = words.first.direction;
      }
    }
    notifyListeners();
  }

  List<CrosswordWord> _getWordsAtPosition(int row, int col) {
    return data.words.where((word) {
      if (word.direction == WordDirection.across) {
        return row == word.startRow &&
            col >= word.startCol &&
            col < word.startCol + word.word.length;
      } else {
        // down
        return col == word.startCol &&
            row >= word.startRow &&
            row < word.startRow + word.word.length;
      }
    }).toList();
  }

  CrosswordWord? _getCurrentWord() {
    if (selectedRow == null || selectedCol == null) return null;

    final words = _getWordsAtPosition(selectedRow!, selectedCol!)
        .where((w) => w.direction == currentDirection)
        .toList();

    if (words.isNotEmpty) {
      words.sort((a, b) {
        final distA = (a.startRow - selectedRow!).abs() +
            (a.startCol - selectedCol!).abs();
        final distB = (b.startRow - selectedRow!).abs() +
            (b.startCol - selectedCol!).abs();
        return distA.compareTo(distB);
      });
      return words.first;
    }
    return null;
  }

  void typeChar(String char) {
    if (selectedRow == null || selectedCol == null) return;
    grid[selectedRow!][selectedCol!].userLetter = char.toUpperCase();
    _moveToNextCell();
    // Check if puzzle is complete
    _checkCompletion();
    notifyListeners();
  }

  void _checkCompletion() {
    if (_puzzleCompleted) return;

    // Check if all words are complete
    bool allComplete = true;
    for (var word in data.words) {
      if (!_isWordComplete(word)) {
        allComplete = false;
        break;
      }
    }

    if (allComplete) {
      _puzzleCompleted = true;
      _timer?.cancel();

      // Trigger completion callback after a brief delay
      Future.delayed(const Duration(milliseconds: 500), () {
        onPuzzleComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void backspace() {
    if (selectedRow == null || selectedCol == null) return;
    if (grid[selectedRow!][selectedCol!].userLetter.isEmpty) {
      _moveToPreviousCell();
    }
    if (selectedRow != null && selectedCol != null) {
      grid[selectedRow!][selectedCol!].userLetter = '';
    }
    notifyListeners();
  }

  void _moveToNextCell() {
    if (selectedRow == null || selectedCol == null) return;
    final word = _getCurrentWord();
    if (word == null) return;

    int nextRow = selectedRow!;
    int nextCol = selectedCol!;

    if (currentDirection == WordDirection.across) {
      if (selectedCol! < word.startCol + word.word.length - 1) {
        nextCol++;
      }
    } else {
      // down
      if (selectedRow! < word.startRow + word.word.length - 1) {
        nextRow++;
      }
    }

    if (grid[nextRow][nextCol].isActive) {
      selectedRow = nextRow;
      selectedCol = nextCol;
    }
  }

  void _moveToPreviousCell() {
    if (selectedRow == null || selectedCol == null) return;
    final word = _getCurrentWord();
    if (word == null) return;

    int prevRow = selectedRow!;
    int prevCol = selectedCol!;

    if (currentDirection == WordDirection.across) {
      if (selectedCol! > word.startCol) {
        prevCol--;
      }
    } else {
      // down
      if (selectedRow! > word.startRow) {
        prevRow--;
      }
    }

    if (grid[prevRow][prevCol].isActive) {
      selectedRow = prevRow;
      selectedCol = prevCol;
    }
  }

  void moveSelection(Direction dir) {
    if (selectedRow == null || selectedCol == null) return;
    int newRow = selectedRow!;
    int newCol = selectedCol!;
    switch (dir) {
      case Direction.up:
        newRow = max(0, newRow - 1);
        break;
      case Direction.down:
        newRow = min(data.gridSize - 1, newRow + 1);
        break;
      case Direction.left:
        newCol = max(0, newCol - 1);
        break;
      case Direction.right:
        newCol = min(data.gridSize - 1, newCol + 1);
        break;
    }
    if (grid[newRow][newCol].isActive) {
      selectedRow = newRow;
      selectedCol = newCol;
      notifyListeners();
    }
  }

  bool _isWordComplete(CrosswordWord word) {
    final cells = _getWordCells(word);
    return cells.every((c) => c.userLetter == c.correctLetter);
  }

  List<CrosswordCell> _getWordCells(CrosswordWord word) {
    List<CrosswordCell> cells = [];
    for (int i = 0; i < word.word.length; i++) {
      final row = word.direction == WordDirection.across
          ? word.startRow
          : word.startRow + i;
      final col = word.direction == WordDirection.across
          ? word.startCol + i
          : word.startCol;
      cells.add(grid[row][col]);
    }
    return cells;
  }

  bool isCellInCurrentWord(int row, int col) {
    final word = _getCurrentWord();
    if (word == null) return false;
    final cells = _getWordCells(word);
    return cells.any((c) => c.row == row && c.col == col);
  }

  bool isCellSelected(int row, int col) {
    return selectedRow == row && selectedCol == col;
  }
}

// Grid Widget
class CrosswordGrid extends StatelessWidget {
  final CrosswordController controller;

  const CrosswordGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: controller.data.gridSize,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: controller.data.gridSize * controller.data.gridSize,
              itemBuilder: (context, index) {
                final row = index ~/ controller.data.gridSize;
                final col = index % controller.data.gridSize;
                final cell = controller.grid[row][col];

                return GestureDetector(
                  onTap: () => controller.selectCell(row, col),
                  child: _buildCell(
                    cell,
                    controller.isCellSelected(row, col),
                    controller.isCellInCurrentWord(row, col),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(CrosswordCell cell, bool isSelected, bool isInCurrentWord) {
    if (!cell.isActive) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final isWrong =
        cell.userLetter.isNotEmpty && cell.userLetter != cell.correctLetter;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFC7D2FE)
            : isInCurrentWord
                ? const Color(0xFFE0E7FF)
                : Colors.white,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6366F1)
              : isInCurrentWord
                  ? const Color(0xFFC7D2FE)
                  : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          if (cell.number != null)
            Positioned(
              top: 2,
              left: 3,
              child: Text(
                '${cell.number}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          Center(
            child: Text(
              cell.userLetter,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isWrong ? Colors.red.shade600 : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clues Widget
class CrosswordClues extends StatelessWidget {
  final CrosswordController controller;

  const CrosswordClues({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final acrossWords = controller.data.words
        .where((w) => w.direction == WordDirection.across)
        .toList();
    final downWords = controller.data.words
        .where((w) => w.direction == WordDirection.down)
        .toList();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClueSection('Across', acrossWords),
            const SizedBox(height: 20),
            _buildClueSection('Down', downWords),
          ],
        );
      },
    );
  }

  Widget _buildClueSection(String title, List<CrosswordWord> words) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...words.map((word) => _buildClueItem(word)),
        ],
      ),
    );
  }

  Widget _buildClueItem(CrosswordWord word) {
    final index = controller.wordNumbers[word]!;
    final isComplete = controller._isWordComplete(word);
    final currentWord = controller._getCurrentWord();
    final isSelected = currentWord == word;

    return InkWell(
      onTap: () {
        controller.selectCell(word.startRow, word.startCol);
        if (controller.currentDirection != word.direction) {
          controller.selectCell(word.startRow, word.startCol);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$index.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                word.clue,
                style: TextStyle(
                  fontSize: 14,
                  color: isComplete
                      ? Colors.grey.shade500
                      : const Color(0xFF475569),
                  decoration: isComplete ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
enum WordDirection { across, down }

enum Direction { up, down, left, right }

class CrosswordData {
  final int gridSize;
  final List<CrosswordWord> words;

  CrosswordData({required this.gridSize, required this.words});

  factory CrosswordData.fromJson(Map<String, dynamic> json) {
    return CrosswordData(
      gridSize: json['gridSize'] ?? 10,
      words: (json['words'] as List)
          .map((w) => CrosswordWord.fromJson(w))
          .toList(),
    );
  }
}

class CrosswordWord {
  final String word;
  final String clue;
  final int startRow;
  final int startCol;
  final WordDirection direction;

  CrosswordWord({
    required this.word,
    required this.clue,
    required this.startRow,
    required this.startCol,
    required this.direction,
  });

  factory CrosswordWord.fromJson(Map<String, dynamic> json) {
    return CrosswordWord(
      word: json['word'].toString().toUpperCase(),
      clue: json['clue'],
      startRow: json['startRow'],
      startCol: json['startCol'],
      direction: json['direction'] == 'across'
          ? WordDirection.across
          : WordDirection.down,
    );
  }
}

class CrosswordCell {
  final int row;
  final int col;
  int? number;
  String correctLetter = '';
  String userLetter = '';
  bool isActive = false;

  CrosswordCell({required this.row, required this.col});
}
