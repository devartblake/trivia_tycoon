import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/flow_connect_grid_cell.dart';
import 'package:synaptix/game/models/flow_connect_level_data.dart';
import 'package:synaptix/game/models/flow_connect_path_point.dart';

void main() {
  // -------------------------------------------------------------------------
  // FlowConnectGridCell
  // -------------------------------------------------------------------------

  group('FlowConnectGridCell', () {
    test('constructs with required fields and defaults', () {
      final cell = FlowConnectGridCell(row: 2, col: 3);
      expect(cell.row, 2);
      expect(cell.col, 3);
      expect(cell.number, isNull);
      expect(cell.isVisited, isFalse);
      expect(cell.isWall, isFalse);
    });

    test('constructs with all fields specified', () {
      final cell = FlowConnectGridCell(
        row: 0,
        col: 1,
        number: 5,
        isVisited: true,
        isWall: true,
      );
      expect(cell.number, 5);
      expect(cell.isVisited, isTrue);
      expect(cell.isWall, isTrue);
    });

    test('copyWith updates row and col', () {
      final original = FlowConnectGridCell(row: 1, col: 1);
      final copy = original.copyWith(row: 3, col: 4);
      expect(copy.row, 3);
      expect(copy.col, 4);
      expect(copy.isVisited, isFalse);
    });

    test('copyWith updates isVisited', () {
      final original = FlowConnectGridCell(row: 0, col: 0);
      final visited = original.copyWith(isVisited: true);
      expect(visited.isVisited, isTrue);
      expect(visited.row, 0);
    });

    test('copyWith updates isWall', () {
      final original = FlowConnectGridCell(row: 0, col: 0);
      final wall = original.copyWith(isWall: true);
      expect(wall.isWall, isTrue);
    });

    test('copyWith updates number', () {
      final original = FlowConnectGridCell(row: 0, col: 0);
      final numbered = original.copyWith(number: 7);
      expect(numbered.number, 7);
    });

    test('copyWith with no args preserves all values', () {
      final original = FlowConnectGridCell(
        row: 2,
        col: 3,
        number: 4,
        isVisited: true,
        isWall: false,
      );
      final copy = original.copyWith();
      expect(copy.row, original.row);
      expect(copy.col, original.col);
      expect(copy.number, original.number);
      expect(copy.isVisited, original.isVisited);
    });
  });

  // -------------------------------------------------------------------------
  // Direction enum
  // -------------------------------------------------------------------------

  group('Direction enum', () {
    test('has 5 values: up, down, left, right, none', () {
      expect(Direction.values.length, 5);
      expect(
          Direction.values,
          containsAll([
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
    test('constructs with required fields and default directions', () {
      final point = FlowConnectPathPoint(row: 1, col: 2, order: 0);
      expect(point.row, 1);
      expect(point.col, 2);
      expect(point.order, 0);
      expect(point.fromDirection, Direction.none);
      expect(point.toDirection, Direction.none);
    });

    test('constructs with explicit directions', () {
      final point = FlowConnectPathPoint(
        row: 0,
        col: 0,
        order: 1,
        fromDirection: Direction.up,
        toDirection: Direction.right,
      );
      expect(point.fromDirection, Direction.up);
      expect(point.toDirection, Direction.right);
    });

    test('copyWith updates order', () {
      final original = FlowConnectPathPoint(row: 0, col: 0, order: 1);
      final copy = original.copyWith(order: 5);
      expect(copy.order, 5);
      expect(copy.row, 0);
    });

    test('copyWith updates directions', () {
      final original = FlowConnectPathPoint(row: 0, col: 0, order: 0);
      final copy = original.copyWith(
        fromDirection: Direction.left,
        toDirection: Direction.down,
      );
      expect(copy.fromDirection, Direction.left);
      expect(copy.toDirection, Direction.down);
    });

    test('copyWith with no args preserves all values', () {
      final original = FlowConnectPathPoint(
        row: 3,
        col: 4,
        order: 2,
        fromDirection: Direction.up,
        toDirection: Direction.right,
      );
      final copy = original.copyWith();
      expect(copy.row, original.row);
      expect(copy.col, original.col);
      expect(copy.order, original.order);
      expect(copy.fromDirection, original.fromDirection);
      expect(copy.toDirection, original.toDirection);
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectLevelData
  // -------------------------------------------------------------------------

  group('FlowConnectLevelData', () {
    test('constructs and exposes fields', () {
      final grid = [
        [FlowConnectGridCell(row: 0, col: 0)],
      ];
      final path = [FlowConnectPathPoint(row: 0, col: 0, order: 0)];
      final level = FlowConnectLevelData(
        grid: grid,
        gridSize: 3,
        totalNumbers: 5,
        solutionPath: path,
      );
      expect(level.gridSize, 3);
      expect(level.totalNumbers, 5);
      expect(level.grid.length, 1);
      expect(level.solutionPath.length, 1);
    });

    test('empty grid and path are valid', () {
      final level = FlowConnectLevelData(
        grid: [],
        gridSize: 0,
        totalNumbers: 0,
        solutionPath: [],
      );
      expect(level.grid, isEmpty);
      expect(level.solutionPath, isEmpty);
    });
  });
}
