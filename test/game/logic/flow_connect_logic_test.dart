import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/flow_connect_grid_cell.dart';
import 'package:trivia_tycoon/game/models/flow_connect_path_point.dart';
import 'package:trivia_tycoon/game/logic/flow_connect_path_validator.dart';
import 'package:trivia_tycoon/game/state/flow_connect_game_state.dart';

List<List<FlowConnectGridCell>> _makeGrid(
  int rows,
  int cols, {
  Map<String, int>? numbers,
}) {
  return List.generate(
    rows,
    (row) => List.generate(
      cols,
      (col) => FlowConnectGridCell(
        row: row,
        col: col,
        number: numbers?['$row,$col'],
      ),
    ),
  );
}

FlowConnectGameState _makeState({
  required List<List<FlowConnectGridCell>> grid,
  required List<FlowConnectPathPoint> path,
  required int gridSize,
  int totalNumbers = 2,
}) =>
    FlowConnectGameState(
      grid: grid,
      currentPath: path,
      currentNumber: 1,
      isComplete: false,
      gridSize: gridSize,
      totalNumbers: totalNumbers,
      status: FlowConnectGameStatus.playing,
    );

void main() {
  // -------------------------------------------------------------------------
  // FlowConnectGridCell
  // -------------------------------------------------------------------------

  group('FlowConnectGridCell', () {
    test('stores row, col, number, isVisited, isWall', () {
      final cell = FlowConnectGridCell(
          row: 1, col: 2, number: 3, isVisited: true, isWall: true);
      expect(cell.row, 1);
      expect(cell.col, 2);
      expect(cell.number, 3);
      expect(cell.isVisited, isTrue);
      expect(cell.isWall, isTrue);
    });

    test('isVisited defaults to false', () {
      final cell = FlowConnectGridCell(row: 0, col: 0);
      expect(cell.isVisited, isFalse);
    });

    test('isWall defaults to false', () {
      final cell = FlowConnectGridCell(row: 0, col: 0);
      expect(cell.isWall, isFalse);
    });

    test('number defaults to null', () {
      final cell = FlowConnectGridCell(row: 0, col: 0);
      expect(cell.number, isNull);
    });

    test('copyWith updates isVisited', () {
      final cell = FlowConnectGridCell(row: 0, col: 0);
      final updated = cell.copyWith(isVisited: true);
      expect(updated.isVisited, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final cell = FlowConnectGridCell(row: 1, col: 2, number: 5);
      final updated = cell.copyWith(isWall: true);
      expect(updated.row, 1);
      expect(updated.col, 2);
      expect(updated.number, 5);
      expect(updated.isWall, isTrue);
    });

    test('copyWith with number overrides existing number', () {
      final cell = FlowConnectGridCell(row: 0, col: 0, number: 1);
      final updated = cell.copyWith(number: 9);
      expect(updated.number, 9);
    });
  });

  // -------------------------------------------------------------------------
  // Direction enum
  // -------------------------------------------------------------------------

  group('Direction enum', () {
    test('has exactly 5 values', () {
      expect(Direction.values.length, 5);
    });

    test('contains up, down, left, right, none', () {
      expect(Direction.values, containsAll([
        Direction.up,
        Direction.down,
        Direction.left,
        Direction.right,
        Direction.none,
      ]));
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectPathPoint
  // -------------------------------------------------------------------------

  group('FlowConnectPathPoint', () {
    test('stores row, col, order', () {
      final p = FlowConnectPathPoint(row: 2, col: 3, order: 7);
      expect(p.row, 2);
      expect(p.col, 3);
      expect(p.order, 7);
    });

    test('fromDirection defaults to Direction.none', () {
      final p = FlowConnectPathPoint(row: 0, col: 0, order: 0);
      expect(p.fromDirection, Direction.none);
    });

    test('toDirection defaults to Direction.none', () {
      final p = FlowConnectPathPoint(row: 0, col: 0, order: 0);
      expect(p.toDirection, Direction.none);
    });

    test('stores custom fromDirection and toDirection', () {
      final p = FlowConnectPathPoint(
        row: 0,
        col: 0,
        order: 0,
        fromDirection: Direction.up,
        toDirection: Direction.down,
      );
      expect(p.fromDirection, Direction.up);
      expect(p.toDirection, Direction.down);
    });

    test('copyWith updates row', () {
      final p = FlowConnectPathPoint(row: 0, col: 1, order: 2);
      final updated = p.copyWith(row: 5);
      expect(updated.row, 5);
      expect(updated.col, 1);
      expect(updated.order, 2);
    });

    test('copyWith updates fromDirection', () {
      final p = FlowConnectPathPoint(row: 0, col: 0, order: 0);
      final updated = p.copyWith(fromDirection: Direction.left);
      expect(updated.fromDirection, Direction.left);
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectPathValidator.isValidPath
  // -------------------------------------------------------------------------

  group('FlowConnectPathValidator.isValidPath', () {
    final grid2x2 = _makeGrid(2, 2);

    test('empty path (0 points) returns true', () {
      expect(FlowConnectPathValidator.isValidPath([], grid2x2), isTrue);
    });

    test('single-point path returns true', () {
      final path = [FlowConnectPathPoint(row: 0, col: 0, order: 0)];
      expect(FlowConnectPathValidator.isValidPath(path, grid2x2), isTrue);
    });

    test('path with duplicate coordinates returns false', () {
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 0, order: 1),
      ];
      expect(FlowConnectPathValidator.isValidPath(path, grid2x2), isFalse);
    });

    test('valid adjacent path of 2 points returns true', () {
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
      ];
      expect(FlowConnectPathValidator.isValidPath(path, grid2x2), isTrue);
    });

    test('diagonal step (dx+dy != 1) returns false', () {
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 1, col: 1, order: 1),
      ];
      expect(FlowConnectPathValidator.isValidPath(path, grid2x2), isFalse);
    });

    test('out-of-order numbered cells returns false', () {
      // grid: (0,0)=2, (0,1)=1 — visiting 2 before 1
      final grid = _makeGrid(1, 2, numbers: {'0,0': 2, '0,1': 1});
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
      ];
      expect(FlowConnectPathValidator.isValidPath(path, grid), isFalse);
    });

    test('in-order numbered cells returns true', () {
      // grid: (0,0)=1, (0,1)=2 — visiting 1 then 2
      final grid = _makeGrid(1, 2, numbers: {'0,0': 1, '0,1': 2});
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
      ];
      expect(FlowConnectPathValidator.isValidPath(path, grid), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectPathValidator.checkWinCondition
  // -------------------------------------------------------------------------

  group('FlowConnectPathValidator.checkWinCondition', () {
    // 2x2 grid: (0,0)=1, (0,1)=null, (1,0)=null, (1,1)=2
    final grid2x2 = _makeGrid(2, 2, numbers: {'0,0': 1, '1,1': 2});

    test('path shorter than gridSize*gridSize returns false', () {
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
        FlowConnectPathPoint(row: 1, col: 1, order: 2),
      ]; // length 3, need 4
      final state = _makeState(grid: grid2x2, path: path, gridSize: 2);
      expect(FlowConnectPathValidator.checkWinCondition(state), isFalse);
    });

    test('correct number sequence covering all cells returns true', () {
      // (0,0)=1 → (0,1)=null → (1,0)=null → (1,1)=2
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
        FlowConnectPathPoint(row: 1, col: 0, order: 2),
        FlowConnectPathPoint(row: 1, col: 1, order: 3),
      ];
      final state = _makeState(grid: grid2x2, path: path, gridSize: 2);
      expect(FlowConnectPathValidator.checkWinCondition(state), isTrue);
    });

    test('visiting numbered cells out of order returns false', () {
      // (1,1)=2 visited first, before (0,0)=1
      final path = [
        FlowConnectPathPoint(row: 1, col: 1, order: 0),
        FlowConnectPathPoint(row: 1, col: 0, order: 1),
        FlowConnectPathPoint(row: 0, col: 0, order: 2),
        FlowConnectPathPoint(row: 0, col: 1, order: 3),
      ];
      final state = _makeState(grid: grid2x2, path: path, gridSize: 2);
      expect(FlowConnectPathValidator.checkWinCondition(state), isFalse);
    });

    test('path that skips last numbered cell returns false', () {
      // Grid where (1,1) has number=2 but path only visits cells with number<=1
      final gridMissing2 = _makeGrid(2, 2, numbers: {'0,0': 1});
      // 4-cell path that never reaches any cell with number=2
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
        FlowConnectPathPoint(row: 1, col: 0, order: 2),
        FlowConnectPathPoint(row: 1, col: 1, order: 3),
      ];
      // totalNumbers=2 but grid only has one numbered cell (number=1)
      // lastVisitedNumber will be 1, not equal to totalNumbers(2)
      final state = _makeState(
          grid: gridMissing2, path: path, gridSize: 2, totalNumbers: 2);
      expect(FlowConnectPathValidator.checkWinCondition(state), isFalse);
    });
  });
}
