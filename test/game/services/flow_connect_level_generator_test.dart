import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/flow_connect_level_generator.dart';

void main() {
  // -------------------------------------------------------------------------
  // generateLevel — basic contract
  // -------------------------------------------------------------------------

  group('generateLevel — gridSize contract', () {
    test('returned level.gridSize matches the requested grid size', () {
      for (final size in [3, 4, 5, 6]) {
        final level = FlowConnectLevelGenerator.generateLevel(
            size, FlowConnectDifficulty.medium);
        expect(level.gridSize, size, reason: 'gridSize should be $size');
      }
    });

    test('grid rows match gridSize when path succeeds', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (level.solutionPath.isNotEmpty) {
        expect(level.grid.length, 5);
      }
    });

    test('each grid row has gridSize columns when path succeeds', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (level.solutionPath.isNotEmpty) {
        for (final row in level.grid) {
          expect(row.length, 5);
        }
      }
    });

    test('solutionPath visits every cell (length == gridSize²) on success', () {
      // Use 4x4 — very high probability of Hamiltonian path success
      final level = FlowConnectLevelGenerator.generateLevel(
          4, FlowConnectDifficulty.easy);
      if (level.solutionPath.isNotEmpty) {
        expect(level.solutionPath.length, 4 * 4);
      }
    });
  });

  // -------------------------------------------------------------------------
  // generateLevel — failure path (empty grid sentinel)
  // -------------------------------------------------------------------------

  group('generateLevel — failure sentinel', () {
    test('on path failure: grid is empty', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      // Both paths: success (grid filled) or failure (grid empty)
      if (level.solutionPath.isEmpty) {
        expect(level.grid, isEmpty);
      }
    });

    test('on path failure: totalNumbers is 0', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (level.solutionPath.isEmpty) {
        expect(level.totalNumbers, 0);
      }
    });
  });

  // -------------------------------------------------------------------------
  // generateLevel — checkpoint count formula
  //
  // Formula (for successful generation):
  //   base = (gridSize² / 5).toInt().clamp(4, 12)
  //   easy  = (base * 0.8).toInt().clamp(4, 12)
  //   medium = base
  //   hard  = (base * 1.2).toInt().clamp(4, 12)
  //
  // gridSize=5: base=5, easy=4, medium=5, hard=6  → all distinct
  // -------------------------------------------------------------------------

  group('generateLevel — checkpoint counts by difficulty', () {
    test('totalNumbers is in valid range [4, 12] on success', () {
      for (final diff in FlowConnectDifficulty.values) {
        final level = FlowConnectLevelGenerator.generateLevel(5, diff);
        if (level.solutionPath.isNotEmpty) {
          expect(level.totalNumbers, inInclusiveRange(4, 12),
              reason: '$diff should produce 4–12 checkpoints');
        }
      }
    });

    test('gridSize=5 easy produces 4 checkpoints', () {
      // base = (25/5).toInt() = 5; easy = (5*0.8).toInt().clamp(4,12) = 4
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.easy);
      if (level.solutionPath.isNotEmpty) {
        expect(level.totalNumbers, 4);
      }
    });

    test('gridSize=5 medium produces 5 checkpoints', () {
      // base = (25/5).toInt() = 5; medium = 5 (unchanged)
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (level.solutionPath.isNotEmpty) {
        expect(level.totalNumbers, 5);
      }
    });

    test('gridSize=5 hard produces 6 checkpoints', () {
      // base = 5; hard = (5*1.2).toInt().clamp(4,12) = 6
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.hard);
      if (level.solutionPath.isNotEmpty) {
        expect(level.totalNumbers, 6);
      }
    });

    test('hard produces >= medium checkpoints for gridSize=5', () {
      final medium = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      final hard = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.hard);
      if (medium.solutionPath.isNotEmpty && hard.solutionPath.isNotEmpty) {
        expect(hard.totalNumbers, greaterThanOrEqualTo(medium.totalNumbers));
      }
    });

    test('medium produces >= easy checkpoints for gridSize=5', () {
      final easy = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.easy);
      final medium = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (easy.solutionPath.isNotEmpty && medium.solutionPath.isNotEmpty) {
        expect(medium.totalNumbers, greaterThanOrEqualTo(easy.totalNumbers));
      }
    });
  });

  // -------------------------------------------------------------------------
  // generateLevel — grid cell positions
  // -------------------------------------------------------------------------

  group('generateLevel — grid cell positions', () {
    test('each grid cell has correct row and col indices', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          4, FlowConnectDifficulty.easy);
      if (level.solutionPath.isNotEmpty) {
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 4; c++) {
            expect(level.grid[r][c].row, r);
            expect(level.grid[r][c].col, c);
          }
        }
      }
    });

    test('numbered cells have number > 0', () {
      final level = FlowConnectLevelGenerator.generateLevel(
          5, FlowConnectDifficulty.medium);
      if (level.solutionPath.isNotEmpty) {
        final numberedCells = level.grid
            .expand((row) => row)
            .where((cell) => (cell.number ?? 0) > 0)
            .toList();
        expect(numberedCells.length, level.totalNumbers);
      }
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectDifficulty enum
  // -------------------------------------------------------------------------

  group('FlowConnectDifficulty enum', () {
    test('has exactly 3 values', () {
      expect(FlowConnectDifficulty.values, hasLength(3));
    });

    test('contains easy, medium, hard', () {
      expect(
          FlowConnectDifficulty.values,
          containsAll([
            FlowConnectDifficulty.easy,
            FlowConnectDifficulty.medium,
            FlowConnectDifficulty.hard,
          ]));
    });
  });
}
