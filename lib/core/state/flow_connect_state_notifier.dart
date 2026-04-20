import 'package:flutter/material.dart';
import '../../game/logic/flow_connect_path_validator.dart';
import '../../game/models/flow_connect_level_data.dart';
import '../../game/models/flow_connect_path_point.dart';
import '../../game/services/flow_connect_level_generator.dart';
import '../../game/state/flow_connect_game_state.dart';
import '../../screens/mini_games/system/flow_connect_hint_system.dart';

class FlowConnectStateNotifier extends ChangeNotifier {
  late FlowConnectGameState _gameState;
  late List<FlowConnectPathPoint> _solutionPath;
  FlowConnectPathPoint? _lastPoint;
  FlowConnectPathPoint? _hintPoint;

  DateTime? _startTime;
  DateTime? _endTime;
  final VoidCallback? onPuzzleComplete;

  FlowConnectGameState get gameState => _gameState;
  FlowConnectPathPoint? get hintPoint => _hintPoint;

  String get completionTime {
    if (_startTime == null || _endTime == null) return '0:00';
    final duration = _endTime!.difference(_startTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  FlowConnectStateNotifier({
    required int gridSize,
    required FlowConnectDifficulty difficulty,
    this.onPuzzleComplete,
  }) {
    initializeGame(gridSize, difficulty);
  }

  void initializeGame(int gridSize, FlowConnectDifficulty difficulty) {
    final FlowConnectLevelData level =
        FlowConnectLevelGenerator.generateLevel(gridSize, difficulty);
    _solutionPath = level.solutionPath;
    _gameState = FlowConnectGameState(
      grid: level.grid,
      currentPath: [],
      currentNumber: 1,
      isComplete: false,
      gridSize: gridSize,
      totalNumbers: level.totalNumbers,
      status: FlowConnectGameStatus.notStarted,
    );
    _hintPoint = null;
    _lastPoint = null;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  void undo() {
    _gameState = _gameState.undo();
    notifyListeners();
  }

  void redo() {
    _gameState = _gameState.redo();
    notifyListeners();
  }

  bool get canUndo => _gameState.canUndo;
  bool get canRedo => _gameState.canRedo;

  void showHint() {
    final hint = FlowConnectHintSystem.getNextHint(_gameState, _solutionPath);
    if (hint != null) {
      _hintPoint = hint;
      notifyListeners();
      Future.delayed(const Duration(seconds: 1), () {
        _hintPoint = null;
        notifyListeners();
      });
    }
  }

  void onPanStart(Offset detailsLocalPosition, double cellSize) {
    if (_gameState.status == FlowConnectGameStatus.success) return;

    // Start timer on first move
    _startTime ??= DateTime.now();

    _hintPoint = null;
    final point = _pointFromOffset(detailsLocalPosition, cellSize);
    if (point == null) return;

    final cell = _gameState.grid[point.row][point.col];
    if (cell.number == 1) {
      _gameState = _gameState.copyWith(
        currentPath: [point],
        status: FlowConnectGameStatus.playing,
        currentNumber: 2,
      ).recordState();
      _lastPoint = point;
      notifyListeners();
    }
  }

  void onPanUpdate(Offset detailsLocalPosition, double cellSize) {
    if (_gameState.status != FlowConnectGameStatus.playing) return;

    final currentGridPoint = _pointFromOffset(detailsLocalPosition, cellSize);
    if (currentGridPoint == null) return;

    // If the user is trying to go back to the previous point (backtracking)
    if (_gameState.currentPath.length > 1 &&
        currentGridPoint.row ==
            _gameState.currentPath[_gameState.currentPath.length - 2].row &&
        currentGridPoint.col ==
            _gameState.currentPath[_gameState.currentPath.length - 2].col) {
      _gameState = _gameState.copyWith(
        currentPath: List<FlowConnectPathPoint>.from(_gameState.currentPath)
          ..removeLast(),
      );
      _lastPoint = _gameState.currentPath.last;
      final cell = _gameState.grid[_lastPoint!.row][_lastPoint!.col];
      if (cell.number != null && cell.number! < _gameState.currentNumber) {
        _gameState = _gameState.copyWith(currentNumber: cell.number! + 1);
      }
      _gameState = _gameState.recordState();
      notifyListeners();
      return;
    }

    // If the user is trying to move to the same point, do nothing
    if (_lastPoint != null &&
        currentGridPoint.row == _lastPoint!.row &&
        currentGridPoint.col == _lastPoint!.col) {
      return;
    }

    // Check if the new point is a valid next step (adjacent and not already in path, unless it's a number)
    final isAdjacent = (currentGridPoint.row - _lastPoint!.row).abs() +
            (currentGridPoint.col - _lastPoint!.col).abs() ==
        1;
    final isAlreadyInPath = _gameState.currentPath.any(
        (p) => p.row == currentGridPoint.row && p.col == currentGridPoint.col);
    final isNumberedCell =
        _gameState.grid[currentGridPoint.row][currentGridPoint.col].number !=
            null;

    if (isAdjacent && (!isAlreadyInPath || isNumberedCell)) {
      final newPath = List<FlowConnectPathPoint>.from(_gameState.currentPath)
        ..add(currentGridPoint);

      if (FlowConnectPathValidator.isValidPath(newPath, _gameState.grid)) {
        final cell =
            _gameState.grid[currentGridPoint.row][currentGridPoint.col];
        int nextNumber = _gameState.currentNumber;
        if (cell.number == nextNumber) {
          nextNumber++;
        }

        _gameState = _gameState
            .copyWith(
              currentPath: newPath,
              currentNumber: nextNumber,
            )
            .recordState();
        _lastPoint = currentGridPoint;
        notifyListeners();
      }
    }
  }

  FlowConnectGameStatus onPanEnd() {
    if (_gameState.status != FlowConnectGameStatus.playing)
      return _gameState.status;

    if (FlowConnectPathValidator.checkWinCondition(_gameState)) {
      _endTime = DateTime.now();
      _gameState = _gameState.copyWith(status: FlowConnectGameStatus.success);
      notifyListeners();

      // Trigger completion callback after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        onPuzzleComplete?.call();
      });

      return FlowConnectGameStatus.success;
    } else {
      _gameState = _gameState.trimHistory();
      notifyListeners();
      return _gameState.status;
    }
  }

  FlowConnectPathPoint? _pointFromOffset(Offset offset, double cellSize) {
    final row = (offset.dy / cellSize).floor();
    final col = (offset.dx / cellSize).floor();

    if (row >= 0 &&
        row < _gameState.gridSize &&
        col >= 0 &&
        col < _gameState.gridSize) {
      return FlowConnectPathPoint(
          row: row, col: col, order: _gameState.currentPath.length);
    }
    return null;
  }
}
