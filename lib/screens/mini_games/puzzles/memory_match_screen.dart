import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:trivia_tycoon/ui_components/flip_card/flip_card.dart';
import 'package:trivia_tycoon/ui_components/flip_card/controller/flip_card_controller.dart';

import '../dialogs/game_result_dialog.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      onGameComplete: () {
        Future.delayed(const
        Duration(milliseconds: 500), () {
          _showResultDialog();
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              'Tap a card to flip it and reveal the symbol.',
              'Tap a second card to try to find a matching pair.',
              'If the cards match, they stay face up.',
              'If they don\'t match, they flip back over.',
              'Remember the positions and find all pairs!',
              'Complete the game in as few moves as possible.',
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

  void _showResultDialog() {
    final time = _controller.formattedTime;
    final movesCount = _controller.moves;

    String achievementTitle = 'Memory Master!';
    String achievementSubtitle = 'You matched all pairs perfectly!';

    if (movesCount <= _controller.totalPairs + 2) {
      achievementTitle = 'Perfect Memory!';
      achievementSubtitle = 'Completed with minimal moves';
    } else if (movesCount <= _controller.totalPairs * 2) {
      achievementTitle = 'Sharp Mind!';
      achievementSubtitle = 'Great memory performance';
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Memory Match',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.psychology,
      ),
      onShare: () {
        debugPrint('Share tapped');
      },
      onClose: () {
        debugPrint('Close tapped');
      },
      onPlayAgain: () {
        _controller.reset();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Memory Match',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
            icon: const Icon(Icons.refresh),
            onPressed: _controller.reset,
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
                  listenable: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard('Moves', _controller.moves, Icons.touch_app, const Color(0xFF6366F1)),
                        const SizedBox(width: 16),
                        _buildStatCard('Pairs', '${_controller.matchedPairs}/${_controller.totalPairs}', Icons.check_circle, const Color(0xFF10B981)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                MemoryGrid(controller: _controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GameController extends ChangeNotifier {
  final VoidCallback? onGameComplete;

  List<MemoryCard> cards = [];
  int moves = 0;
  int matchedPairs = 0;
  int totalPairs = 8;
  Timer? _timer;
  int _secondsElapsed = 0;
  MemoryCard? _firstFlipped;
  MemoryCard? _secondFlipped;
  bool _isChecking = false;

  final List<IconData> _icons = [
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.rocket_launch,
    Icons.emoji_emotions,
    Icons.cake,
  ];

  final List<Color> _colors = [
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
    const Color(0xFFFBBF24),
  ];

  GameController({this.onGameComplete})
  {
    _initGame();
  }

  String get formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _initGame() {
    cards.clear();
    moves = 0;
    matchedPairs = 0;
    _secondsElapsed = 0;
    _firstFlipped = null;
    _secondFlipped = null;
    _isChecking = false;

    // Create pairs
    final List<MemoryCard> tempCards = [];
    for (int i = 0; i < totalPairs; i++) {
      final id = i;
      tempCards.add(MemoryCard(
        id: '$id-a',
        pairId: id,
        icon: _icons[i],
        color: _colors[i],
        controller: FlipCardController(),
      ));
      tempCards.add(MemoryCard(
        id: '$id-b',
        pairId: id,
        icon: _icons[i],
        color: _colors[i],
        controller: FlipCardController(),
      ));
    }

    // Shuffle
    tempCards.shuffle(Random());
    cards = tempCards;
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

  Future<void> onCardTapped(MemoryCard card) async {
    if (_isChecking || card.isMatched || card == _firstFlipped) return;

    if (_secondsElapsed == 0) {
      _startTimer();
    }

    await card.controller.flip(CardSide.back);

    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else if (_secondFlipped == null) {
      _secondFlipped = card;
      moves++;
      notifyListeners();

      _isChecking = true;
      await _checkMatch();
      _isChecking = false;
    }
  }

  Future<void> _checkMatch() async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_firstFlipped!.pairId == _secondFlipped!.pairId) {
      // Match found
      _firstFlipped!.isMatched = true;
      _secondFlipped!.isMatched = true;
      matchedPairs++;

      if (matchedPairs == totalPairs) {
        _timer?.cancel();
        notifyListeners();
        // Trigger completion callback
        onGameComplete?.call();
      }
    } else {
      // No match - flip back
      await Future.wait([
        _firstFlipped!.controller.flip(CardSide.front),
        _secondFlipped!.controller.flip(CardSide.front),
      ]);
    }

    _firstFlipped = null;
    _secondFlipped = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class MemoryGrid extends StatelessWidget {
  final GameController controller;

  const MemoryGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: controller.cards.length,
            itemBuilder: (context, index) {
              final card = controller.cards[index];
              return MemoryCardWidget(
                key: ValueKey(card.id),
                card: card,
                onTap: () => controller.onCardTapped(card),
              );
            },
          ),
        );
      },
    );
  }
}

class MemoryCardWidget extends StatelessWidget {
  final MemoryCard card;
  final VoidCallback onTap;

  const MemoryCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      controller: card.controller,
      flipOnTouch: false,
      direction: Axis.vertical,
      initialSide: CardSide.front,
      front: GestureDetector(
        onTap: card.isMatched ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.help_outline,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
      back: Container(
        decoration: BoxDecoration(
          color: card.isMatched ? Colors.white : card.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isMatched ? card.color : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: card.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            card.icon,
            size: 48,
            color: card.isMatched ? card.color : Colors.white,
          ),
        ),
      ),
    );
  }
}

class MemoryCard {
  final String id;
  final int pairId;
  final IconData icon;
  final Color color;
  final FlipCardController controller;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.pairId,
    required this.icon,
    required this.color,
    required this.controller,
    this.isMatched = false,
  });
}
