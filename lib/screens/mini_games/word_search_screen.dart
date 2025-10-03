import 'dart:async';
import 'package:flutter/material.dart';
import '../../game/data/word_search_loader.dart';
import '../../game/controllers/word_search_controller.dart';
import 'package:trivia_tycoon/screens/mini_games/widgets/word_list_widget.dart';
import 'package:trivia_tycoon/screens/mini_games/widgets/word_search_grid_widget.dart';

import 'dialogs/game_result_dialog.dart';
import 'dialogs/word_search_settings_dialog.dart';

class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late WordSearchController _controller;
  bool _isLoading = true;
  String? _error;
  WordSearchDifficulty _difficulty = WordSearchDifficulty.easy;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Determine which file to load based on the selected difficulty
      final difficultyStr = _difficulty.toString().split('.').last;
      final assetPath = 'assets/data/mini-games/word_search_$difficultyStr.json';

      final words = await WordSearchDataLoader.loadWords(
        assetPath,
        difficulty: difficultyStr,
      );

      _controller = WordSearchController(
        words,
        onPuzzleComplete: () {
          if (mounted) {
            _showResultDialog();
          }
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not load words for this difficulty.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Check if controller has been initialized before disposing
    if (!_isLoading && _error == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showSettingsDialog() async {
    final newDifficulty = await showDialog<WordSearchDifficulty>(
      context: context,
      builder: (context) => WordSearchSettingsDialog(initialDifficulty: _difficulty),
    );

    if (newDifficulty != null && newDifficulty != _difficulty) {
      setState(() {
        _difficulty = newDifficulty;
      });
      // Start a new game with the new difficulty
      _initGame();
    }
  }

  void _showResultDialog() {
    final time = _controller.formattedTime;
    final difficultyName = _difficulty.toString().split('.').last;
    final seconds = _controller.secondsElapsed;

    String achievementTitle = 'Word Master!';
    String achievementSubtitle = 'All words found successfully';

    if (difficultyName == 'easy') {
      if (seconds < 120) {
        achievementTitle = 'Speed Reader!';
        achievementSubtitle = 'Easy puzzle completed quickly';
      } else {
        achievementTitle = 'Word Finder!';
        achievementSubtitle = 'Easy puzzle completed';
      }
    } else if (difficultyName == 'medium') {
      if (seconds < 240) {
        achievementTitle = 'Sharp Eye!';
        achievementSubtitle = 'Medium puzzle solved efficiently';
      } else {
        achievementTitle = 'Word Detective!';
        achievementSubtitle = 'Medium puzzle mastered';
      }
    } else if (difficultyName == 'hard') {
      if (seconds < 360) {
        achievementTitle = 'Word Wizard!';
        achievementSubtitle = 'Hard puzzle conquered quickly';
      } else {
        achievementTitle = 'Word Champion!';
        achievementSubtitle = 'Hard puzzle conquered';
      }
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Word Search - ${difficultyName[0].toUpperCase()}${difficultyName.substring(1)}',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.search,
      ),
      onShare: () {
        debugPrint('Share tapped');
      },
      onClose: () {
        debugPrint('Close tapped');
      },
      onPlayAgain: () {
        _initGame();
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
              'Find all the hidden words in the grid.',
              'Words can be horizontal, vertical, or diagonal.',
              'Words can be forwards or backwards.',
              'Drag from the first letter to the last letter to select a word.',
              'Found words will be highlighted in different colors.',
              'Find all words to complete the puzzle!',
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
          'Word Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _error == null)
            ListenableBuilder(
              listenable: _controller,
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
                          _controller.formattedTime,
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
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
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading game: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initGame,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
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
                WordSearchGrid(controller: _controller),
                const SizedBox(height: 20),
                WordList(controller: _controller),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
