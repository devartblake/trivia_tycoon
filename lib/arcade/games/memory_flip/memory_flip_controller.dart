import 'dart:async';
import 'dart:math';

import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_id.dart';
import '../../domain/arcade_result.dart';
import 'memory_flip_models.dart';

class MemoryFlipState {
  final List<MemoryCard> cards;

  final int score;
  final int matches; // number of pairs matched
  final int moves; // number of pair-attempts (two flips)
  final int misses; // non-matching attempts

  final Duration remaining;
  final bool isOver;

  /// Temporarily lock flips while resolving a mismatch animation.
  final bool inputLocked;

  const MemoryFlipState({
    required this.cards,
    required this.score,
    required this.matches,
    required this.moves,
    required this.misses,
    required this.remaining,
    required this.isOver,
    required this.inputLocked,
  });

  int get totalPairs => cards.length ~/ 2;

  bool get allMatched => matches >= totalPairs;

  MemoryFlipState copyWith({
    List<MemoryCard>? cards,
    int? score,
    int? matches,
    int? moves,
    int? misses,
    Duration? remaining,
    bool? isOver,
    bool? inputLocked,
  }) {
    return MemoryFlipState(
      cards: cards ?? this.cards,
      score: score ?? this.score,
      matches: matches ?? this.matches,
      moves: moves ?? this.moves,
      misses: misses ?? this.misses,
      remaining: remaining ?? this.remaining,
      isOver: isOver ?? this.isOver,
      inputLocked: inputLocked ?? this.inputLocked,
    );
  }
}

class MemoryFlipController {
  final ArcadeDifficulty difficulty;
  final MemoryFlipConfig config;
  final Random _rng;

  MemoryFlipState _state;
  MemoryFlipState get state => _state;

  Timer? _timer;

  int? _firstIndex; // index of first flipped card in a move

  MemoryFlipController({
    required this.difficulty,
    Random? rng,
  })  : _rng = rng ?? Random(),
        config = MemoryFlipConfig.fromDifficulty(difficulty),
        _state = MemoryFlipState(
          cards: const [],
          score: 0,
          matches: 0,
          moves: 0,
          misses: 0,
          remaining: MemoryFlipConfig.fromDifficulty(difficulty).timeLimit,
          isOver: false,
          inputLocked: false,
        ) {
    _state = _state.copyWith(cards: _buildDeck());
  }

  void start(void Function(MemoryFlipState) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isOver) return;

      final next = _state.remaining - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        _state = _state.copyWith(remaining: Duration.zero, isOver: true);
        onTick(_state);
        _timer?.cancel();
        return;
      }

      _state = _state.copyWith(remaining: next);
      onTick(_state);
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  List<MemoryCard> _buildDeck() {
    final total = config.gridSize;
    final pairs = total ~/ 2;

    final ids = List<int>.generate(pairs, (i) => i);
    final deckIds = <int>[...ids, ...ids]..shuffle(_rng);

    return List<MemoryCard>.generate(total, (i) {
      return MemoryCard(
        id: deckIds[i],
        index: i,
        isMatched: false,
        isFaceUp: false,
      );
    });
  }

  /// Attempt to flip a card at [index]. Returns:
  /// - 'ignored' if flip not allowed
  /// - 'first' when first card of a move is flipped
  /// - 'match' when second flip matches first
  /// - 'miss' when second flip mismatches first
  Future<String> flip(
      int index, void Function(MemoryFlipState) onUpdate) async {
    if (_state.isOver) return 'ignored';
    if (_state.inputLocked) return 'ignored';

    final card = _state.cards[index];
    if (card.isMatched || card.isFaceUp) return 'ignored';

    // Reveal the card
    _state = _state.copyWith(cards: _setFaceUp(index, true));
    onUpdate(_state);

    if (_firstIndex == null) {
      _firstIndex = index;
      return 'first';
    }

    // Second flip
    final first = _state.cards[_firstIndex!];
    final second = _state.cards[index];

    _state = _state.copyWith(moves: _state.moves + 1);

    if (first.id == second.id) {
      // Match!
      final gained = _matchPoints();
      _state = _state.copyWith(
        score: _state.score + gained,
        matches: _state.matches + 1,
        cards: _markMatched(_firstIndex!, index),
      );
      _firstIndex = null;

      if (_state.allMatched) {
        _state = _state.copyWith(isOver: true);
        _timer?.cancel();
      }

      onUpdate(_state);
      return 'match';
    } else {
      // Miss: briefly show both, then flip down.
      _state = _state.copyWith(
        misses: _state.misses + 1,
        score: max(0, _state.score - config.missPenalty),
        inputLocked: true,
      );
      onUpdate(_state);

      await Future<void>.delayed(const Duration(milliseconds: 520));

      // Flip both down if still not over
      if (!_state.isOver) {
        _state = _state.copyWith(
          cards:
              _setFaceUp(_firstIndex!, false, base: _setFaceUp(index, false)),
          inputLocked: false,
        );
        onUpdate(_state);
      }

      _firstIndex = null;
      return 'miss';
    }
  }

  int _matchPoints() {
    final totalSeconds = config.timeLimit.inSeconds.clamp(1, 9999);
    final rem = _state.remaining.inSeconds.clamp(0, totalSeconds);

    // Faster finishes yield higher points; early-game match reward higher
    final timeFactor = (0.6 + 0.6 * (rem / totalSeconds)).clamp(0.6, 1.2);

    // Efficiency bonus: fewer misses => more points
    final efficiency = (_state.misses == 0)
        ? 1.15
        : (1.0 - (_state.misses * 0.03)).clamp(0.75, 1.1);

    // Difficulty multiplier already encoded via baseMatchPoints & penalties; keep small multiplier anyway
    final diff = difficulty.rewardMultiplier.clamp(1.0, 2.0);

    return (config.baseMatchPoints *
            timeFactor *
            efficiency *
            (0.85 + (0.15 * diff)))
        .round()
        .clamp(30, 600);
  }

  List<MemoryCard> _setFaceUp(int index, bool isUp, {List<MemoryCard>? base}) {
    final cards = (base ?? _state.cards).toList();
    cards[index] = cards[index].copyWith(isFaceUp: isUp);
    return cards;
  }

  List<MemoryCard> _markMatched(int a, int b) {
    final cards = _state.cards.toList();
    cards[a] = cards[a].copyWith(isMatched: true, isFaceUp: true);
    cards[b] = cards[b].copyWith(isMatched: true, isFaceUp: true);
    return cards;
  }

  ArcadeResult toResult() {
    final totalPairs = _state.totalPairs.clamp(1, 999);
    final completion = (_state.matches / totalPairs).clamp(0.0, 1.0);

    // Accuracy-like metric (how “clean”)
    final attempts = _state.moves.clamp(1, 9999);
    final hitRate = (_state.matches / attempts).clamp(0.0, 1.0);

    return ArcadeResult(
      gameId: ArcadeGameId.memoryFlip,
      difficulty: difficulty,
      score: _state.score,
      duration: Duration.zero, // shell sets canonical duration
      metadata: {
        'pairsMatched': _state.matches,
        'totalPairs': totalPairs,
        'moves': _state.moves,
        'misses': _state.misses,
        'completion': completion,
        'hitRate': hitRate,
      },
    );
  }
}
