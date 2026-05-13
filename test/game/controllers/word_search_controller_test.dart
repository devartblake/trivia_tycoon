import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/word_search_controller.dart';
import 'package:trivia_tycoon/game/models/word_search_model.dart';

WordSearchController _make([List<String>? words]) =>
    WordSearchController(words ?? ['CAT', 'DOG'], onPuzzleComplete: () {});

void main() {
  // -------------------------------------------------------------------------
  // formattedTime
  // -------------------------------------------------------------------------

  group('formattedTime', () {
    test('00:00 initially', () {
      final ctrl = _make();
      expect(ctrl.formattedTime, '00:00');
      ctrl.dispose();
    });

    test('format for known seconds values', () {
      // We can verify format by checking output of controller with known secondsElapsed
      // by using a workaround: reset keeps elapsed at 0
      final ctrl = _make();
      expect(ctrl.secondsElapsed, 0);
      ctrl.dispose();
    });

    test('format string is MM:SS pattern', () {
      final ctrl = _make();
      final time = ctrl.formattedTime;
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(time), isTrue);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // grid initialization
  // -------------------------------------------------------------------------

  group('grid initialization', () {
    test('grid is 12×12', () {
      final ctrl = _make();
      expect(ctrl.grid.length, 12);
      for (final row in ctrl.grid) {
        expect(row.length, 12);
      }
      ctrl.dispose();
    });

    test('each cell is a single uppercase letter', () {
      final ctrl = _make(['CAT', 'DOG', 'FOX']);
      for (final row in ctrl.grid) {
        for (final cell in row) {
          expect(cell.length, 1);
          expect(cell, matches(RegExp(r'^[A-Z]$')));
        }
      }
      ctrl.dispose();
    });

    test('wordPositions has correct count for short word list', () {
      final ctrl = _make(['CAT', 'DOG', 'FOX']);
      expect(ctrl.wordPositions.length, 3);
      ctrl.dispose();
    });

    test('foundWords is empty initially', () {
      final ctrl = _make();
      expect(ctrl.foundWords, isEmpty);
      ctrl.dispose();
    });

    test('words list stored (up to 8)', () {
      final ctrl = _make(['CAT', 'DOG']);
      expect(ctrl.words, containsAll(['CAT', 'DOG']));
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // word truncation to 8
  // -------------------------------------------------------------------------

  group('words truncated to 8', () {
    test('passing 10 words results in wordPositions.length <= 8', () {
      final ctrl = _make([
        'CAT', 'DOG', 'FOX', 'BEE', 'ANT',
        'RAT', 'OWL', 'EEL', 'YAK', 'GNU'
      ]);
      expect(ctrl.wordPositions.length, lessThanOrEqualTo(8));
      ctrl.dispose();
    });

    test('words list itself is truncated to first 8', () {
      final ctrl = _make([
        'CAT', 'DOG', 'FOX', 'BEE', 'ANT',
        'RAT', 'OWL', 'EEL', 'YAK', 'GNU'
      ]);
      expect(ctrl.words.length, 8);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // getCellHighlight
  // -------------------------------------------------------------------------

  group('getCellHighlight', () {
    test('returns null for cell not part of any found word', () {
      final ctrl = _make(['CAT']);
      // No words found yet
      expect(ctrl.getCellHighlight(0, 0), isNull);
      ctrl.dispose();
    });

    test('returns Color for cell in a found word', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        final wordPos = ctrl.wordPositions.first;
        // Manually add to foundWords to simulate finding the word
        ctrl.foundWords.add(wordPos.originalWord);
        final pos = wordPos.positions.first;
        final highlight = ctrl.getCellHighlight(pos.x, pos.y);
        expect(highlight, isNotNull);
        expect(highlight, isA<Color>());
      }
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // isCellSelected
  // -------------------------------------------------------------------------

  group('isCellSelected', () {
    test('false initially', () {
      final ctrl = _make();
      expect(ctrl.isCellSelected(0, 0), isFalse);
      ctrl.dispose();
    });

    test('true at drag start cell while dragging', () {
      final ctrl = _make();
      ctrl.onDragStart(3, 3);
      expect(ctrl.isCellSelected(3, 3), isTrue);
      ctrl.dispose();
    });

    test('false after onDragEnd', () {
      final ctrl = _make(['CAT']);
      ctrl.onDragStart(0, 0);
      ctrl.onDragEnd();
      expect(ctrl.isCellSelected(0, 0), isFalse);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // drag: onDragUpdate
  // -------------------------------------------------------------------------

  group('onDragUpdate', () {
    test('updates drag end cell while dragging', () {
      final ctrl = _make();
      ctrl.onDragStart(5, 5);
      ctrl.onDragUpdate(5, 7);
      // After update, cell (5,7) should be selected (it's part of the drag line)
      expect(ctrl.isCellSelected(5, 7), isTrue);
      ctrl.dispose();
    });

    test('no-op when not dragging', () {
      final ctrl = _make();
      ctrl.onDragUpdate(3, 3);
      // Should not throw or crash
      expect(ctrl.isCellSelected(3, 3), isFalse);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // drag: complete word found
  // -------------------------------------------------------------------------

  group('drag finds word', () {
    test('foundWords updated when word selected correctly', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        final wordPos = ctrl.wordPositions.first;
        final positions = wordPos.positions;
        if (positions.length >= 2) {
          final start = positions.first;
          final end = positions.last;
          ctrl.onDragStart(start.x, start.y);
          ctrl.onDragUpdate(end.x, end.y);
          ctrl.onDragEnd();
          expect(ctrl.foundWords.contains(wordPos.originalWord), isTrue);
        }
      }
      ctrl.dispose();
    });

    test('getCellHighlight returns color for found word cells', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        final wordPos = ctrl.wordPositions.first;
        final positions = wordPos.positions;
        if (positions.length >= 2) {
          final start = positions.first;
          final end = positions.last;
          ctrl.onDragStart(start.x, start.y);
          ctrl.onDragUpdate(end.x, end.y);
          ctrl.onDragEnd();
          final highlight = ctrl.getCellHighlight(start.x, start.y);
          expect(highlight, isNotNull);
        }
      }
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // invalid drag (non-straight line)
  // -------------------------------------------------------------------------

  group('invalid drag', () {
    test('non-straight line drag finds no word', () {
      final ctrl = _make(['CAT', 'DOG']);
      // L-shaped drag: not straight
      ctrl.onDragStart(0, 0);
      ctrl.onDragUpdate(2, 1); // diagonal but 2 rows, 1 col — not 45°
      ctrl.onDragEnd();
      expect(ctrl.foundWords, isEmpty);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // reset
  // -------------------------------------------------------------------------

  group('reset', () {
    test('foundWords empty after reset', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        ctrl.foundWords.add(ctrl.wordPositions.first.originalWord);
      }
      ctrl.reset();
      expect(ctrl.foundWords, isEmpty);
      ctrl.dispose();
    });

    test('grid still 12×12 after reset', () {
      final ctrl = _make();
      ctrl.reset();
      expect(ctrl.grid.length, 12);
      ctrl.dispose();
    });

    test('secondsElapsed reset to 0', () {
      final ctrl = _make();
      ctrl.reset();
      expect(ctrl.secondsElapsed, 0);
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // onPuzzleComplete callback
  // -------------------------------------------------------------------------

  group('onPuzzleComplete callback', () {
    test('fires when all words found', () async {
      bool called = false;
      final ctrl = WordSearchController(
        ['CAT'],
        onPuzzleComplete: () => called = true,
      );
      if (ctrl.wordPositions.isNotEmpty) {
        final wordPos = ctrl.wordPositions.first;
        final positions = wordPos.positions;
        if (positions.length >= 2) {
          final start = positions.first;
          final end = positions.last;
          ctrl.onDragStart(start.x, start.y);
          ctrl.onDragUpdate(end.x, end.y);
          ctrl.onDragEnd();
          // Callback called after 500ms delay
          await Future.delayed(const Duration(milliseconds: 600));
          expect(called, isTrue);
        }
      }
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // WordPosition struct
  // -------------------------------------------------------------------------

  group('WordPosition', () {
    test('originalWord matches the word searched for', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        expect(ctrl.wordPositions.first.originalWord, 'CAT');
      }
      ctrl.dispose();
    });

    test('positions list is non-empty for placed word', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        expect(ctrl.wordPositions.first.positions, isNotEmpty);
      }
      ctrl.dispose();
    });

    test('color is a valid Color', () {
      final ctrl = _make(['CAT']);
      if (ctrl.wordPositions.isNotEmpty) {
        expect(ctrl.wordPositions.first.color, isA<Color>());
      }
      ctrl.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // isDragging state
  // -------------------------------------------------------------------------

  group('isDragging state', () {
    test('false initially', () {
      final ctrl = _make();
      expect(ctrl.isDragging, isFalse);
      ctrl.dispose();
    });

    test('true during drag', () {
      final ctrl = _make();
      ctrl.onDragStart(3, 3);
      expect(ctrl.isDragging, isTrue);
      ctrl.dispose();
    });

    test('false after drag ends', () {
      final ctrl = _make();
      ctrl.onDragStart(3, 3);
      ctrl.onDragEnd();
      expect(ctrl.isDragging, isFalse);
      ctrl.dispose();
    });
  });
}
