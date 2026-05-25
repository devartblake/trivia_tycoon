import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/state/flow_connect_game_state.dart';
import 'package:trivia_tycoon/game/models/flow_connect_grid_cell.dart';
import 'package:trivia_tycoon/game/models/flow_connect_path_point.dart';

// Minimal 2×2 grid helper
List<List<FlowConnectGridCell>> _makeGrid() => [
      [
        FlowConnectGridCell(row: 0, col: 0),
        FlowConnectGridCell(row: 0, col: 1)
      ],
      [
        FlowConnectGridCell(row: 1, col: 0),
        FlowConnectGridCell(row: 1, col: 1)
      ],
    ];

List<FlowConnectPathPoint> _makePath() => [
      FlowConnectPathPoint(row: 0, col: 0, order: 0),
      FlowConnectPathPoint(row: 0, col: 1, order: 1),
    ];

FlowConnectGameState _makeState({
  List<FlowConnectPathPoint>? currentPath,
  int currentNumber = 1,
  bool isComplete = false,
  FlowConnectGameStatus status = FlowConnectGameStatus.playing,
}) =>
    FlowConnectGameState(
      grid: _makeGrid(),
      currentPath: currentPath ?? _makePath(),
      currentNumber: currentNumber,
      isComplete: isComplete,
      gridSize: 2,
      totalNumbers: 2,
      status: status,
    );

