import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'dialogs/game_result_dialog.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late GameController _gameController;

  @override
  void initState() {
    super.initState();
    _gameController = GameController(
      onWin: () {
        if (mounted) {
          _showResultDialog();
          _gameController.markWinDialogShown();
        }
      },
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  void _showResultDialog() {
    final time = _gameController.formattedTime;
    final score = _gameController.score;

    String achievementTitle = '2048 Achieved!';
    String achievementSubtitle = 'You reached the legendary tile';

    if (score >= 50000) {
      achievementTitle = '2048 Legend!';
      achievementSubtitle = 'Extraordinary score achieved';
    } else if (score >= 20000) {
      achievementTitle = '2048 Master!';
      achievementSubtitle = 'Exceptional performance';
    } else if (score >= 10000) {
      achievementTitle = '2048 Champion!';
      achievementSubtitle = 'Great strategic thinking';
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: '2048 Game',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: '$score',
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.apps,
      ),
      onShare: () {
        debugPrint('Share tapped');
      },
      onClose: () {
        debugPrint('Close tapped');
      },
      onPlayAgain: () {
        _gameController.reset();
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
            ...[
              'Swipe in any direction to move all tiles.',
              'When two tiles with the same number touch, they merge into one!',
              'The merged tile shows the sum of the two tiles (2+2=4, 4+4=8, etc.).',
              'Your goal is to reach the 2048 tile!',
              'Keep playing after reaching 2048 to achieve higher scores.',
              'The game ends when no more moves are possible.',
            ].map((text) => Padding(
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
            )),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '2048',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ListenableBuilder(
            listenable: _gameController,
            builder: (context, _) {
              return Center(
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
                        _gameController.formattedTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _gameController.reset,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFF), Color(0xFFFFFFFF)],
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
                            children: const [
                              Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1), size: 20),
                              SizedBox(width: 8),
                              Text(
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
                      ListenableBuilder(
                        listenable: _gameController,
                        builder: (context, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildScoreCard('Score', _gameController.score, const Color(0xFF6366F1)),
                              const SizedBox(width: 16),
                              _buildScoreCard('Best', _gameController.bestScore, const Color(0xFFFFD700)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      GameBoard(controller: _gameController),
                      const SizedBox(height: 20),
                      ListenableBuilder(
                        listenable: _gameController,
                        builder: (context, _) {
                          return ElevatedButton.icon(
                            onPressed: _gameController.canUndo ? _gameController.undo : null,
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Undo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0DDD9),
                              foregroundColor: const Color(0xFF4A4A4A),
                              disabledBackgroundColor: const Color(0xFFE0DDD9).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class GameController extends ChangeNotifier {
  static const int gridSize = 4;
  final VoidCallback? onWin;

  List<Tile> tiles = [];
  int score = 0;
  int bestScore = 0;
  Timer? _timer;
  int _secondsElapsed = 0;
  List<GameSnapshot> _history = [];
  bool _won = false;
  bool _wonDialogShown = false;
  bool _gameOver = false;

  GameController({this.onWin}) {
    _initGame();
  }

  bool get canUndo => _history.isNotEmpty && !_gameOver && !_won;

  String get formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _initGame() {
    tiles.clear();
    score = 0;
    _secondsElapsed = 0;
    _history.clear();
    _won = false;
    _gameOver = false;
    _addRandomTile();
    _addRandomTile();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _initGame();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void _addRandomTile() {
    final available = <Point<int>>[];
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (!tiles.any((t) => t.x == x && t.y == y)) {
          available.add(Point(x, y));
        }
      }
    }

    if (available.isEmpty) return;

    final random = Random();
    final pos = available[random.nextInt(available.length)];
    final value = random.nextInt(10) < 9 ? 2 : 4;

    tiles.add(Tile(
      id: '${pos.x}-${pos.y}-${DateTime.now().millisecondsSinceEpoch}',
      value: value,
      x: pos.x,
      y: pos.y,
    ));
  }

  void move(SwipeDirection direction) {
    if (_gameOver || _won) return;

    // Allow continuing after win
    if (_won && _wonDialogShown) {
      // Player can continue playing after seeing win dialog
    } else if (_won) {
      return; // Wait for dialog to be shown
    }

    if (_secondsElapsed == 0) {
      _startTimer();
    }

    _saveSnapshot();

    bool moved = false;
    tiles.sort((a, b) => _getSortOrder(a, b, direction));

    final merged = <String>{};

    for (var tile in tiles) {
      var target = _getTargetPosition(tile, direction, merged);
      if (target.x != tile.x || target.y != tile.y) {
        moved = true;
        tile.x = target.x;
        tile.y = target.y;
      }

      final mergeTarget = tiles.firstWhere(
            (t) => t.x == target.x && t.y == target.y && t != tile && !merged.contains(t.id),
        orElse: () => tile,
      );

      if (mergeTarget != tile && mergeTarget.value == tile.value) {
        moved = true;
        mergeTarget.value *= 2;
        mergeTarget.merged = true;
        merged.add(mergeTarget.id);
        score += mergeTarget.value;
        tile.removed = true;

        if (mergeTarget.value == 2048 && !_won) {
          _won = true;
          // Trigger win callback after a brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            onWin?.call();
          });
        }
      }
    }

    if (moved) {
      tiles.removeWhere((t) => t.removed);
      Future.delayed(const Duration(milliseconds: 150), () {
        for (var tile in tiles) {
          tile.merged = false;
        }
        _addRandomTile();
        if (!_won) {
          _checkGameOver();
        }
        if (score > bestScore) {
          bestScore = score;
        }
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void markWinDialogShown() {
    _wonDialogShown = true;
    notifyListeners();
  }

  int _getSortOrder(Tile a, Tile b, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return a.x.compareTo(b.x);
      case SwipeDirection.right:
        return b.x.compareTo(a.x);
      case SwipeDirection.up:
        return a.y.compareTo(b.y);
      case SwipeDirection.down:
        return b.y.compareTo(a.y);
    }
  }

  Point<int> _getTargetPosition(Tile tile, SwipeDirection direction, Set<String> merged) {
    int x = tile.x;
    int y = tile.y;

    while (true) {
      int nextX = x;
      int nextY = y;

      switch (direction) {
        case SwipeDirection.left:
          nextX--;
          break;
        case SwipeDirection.right:
          nextX++;
          break;
        case SwipeDirection.up:
          nextY--;
          break;
        case SwipeDirection.down:
          nextY++;
          break;
      }

      if (nextX < 0 || nextX >= gridSize || nextY < 0 || nextY >= gridSize) {
        break;
      }

      final blocked = tiles.any((t) =>
      t.x == nextX && t.y == nextY && t != tile && !t.removed
      );

      if (blocked) {
        final blocker = tiles.firstWhere((t) => t.x == nextX && t.y == nextY && t != tile);
        if (blocker.value == tile.value && !merged.contains(blocker.id)) {
          return Point(nextX, nextY);
        }
        break;
      }

      x = nextX;
      y = nextY;
    }

    return Point(x, y);
  }

  void _checkGameOver() {
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (!tiles.any((t) => t.x == x && t.y == y)) {
          return;
        }
      }
    }

    for (var tile in tiles) {
      for (var other in tiles) {
        if (tile == other) continue;
        if ((tile.x == other.x && (tile.y - other.y).abs() == 1) ||
            (tile.y == other.y && (tile.x - other.x).abs() == 1)) {
          if (tile.value == other.value) {
            return;
          }
        }
      }
    }

    _gameOver = true;
    _timer?.cancel();
  }

  void _saveSnapshot() {
    _history.add(GameSnapshot(
      tiles: tiles.map((t) => Tile(
        id: t.id,
        value: t.value,
        x: t.x,
        y: t.y,
      )).toList(),
      score: score,
    ));
  }

  void undo() {
    if (_history.isEmpty) return;

    final snapshot = _history.removeLast();
    tiles = snapshot.tiles;
    score = snapshot.score;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class GameBoard extends StatelessWidget {
  final GameController controller;

  const GameBoard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dx.abs() > velocity.dy.abs()) {
          controller.move(velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
        } else {
          controller.move(velocity.dy > 0 ? SwipeDirection.down : SwipeDirection.up);
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = (constraints.maxWidth - 32) / 4;

                return Stack(
                  children: [
                    // Background grid
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFCDC1B4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                    // Animated tiles
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) {
                        return Stack(
                          children: controller.tiles.map((tile) {
                            return AnimatedPositioned(
                              key: ValueKey(tile.id),
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeInOut,
                              left: tile.x * (tileSize + 8),
                              top: tile.y * (tileSize + 8),
                              width: tileSize,
                              height: tileSize,
                              child: RepaintBoundary(
                                child: TileWidget(
                                  tile: tile,
                                  size: tileSize,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  Color _getTileColor(int value) {
    switch (value) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFF3C3A32);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: tile.merged ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: _getTileColor(tile.value),
          borderRadius: BorderRadius.circular(8),
          boxShadow: tile.merged ? [
            BoxShadow(
              color: _getTileColor(tile.value).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            '${tile.value}',
            style: TextStyle(
              fontSize: tile.value < 100 ? 32 : tile.value < 1000 ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: _getTextColor(tile.value),
            ),
          ),
        ),
      ),
    );
  }
}

class Tile {
  final String id;
  int value;
  int x;
  int y;
  bool merged;
  bool removed;

  Tile({
    required this.id,
    required this.value,
    required this.x,
    required this.y,
    this.merged = false,
    this.removed = false,
  });
}

class GameSnapshot {
  final List<Tile> tiles;
  final int score;

  GameSnapshot({required this.tiles, required this.score});
}

enum SwipeDirection { up, down, left, right }