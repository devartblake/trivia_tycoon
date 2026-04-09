import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/games/memory_flip/memory_flip_controller.dart';
import 'package:trivia_tycoon/arcade/games/memory_flip/memory_flip_models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MemoryFlipController _ctrl({
  ArcadeDifficulty difficulty = ArcadeDifficulty.easy,
  int seed = 42,
}) =>
    MemoryFlipController(difficulty: difficulty, rng: Random(seed));

/// Returns indices [a, b] of two cards that form a matching pair.
List<int> findMatchingPair(List<MemoryCard> cards) {
  final seen = <int, int>{}; // id -> index
  for (final card in cards) {
    if (seen.containsKey(card.id)) {
      return [seen[card.id]!, card.index];
    }
    seen[card.id] = card.index;
  }
  throw StateError('No matching pair found');
}

/// Returns indices [a, b] of two cards that do NOT share a pair id.
List<int> findNonMatchingPair(List<MemoryCard> cards) {
  final firstId = cards[0].id;
  final first = cards[0].index;
  for (final card in cards) {
    if (card.id != firstId) {
      return [first, card.index];
    }
  }
  throw StateError('All cards have the same id');
}

/// Match every pair in the deck (completes the game).
Future<void> matchAll(MemoryFlipController c) async {
  final byId = <int, List<int>>{};
  for (final card in c.state.cards) {
    byId.putIfAbsent(card.id, () => []).add(card.index);
  }
  for (final pair in byId.values) {
    await c.flip(pair[0], (_) {});
    await c.flip(pair[1], (_) {});
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('MemoryFlipController initial state', () {
    test('easy difficulty: 12 cards', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.easy);
      expect(c.state.cards.length, 12);
      c.dispose();
    });

    test('normal difficulty: 16 cards', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.normal);
      expect(c.state.cards.length, 16);
      c.dispose();
    });

    test('hard difficulty: 20 cards', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.hard);
      expect(c.state.cards.length, 20);
      c.dispose();
    });

    test('insane difficulty: 24 cards', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.insane);
      expect(c.state.cards.length, 24);
      c.dispose();
    });

    test('score starts at 0', () {
      final c = _ctrl();
      expect(c.state.score, 0);
      c.dispose();
    });

    test('matches, moves, misses start at 0', () {
      final c = _ctrl();
      expect(c.state.matches, 0);
      expect(c.state.moves, 0);
      expect(c.state.misses, 0);
      c.dispose();
    });

    test('isOver starts as false', () {
      final c = _ctrl();
      expect(c.state.isOver, isFalse);
      c.dispose();
    });

    test('inputLocked starts as false', () {
      final c = _ctrl();
      expect(c.state.inputLocked, isFalse);
      c.dispose();
    });

    test('all cards start face-down and unmatched', () {
      final c = _ctrl();
      expect(c.state.cards.every((card) => !card.isFaceUp && !card.isMatched), isTrue);
      c.dispose();
    });

    test('deck has N/2 unique pair ids (easy → 6)', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.easy);
      final uniqueIds = c.state.cards.map((card) => card.id).toSet();
      expect(uniqueIds.length, 6);
      c.dispose();
    });

    test('each pair id appears exactly twice', () {
      final c = _ctrl();
      final counts = <int, int>{};
      for (final card in c.state.cards) {
        counts[card.id] = (counts[card.id] ?? 0) + 1;
      }
      expect(counts.values.every((n) => n == 2), isTrue);
      c.dispose();
    });

    test('card.index matches position in list', () {
      final c = _ctrl();
      for (int i = 0; i < c.state.cards.length; i++) {
        expect(c.state.cards[i].index, i);
      }
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // flip — first card of a move
  // -------------------------------------------------------------------------

  group('MemoryFlipController.flip — first card', () {
    test('returns "first"', () async {
      final c = _ctrl();
      expect(await c.flip(0, (_) {}), 'first');
      c.dispose();
    });

    test('the flipped card is face-up', () async {
      final c = _ctrl();
      await c.flip(0, (_) {});
      expect(c.state.cards[0].isFaceUp, isTrue);
      c.dispose();
    });

    test('moves count is still 0 after first flip', () async {
      final c = _ctrl();
      await c.flip(0, (_) {});
      expect(c.state.moves, 0);
      c.dispose();
    });

    test('inputLocked remains false after first flip', () async {
      final c = _ctrl();
      await c.flip(0, (_) {});
      expect(c.state.inputLocked, isFalse);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // flip — matching pair
  // -------------------------------------------------------------------------

  group('MemoryFlipController.flip — matching pair', () {
    test('returns "match"', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      expect(await c.flip(pair[1], (_) {}), 'match');
      c.dispose();
    });

    test('both cards are marked as matched', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.cards[pair[0]].isMatched, isTrue);
      expect(c.state.cards[pair[1]].isMatched, isTrue);
      c.dispose();
    });

    test('matched cards remain face-up', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.cards[pair[0]].isFaceUp, isTrue);
      expect(c.state.cards[pair[1]].isFaceUp, isTrue);
      c.dispose();
    });

    test('matches increments to 1', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.matches, 1);
      c.dispose();
    });

    test('moves increments to 1', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.moves, 1);
      c.dispose();
    });

    test('score increases after a match', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.score, greaterThan(0));
      c.dispose();
    });

    test('score is within documented min/max bounds (30–600)', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.state.score, inInclusiveRange(30, 600));
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // flip — mismatching pair (520 ms internal delay)
  // -------------------------------------------------------------------------

  group('MemoryFlipController.flip — mismatching pair', () {
    test('returns "miss"', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      expect(await c.flip(nm[1], (_) {}), 'miss');
      c.dispose();
    });

    test('misses increments to 1', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      await c.flip(nm[1], (_) {});
      expect(c.state.misses, 1);
      c.dispose();
    });

    test('moves increments to 1', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      await c.flip(nm[1], (_) {});
      expect(c.state.moves, 1);
      c.dispose();
    });

    test('both cards are face-down after the miss delay', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      await c.flip(nm[1], (_) {}); // flip() awaits the 520 ms internally
      expect(c.state.cards[nm[0]].isFaceUp, isFalse);
      expect(c.state.cards[nm[1]].isFaceUp, isFalse);
      c.dispose();
    });

    test('inputLocked is false after the miss resolves', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      await c.flip(nm[1], (_) {});
      expect(c.state.inputLocked, isFalse);
      c.dispose();
    });

    test('score never goes below 0 from miss penalty', () async {
      final c = _ctrl();
      final nm = findNonMatchingPair(c.state.cards);
      await c.flip(nm[0], (_) {});
      await c.flip(nm[1], (_) {});
      expect(c.state.score, greaterThanOrEqualTo(0));
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // flip — ignored cases
  // -------------------------------------------------------------------------

  group('MemoryFlipController.flip — ignored', () {
    test('returns "ignored" when flipping an already-matched card', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {}); // match
      expect(await c.flip(pair[0], (_) {}), 'ignored');
      c.dispose();
    });

    test('returns "ignored" when flipping a card that is face-up (same card)', () async {
      final c = _ctrl();
      await c.flip(0, (_) {}); // first flip
      expect(await c.flip(0, (_) {}), 'ignored');
      c.dispose();
    });

    test('returns "ignored" when game is over', () async {
      final c = _ctrl();
      await matchAll(c);
      expect(c.state.isOver, isTrue);
      expect(await c.flip(0, (_) {}), 'ignored');
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // allMatched → isOver
  // -------------------------------------------------------------------------

  group('MemoryFlipController — allMatched → isOver', () {
    test('isOver becomes true when all pairs are matched', () async {
      final c = _ctrl();
      await matchAll(c);
      expect(c.state.allMatched, isTrue);
      expect(c.state.isOver, isTrue);
      c.dispose();
    });

    test('matches equals totalPairs when all pairs matched', () async {
      final c = _ctrl();
      await matchAll(c);
      expect(c.state.matches, c.state.totalPairs);
      c.dispose();
    });

    test('completion is 1.0 in toResult after all matched', () async {
      final c = _ctrl();
      await matchAll(c);
      expect(c.toResult().metadata['completion'], closeTo(1.0, 0.001));
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // toResult()
  // -------------------------------------------------------------------------

  group('MemoryFlipController.toResult()', () {
    test('gameId is ArcadeGameId.memoryFlip', () {
      final c = _ctrl();
      expect(c.toResult().gameId, ArcadeGameId.memoryFlip);
      c.dispose();
    });

    test('difficulty matches the constructed difficulty', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.hard);
      expect(c.toResult().difficulty, ArcadeDifficulty.hard);
      c.dispose();
    });

    test('metadata contains pairsMatched, totalPairs, moves, misses, completion, hitRate', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      final meta = c.toResult().metadata;
      expect(meta.containsKey('pairsMatched'), isTrue);
      expect(meta.containsKey('totalPairs'), isTrue);
      expect(meta.containsKey('moves'), isTrue);
      expect(meta.containsKey('misses'), isTrue);
      expect(meta.containsKey('completion'), isTrue);
      expect(meta.containsKey('hitRate'), isTrue);
      c.dispose();
    });

    test('pairsMatched reflects actual match count', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.toResult().metadata['pairsMatched'], 1);
      c.dispose();
    });

    test('totalPairs is cards.length / 2', () {
      final c = _ctrl(difficulty: ArcadeDifficulty.easy); // 12 cards
      expect(c.toResult().metadata['totalPairs'], 6);
      c.dispose();
    });

    test('completion is 0 initially (no matches)', () {
      final c = _ctrl();
      expect(c.toResult().metadata['completion'], 0.0);
      c.dispose();
    });

    test('score in result matches state score', () async {
      final c = _ctrl();
      final pair = findMatchingPair(c.state.cards);
      await c.flip(pair[0], (_) {});
      await c.flip(pair[1], (_) {});
      expect(c.toResult().score, c.state.score);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // dispose()
  // -------------------------------------------------------------------------

  group('MemoryFlipController.dispose()', () {
    test('does not throw', () {
      final c = _ctrl();
      expect(() => c.dispose(), returnsNormally);
    });

    test('can be called multiple times without throwing', () {
      final c = _ctrl();
      c.dispose();
      expect(() => c.dispose(), returnsNormally);
    });
  });
}
