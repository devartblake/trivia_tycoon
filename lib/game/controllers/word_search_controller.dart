import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_search_model.dart';

class WordSearchController extends ChangeNotifier {
  static const int gridSize = 12;

  List<List<String>> grid = [];
  List<WordPosition> wordPositions = [];
  List<String> words = [];
  Set<String> foundWords = {};

  Timer? _timer;
  int _secondsElapsed = 0;

  Point<int>? _dragStart;
  Point<int>? _dragEnd;
  bool isDragging = false;

  final VoidCallback? onPuzzleComplete;

  final List<Color> _highlightColors = [
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
  ];

  WordSearchController(List<String> wordList, {this.onPuzzleComplete}) {
    words = wordList.take(8).toList(); // Use up to 8 words
    _generateGrid();
  }

  String get formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get secondsElapsed => _secondsElapsed;

  void _generateGrid() {
    grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => ''),
    );
    wordPositions.clear();
    foundWords.clear();

    // Place words
    final random = Random();
    for (var word in words) {
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        attempts++;

        // Random direction: 0=horizontal, 1=vertical, 2=diagonal down, 3=diagonal up
        final direction = random.nextInt(8);
        final reverse = random.nextBool();

        final wordToPlace = reverse ? word.split('').reversed.join() : word;

        if (_tryPlaceWord(wordToPlace, word, direction, random)) {
          placed = true;
        }
      }
    }

    // Fill empty cells with random letters
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = String.fromCharCode(65 + random.nextInt(26));
        }
      }
    }

    notifyListeners();
  }

  bool _tryPlaceWord(
      String word, String originalWord, int direction, Random random) {
    int startRow = random.nextInt(gridSize);
    int startCol = random.nextInt(gridSize);

    int dRow = 0, dCol = 0;

    switch (direction) {
      case 0:
        dCol = 1;
        break; // Horizontal
      case 1:
        dRow = 1;
        break; // Vertical
      case 2:
        dRow = 1;
        dCol = 1;
        break; // Diagonal down
      case 3:
        dRow = -1;
        dCol = 1;
        break; // Diagonal up
      case 4:
        dRow = 1;
        dCol = -1;
        break; // Diagonal down-left ↙
      case 5:
        dRow = -1;
        dCol = -1;
        break; // Diagonal up-left ↖
      case 6:
        dRow = 0;
        dCol = -1;
        break; // Left (if not using reverse)
      case 7:
        dRow = -1;
        dCol = 0;
        break; // Up (if not using reverse)
    }

    // Check if word fits
    int endRow = startRow + dRow * (word.length - 1);
    int endCol = startCol + dCol * (word.length - 1);

    if (endRow < 0 || endRow >= gridSize || endCol < 0 || endCol >= gridSize) {
      return false;
    }

    // Check if cells are empty or match
    List<Point<int>> positions = [];
    for (int i = 0; i < word.length; i++) {
      int row = startRow + dRow * i;
      int col = startCol + dCol * i;

      if (grid[row][col].isNotEmpty && grid[row][col] != word[i]) {
        return false;
      }
      positions.add(Point(row, col));
    }

    // Place word
    for (int i = 0; i < word.length; i++) {
      grid[positions[i].x][positions[i].y] = word[i];
    }

    wordPositions.add(WordPosition(
      word: word, // The placed word (might be reversed)
      originalWord: originalWord,
      positions: positions,
      color: _highlightColors[wordPositions.length % _highlightColors.length],
    ));

    return true;
  }

  void onDragStart(int row, int col) {
    if (_secondsElapsed == 0) {
      _startTimer();
    }

    isDragging = true;
    _dragStart = Point(row, col);
    _dragEnd = Point(row, col);
    notifyListeners();
  }

  void onDragUpdate(int row, int col) {
    if (!isDragging) return;
    _dragEnd = Point(row, col);
    notifyListeners();
  }

  void onDragEnd() {
    if (!isDragging) return;

    if (_dragStart != null && _dragEnd != null) {
      _checkSelection();
    }

    isDragging = false;
    _dragStart = null;
    _dragEnd = null;
    notifyListeners();
  }

  void _checkSelection() {
    final selected = _getSelectedCells();
    if (selected.length < 2) return;

    final selectedWord = selected.map((p) => grid[p.x][p.y]).join();

    for (var wordPos in wordPositions) {
      if (foundWords.contains(wordPos.originalWord)) continue;

      // Check if selected word matches (forward or backward)
      if (selectedWord == wordPos.word ||
          selectedWord == wordPos.word.split('').reversed.join()) {
        // Also verify positions match
        if (_matchesWord(selected, wordPos.positions)) {
          foundWords.add(wordPos.originalWord);

          // UPDATE THIS: Call _checkCompletion instead of inline logic
          _checkCompletion();

          notifyListeners();
          return;
        }
      }
    }
  }

  void _checkCompletion() {
    if (foundWords.length == words.length) {
      _timer?.cancel();

      // Trigger completion callback after a brief delay
      Future.delayed(const Duration(milliseconds: 500), () {
        onPuzzleComplete?.call();
      });
    }
  }

  bool _matchesWord(List<Point<int>> selected, List<Point<int>> word) {
    if (selected.length != word.length) return false;

    // Check forward
    bool forward = true;
    for (int i = 0; i < selected.length; i++) {
      if (selected[i].x != word[i].x || selected[i].y != word[i].y) {
        forward = false;
        break;
      }
    }

    if (forward) return true;

    // Check backward
    bool backward = true;
    for (int i = 0; i < selected.length; i++) {
      if (selected[i].x != word[word.length - 1 - i].x ||
          selected[i].y != word[word.length - 1 - i].y) {
        backward = false;
        break;
      }
    }

    return backward;
  }

  List<Point<int>> _getSelectedCells() {
    if (_dragStart == null || _dragEnd == null) return [];

    List<Point<int>> cells = [];
    int startRow = _dragStart!.x;
    int startCol = _dragStart!.y;
    int endRow = _dragEnd!.x;
    int endCol = _dragEnd!.y;

    // Single cell selection
    if (startRow == endRow && startCol == endCol) {
      return [Point(startRow, startCol)];
    }

    int dRow = (endRow - startRow).sign;
    int dCol = (endCol - startCol).sign;

    // Only allow straight lines or perfect diagonals
    int rowDiff = (endRow - startRow).abs();
    int colDiff = (endCol - startCol).abs();

    // Must be horizontal, vertical, or diagonal (45 degrees)
    if (rowDiff != 0 && colDiff != 0 && rowDiff != colDiff) {
      return []; // Invalid selection
    }

    int row = startRow;
    int col = startCol;
    int steps = 0;
    int maxSteps = max(rowDiff, colDiff) + 1;

    while (steps < maxSteps) {
      cells.add(Point(row, col));

      if (row == endRow && col == endCol) break;

      row += dRow;
      col += dCol;
      steps++;
    }

    return cells;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void reset() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _generateGrid();
  }

  Color? getCellHighlight(int row, int col) {
    for (var wordPos in wordPositions) {
      // Check if this word's ORIGINAL word is in foundWords
      if (foundWords.contains(wordPos.originalWord)) {
        // Check if this cell is part of this word's positions
        for (var pos in wordPos.positions) {
          if (pos.x == row && pos.y == col) {
            return wordPos.color;
          }
        }
      }
    }

    return null;
  }

  bool isCellSelected(int row, int col) {
    final selected = _getSelectedCells();
    return selected.contains(Point(row, col));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