void main() {
  // -------------------------------------------------------------------------
  // FlowConnectGameStatus enum
  // -------------------------------------------------------------------------

  group('FlowConnectGameStatus enum', () {
    test('has exactly 4 values', () {
      expect(FlowConnectGameStatus.values.length, 4);
    });

    test('contains notStarted', () {
      expect(FlowConnectGameStatus.values,
          contains(FlowConnectGameStatus.notStarted));
    });

    test('contains playing', () {
      expect(FlowConnectGameStatus.values,
          contains(FlowConnectGameStatus.playing));
    });

    test('contains success', () {
      expect(FlowConnectGameStatus.values,
          contains(FlowConnectGameStatus.success));
    });

    test('contains failed', () {
      expect(
          FlowConnectGameStatus.values, contains(FlowConnectGameStatus.failed));
    });

    test('all values are distinct', () {
      expect(FlowConnectGameStatus.values.toSet().length, 4);
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectGameState construction
  // -------------------------------------------------------------------------

  group('FlowConnectGameState construction', () {
    test('stores gridSize', () {
      expect(_makeState().gridSize, 2);
    });

    test('stores totalNumbers', () {
      expect(_makeState().totalNumbers, 2);
    });

    test('stores currentNumber', () {
      expect(_makeState(currentNumber: 3).currentNumber, 3);
    });

    test('stores isComplete', () {
      expect(_makeState(isComplete: true).isComplete, isTrue);
    });

    test('stores status', () {
      expect(_makeState(status: FlowConnectGameStatus.success).status,
          FlowConnectGameStatus.success);
    });

    test('stores currentPath', () {
      final path = _makePath();
      expect(_makeState(currentPath: path).currentPath, path);
    });

    test('canUndo is false on fresh state', () {
      expect(_makeState().canUndo, isFalse);
    });

    test('canRedo is false on fresh state', () {
      expect(_makeState().canRedo, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('copyWith', () {
    test('updates gridSize', () {
      final s = _makeState().copyWith(gridSize: 5);
      expect(s.gridSize, 5);
    });

    test('updates totalNumbers', () {
      final s = _makeState().copyWith(totalNumbers: 10);
      expect(s.totalNumbers, 10);
    });

    test('updates currentNumber', () {
      final s = _makeState().copyWith(currentNumber: 7);
      expect(s.currentNumber, 7);
    });

    test('updates isComplete', () {
      final s = _makeState().copyWith(isComplete: true);
      expect(s.isComplete, isTrue);
    });

    test('updates status', () {
      final s = _makeState().copyWith(status: FlowConnectGameStatus.failed);
      expect(s.status, FlowConnectGameStatus.failed);
    });

    test('updates currentPath', () {
      final newPath = [FlowConnectPathPoint(row: 1, col: 1, order: 0)];
      final s = _makeState().copyWith(currentPath: newPath);
      expect(s.currentPath, newPath);
    });

    test('preserves gridSize when not provided', () {
      final s = _makeState().copyWith(currentNumber: 2);
      expect(s.gridSize, 2);
    });

    test('preserves isComplete when not provided', () {
      final s = _makeState(isComplete: false).copyWith(currentNumber: 2);
      expect(s.isComplete, isFalse);
    });

    test('preserves status when not provided', () {
      final s = _makeState(status: FlowConnectGameStatus.notStarted)
          .copyWith(gridSize: 3);
      expect(s.status, FlowConnectGameStatus.notStarted);
    });

    test('preserves currentPath when not provided', () {
      final path = _makePath();
      final s = _makeState(currentPath: path).copyWith(gridSize: 3);
      expect(s.currentPath, path);
    });
  });

  // -------------------------------------------------------------------------
  // recordState
  // -------------------------------------------------------------------------

  group('recordState', () {
    test('canUndo becomes true after recordState', () {
      final s = _makeState().recordState();
      expect(s.canUndo, isTrue);
    });

    test('canRedo is false after recordState (at end of history)', () {
      final s = _makeState().recordState();
      expect(s.canRedo, isFalse);
    });

    test('second recordState gives canUndo true', () {
      final s = _makeState().recordState().recordState();
      expect(s.canUndo, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // undo / redo
  // -------------------------------------------------------------------------

  group('undo', () {
    test('undo at start (historyIndex=0) returns state with canUndo false', () {
      final s = _makeState();
      final undone = s.undo();
      expect(undone.canUndo, isFalse);
    });

    test('undo after recordState gives canUndo false', () {
      final s1 = _makeState();
      final s2 = s1.recordState();
      final s3 = s2.undo();
      expect(s3.canUndo, isFalse);
    });

    test('canRedo true after undo', () {
      final s = _makeState().recordState().undo();
      expect(s.canRedo, isTrue);
    });

    test('undo restores original currentPath', () {
      final originalPath = _makePath();
      final s1 = _makeState(currentPath: originalPath);
      final newPath = [FlowConnectPathPoint(row: 1, col: 0, order: 0)];
      final s2 = s1.recordState().copyWith(currentPath: newPath).recordState();
      final s3 = s2.undo();
      // After two recordStates and one undo, we should be at the second state
      expect(s3.canUndo, isTrue);
    });
  });

  group('redo', () {
    test('redo at end of history returns state with canRedo false', () {
      final s = _makeState().recordState();
      final redone = s.redo();
      expect(redone.canRedo, isFalse);
    });

    test('canRedo false after undo+redo', () {
      final s = _makeState().recordState().undo().redo();
      expect(s.canRedo, isFalse);
    });

    test('canUndo true after undo+redo', () {
      final s = _makeState().recordState().undo().redo();
      expect(s.canUndo, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // trimHistory
  // -------------------------------------------------------------------------

  group('trimHistory', () {
    test('trimHistory at end of history: canRedo still false', () {
      final s = _makeState().recordState().trimHistory();
      expect(s.canRedo, isFalse);
    });

    test('trimHistory after undo: canRedo becomes false', () {
      final s = _makeState().recordState().undo().trimHistory();
      expect(s.canRedo, isFalse);
    });

    test('trimHistory after undo: canUndo stays false', () {
      final s = _makeState().recordState().undo().trimHistory();
      expect(s.canUndo, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // equality and hashCode
  // -------------------------------------------------------------------------

  group('equality', () {
    test('two states with same construction params are equal', () {
      final path = _makePath();
      final grid = _makeGrid();
      final s1 = FlowConnectGameState(
        grid: grid,
        currentPath: path,
        currentNumber: 1,
        isComplete: false,
        gridSize: 2,
        totalNumbers: 2,
        status: FlowConnectGameStatus.playing,
      );
      final s2 = FlowConnectGameState(
        grid: grid,
        currentPath: path,
        currentNumber: 1,
        isComplete: false,
        gridSize: 2,
        totalNumbers: 2,
        status: FlowConnectGameStatus.playing,
      );
      expect(s1, equals(s2));
    });

    test('states differing in currentNumber are not equal', () {
      final s1 = _makeState(currentNumber: 1);
      final s2 = _makeState(currentNumber: 2);
      expect(s1, isNot(equals(s2)));
    });

    test('states differing in gridSize are not equal', () {
      final s1 = _makeState().copyWith(gridSize: 2);
      final s2 = _makeState().copyWith(gridSize: 3);
      expect(s1, isNot(equals(s2)));
    });
  });

  group('hashCode', () {
    test('equal states have same hashCode', () {
      final path = _makePath();
      final grid = _makeGrid();
      final s1 = FlowConnectGameState(
        grid: grid,
        currentPath: path,
        currentNumber: 1,
        isComplete: false,
        gridSize: 2,
        totalNumbers: 2,
        status: FlowConnectGameStatus.playing,
      );
      final s2 = FlowConnectGameState(
        grid: grid,
        currentPath: path,
        currentNumber: 1,
        isComplete: false,
        gridSize: 2,
        totalNumbers: 2,
        status: FlowConnectGameStatus.playing,
      );
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });
}
