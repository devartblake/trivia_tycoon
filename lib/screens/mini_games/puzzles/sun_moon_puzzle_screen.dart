import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../dialogs/game_result_dialog.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum CellState { empty, sun, moon, locked }

class SunMoonPuzzleScreen extends StatefulWidget {
  const SunMoonPuzzleScreen({super.key});

  @override
  State<SunMoonPuzzleScreen> createState() => _SunMoonPuzzleScreenState();
}

class _SunMoonPuzzleScreenState extends State<SunMoonPuzzleScreen> {
  static const int gridSize = 4;
  List<List<CellState>> grid = [];
  List<List<bool>> isLocked = [];
  List<List<List<CellState>>> history = [];

  // Timer variables
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  bool _puzzleCompleted = false;

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
    final random = Random();

    // Generate a valid solution first
    List<List<CellState>> solution = _generateValidSolution(random);

    // Lock some cells as hints (30-40% of cells)
    int cellsToLock = gridSize * gridSize * (30 + random.nextInt(11)) ~/ 100;

    grid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => CellState.empty),
    );

    isLocked = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    // Randomly select cells to lock
    List<Point<int>> positions = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        positions.add(Point(i, j));
      }
    }
    positions.shuffle(random);

    for (int i = 0; i < cellsToLock; i++) {
      final pos = positions[i];
      grid[pos.x][pos.y] = solution[pos.x][pos.y];
      isLocked[pos.x][pos.y] = true;
    }

    _secondsElapsed = 0;
    _puzzleCompleted = false;
    history.clear();
  }

  List<List<CellState>> _generateValidSolution(Random random) {
    List<List<CellState>> solution = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => CellState.empty),
    );

    // Fill each row ensuring no more than 2 consecutive
    for (int row = 0; row < gridSize; row++) {
      List<CellState> rowStates = _generateValidRow(random);
      for (int col = 0; col < gridSize; col++) {
        solution[row][col] = rowStates[col];
      }
    }

    // Balance columns to ensure equal suns and moons
    for (int col = 0; col < gridSize; col++) {
      _balanceColumn(solution, col, random);
    }

    // Final verification and fix any adjacent violations
    _fixAdjacentViolations(solution, random);

    return solution;
  }

  List<CellState> _generateValidRow(Random random) {
    // Generate a row with equal suns and moons, no more than 2 consecutive
    List<CellState> row = [];
    int sunCount = 0;
    int moonCount = 0;
    int targetCount = gridSize ~/ 2;

    while (row.length < gridSize) {
      // Determine what can be placed
      bool canPlaceSun = sunCount < targetCount &&
          !_wouldViolateConsecutive(row, CellState.sun);
      bool canPlaceMoon = moonCount < targetCount &&
          !_wouldViolateConsecutive(row, CellState.moon);

      if (canPlaceSun && canPlaceMoon) {
        // Both options valid, choose randomly
        if (random.nextBool()) {
          row.add(CellState.sun);
          sunCount++;
        } else {
          row.add(CellState.moon);
          moonCount++;
        }
      } else if (canPlaceSun) {
        row.add(CellState.sun);
        sunCount++;
      } else if (canPlaceMoon) {
        row.add(CellState.moon);
        moonCount++;
      } else {
        // Deadlock - restart row generation
        return _generateValidRow(random);
      }
    }

    return row;
  }

  bool _wouldViolateConsecutive(List<CellState> sequence, CellState state) {
    int len = sequence.length;
    if (len < 2) return false;

    // Check if adding this state would create 3 consecutive
    return sequence[len - 1] == state && sequence[len - 2] == state;
  }

  void _balanceColumn(List<List<CellState>> solution, int col, Random random) {
    int sunCount = 0;
    int moonCount = 0;
    List<int> swappableRows = [];

    for (int row = 0; row < gridSize; row++) {
      if (solution[row][col] == CellState.sun) {
        sunCount++;
        swappableRows.add(row);
      } else if (solution[row][col] == CellState.moon) {
        moonCount++;
      }
    }

    // Balance by swapping cells in the same row
    while (sunCount != moonCount && swappableRows.isNotEmpty) {
      int rowToSwap = swappableRows[random.nextInt(swappableRows.length)];

      // Find a position in this row to swap with
      for (int otherCol = 0; otherCol < gridSize; otherCol++) {
        if (otherCol != col &&
            solution[rowToSwap][otherCol] == CellState.moon) {
          // Swap
          solution[rowToSwap][col] = CellState.moon;
          solution[rowToSwap][otherCol] = CellState.sun;
          sunCount--;
          moonCount++;
          swappableRows.remove(rowToSwap);
          break;
        }
      }

      // Prevent infinite loop
      if (sunCount == moonCount) break;
      if (swappableRows.isEmpty) break;
    }
  }

  void _fixAdjacentViolations(List<List<CellState>> solution, Random random) {
    // Check and fix any vertical violations
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize - 2; row++) {
        if (solution[row][col] == solution[row + 1][col] &&
            solution[row][col] == solution[row + 2][col]) {
          // Found 3 consecutive - swap middle one with a different cell
          CellState problematic = solution[row + 1][col];
          CellState needed =
              problematic == CellState.sun ? CellState.moon : CellState.sun;

          // Find a cell in same column with needed state and swap
          for (int otherRow = 0; otherRow < gridSize; otherRow++) {
            if (otherRow < row || otherRow > row + 2) {
              if (solution[otherRow][col] == needed) {
                solution[row + 1][col] = needed;
                solution[otherRow][col] = problematic;
                break;
              }
            }
          }
        }
      }
    }
  }

  void toggleCell(int row, int col) {
    if (isLocked[row][col] || _puzzleCompleted) return;

    // Start timer on first move
    if (!_isTimerRunning && _secondsElapsed == 0) {
      _startTimer();
    }

    setState(() {
      // Save current state to history
      history.add(grid.map((r) => List<CellState>.from(r)).toList());

      // Cycle through states: empty -> sun -> moon -> empty
      switch (grid[row][col]) {
        case CellState.empty:
          grid[row][col] = CellState.sun;
          break;
        case CellState.sun:
          grid[row][col] = CellState.moon;
          break;
        case CellState.moon:
          grid[row][col] = CellState.empty;
          break;
        case CellState.locked:
          break;
      }
    });
  }

  void undo() {
    if (history.isNotEmpty && !_puzzleCompleted) {
      setState(() {
        grid = history.removeLast();
      });
    }
  }

  void _showResultDialog() {
    final time = _formatTime(_secondsElapsed);

    String achievementTitle = 'Puzzle Solved!';
    String achievementSubtitle = 'Perfect balance achieved';

    if (_secondsElapsed < 60) {
      achievementTitle = 'Lightning Fast!';
      achievementSubtitle = 'Solved in under a minute';
    } else if (_secondsElapsed < 120) {
      achievementTitle = 'Quick Thinker!';
      achievementSubtitle = 'Excellent puzzle-solving speed';
    } else if (_secondsElapsed < 180) {
      achievementTitle = 'Logical Mind!';
      achievementSubtitle = 'Great problem-solving skills';
    } else if (_secondsElapsed < 300) {
      achievementTitle = 'Puzzle Master!';
      achievementSubtitle = 'You solved the puzzle';
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Sun & Moon Puzzle',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.wb_sunny,
      ),
      onShare: () {
        LogManager.debug('Share tapped');
      },
      onClose: () {
        LogManager.debug('Close tapped');
      },
      onPlayAgain: () {
        resetPuzzle();
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
                'Fill the grid so that each cell contains either a ☀️ or a 🌙.'),
            _buildRule(
                'No more than 2 ☀️ or 🌙 may be next to each other, either vertically or horizontally.'),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              child: Row(
                children: [
                  const Text('☀️ ☀️ ', style: TextStyle(fontSize: 16)),
                  Icon(Icons.check, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 16),
                  const Text('☀️ ☀️ ☀️ ', style: TextStyle(fontSize: 16)),
                  Icon(Icons.close, color: Colors.red.shade600, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildRule(
                'Each row (and column) must contain the same number of ☀️ and 🌙.'),
            _buildRule(
                'Cells with purple borders are locked hints to help you solve the puzzle.'),
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

  bool checkSolution() {
    // Check if grid is complete
    for (var row in grid) {
      for (var cell in row) {
        if (cell == CellState.empty) return false;
      }
    }

    // Check rows and columns for equal suns and moons
    for (int i = 0; i < gridSize; i++) {
      int rowSuns = 0, rowMoons = 0;
      int colSuns = 0, colMoons = 0;

      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == CellState.sun) rowSuns++;
        if (grid[i][j] == CellState.moon) rowMoons++;
        if (grid[j][i] == CellState.sun) colSuns++;
        if (grid[j][i] == CellState.moon) colMoons++;
      }

      if (rowSuns != rowMoons || colSuns != colMoons) return false;
    }

    // Check for no more than 2 adjacent
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize - 2; j++) {
        // Check horizontal
        if (grid[i][j] == grid[i][j + 1] &&
            grid[i][j] == grid[i][j + 2] &&
            grid[i][j] != CellState.empty) {
          return false;
        }
        // Check vertical
        if (grid[j][i] == grid[j + 1][i] &&
            grid[j][i] == grid[j + 2][i] &&
            grid[j][i] != CellState.empty) {
          return false;
        }
      }
    }

    return true;
  }

  void resetPuzzle() {
    setState(() {
      _stopTimer();
      _generatePuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sun & Moon Puzzle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
            onPressed: resetPuzzle,
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // How to Play Button
                    GestureDetector(
                      onTap: _showHowToPlay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.3),
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

                    // Grid - Increased height
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                        maxHeight: 500,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            int row = index ~/ gridSize;
                            int col = index % gridSize;
                            bool isLightCell = (row + col) % 2 == 0;
                            bool locked = isLocked[row][col];

                            return GestureDetector(
                              onTap: () => toggleCell(row, col),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLightCell
                                      ? const Color(0xFFF5F1ED)
                                      : Colors.white,
                                  border: Border.all(
                                    color: locked
                                        ? const Color(0xFF6366F1)
                                            .withValues(alpha: 0.5)
                                        : Colors.grey.shade300,
                                    width: locked ? 2 : 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: _buildCellContent(grid[row][col]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton(
                          'Undo',
                          Icons.undo,
                          onPressed: history.isNotEmpty && !_puzzleCompleted
                              ? undo
                              : null,
                        ),
                        const SizedBox(width: 16),
                        _buildButton(
                          'Hint',
                          Icons.lightbulb_outline,
                          onPressed: _showHowToPlay,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Check solution button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _puzzleCompleted
                            ? null
                            : () {
                                if (checkSolution()) {
                                  _stopTimer();
                                  setState(() {
                                    _puzzleCompleted = true;
                                  });

                                  // Show result dialog
                                  _showResultDialog();
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Row(
                                        children: const [
                                          Icon(Icons.info_outline,
                                              color: Color(0xFFF59E0B)),
                                          SizedBox(width: 8),
                                          Text('Not quite right'),
                                        ],
                                      ),
                                      content: const Text(
                                        'The solution is incorrect or incomplete. Keep trying!',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _puzzleCompleted
                              ? Colors.grey.shade300
                              : const Color(0xFF6366F1),
                          foregroundColor: _puzzleCompleted
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _puzzleCompleted
                              ? 'Puzzle Completed!'
                              : 'Check Solution',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(CellState state) {
    switch (state) {
      case CellState.sun:
      case CellState.locked:
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD68910), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      case CellState.moon:
        return CustomPaint(
          size: const Size(50, 50),
          painter: MoonPainter(),
        );
      case CellState.empty:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButton(String text, IconData icon, {VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled
            ? const Color(0xFFE0DDD9)
            : const Color(0xFFE0DDD9).withValues(alpha: 0.5),
        foregroundColor: isEnabled
            ? const Color(0xFF4A4A4A)
            : const Color(0xFF4A4A4A).withValues(alpha: 0.5),
        elevation: isEnabled ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2E5C8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw moon crescent with shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF4A90E2).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(Rect.fromCircle(
      center: Offset(center.dx + radius * 0.3, center.dy),
      radius: radius * 0.8,
    ));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
