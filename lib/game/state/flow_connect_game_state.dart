import 'package:flutter/foundation.dart';
import '../models/flow_connect_grid_cell.dart';
import '../models/flow_connect_path_point.dart';

enum FlowConnectGameStatus {
  notStarted,
  playing,
  success,
  failed,
}

@immutable
class FlowConnectGameState {
  final List<List<FlowConnectGridCell>> grid;
  final List<FlowConnectPathPoint> currentPath;
  final int currentNumber;
  final bool isComplete;
  final int gridSize;
  final int totalNumbers;
  final FlowConnectGameStatus status;

  // History for undo/redo
  final List<List<FlowConnectPathPoint>> _pathHistory;
  final List<int> _numberHistory;
  final int _historyIndex;

  FlowConnectGameState({
    required this.grid,
    required this.currentPath,
    required this.currentNumber,
    required this.isComplete,
    required this.gridSize,
    required this.totalNumbers,
    required this.status,
    List<List<FlowConnectPathPoint>>? pathHistory,
    List<int>? numberHistory,
    int? historyIndex,
  })  : _pathHistory = pathHistory ?? [currentPath],
        _numberHistory = numberHistory ?? [currentNumber],
        _historyIndex = historyIndex ?? 0;

  FlowConnectGameState copyWith({
    List<List<FlowConnectGridCell>>? grid,
    List<FlowConnectPathPoint>? currentPath,
    int? currentNumber,
    bool? isComplete,
    int? gridSize,
    int? totalNumbers,
    FlowConnectGameStatus? status,
    List<List<FlowConnectPathPoint>>? pathHistory,
    List<int>? numberHistory,
    int? historyIndex,
  }) {
    return FlowConnectGameState(
      grid: grid ?? this.grid,
      currentPath: currentPath ?? this.currentPath,
      currentNumber: currentNumber ?? this.currentNumber,
      isComplete: isComplete ?? this.isComplete,
      gridSize: gridSize ?? this.gridSize,
      totalNumbers: totalNumbers ?? this.totalNumbers,
      status: status ?? this.status,
      pathHistory: pathHistory ?? _pathHistory,
      numberHistory: numberHistory ?? _numberHistory,
      historyIndex: historyIndex ?? _historyIndex,
    );
  }

  // Methods for history management
  FlowConnectGameState recordState() {
    final newPathHistory = List<List<FlowConnectPathPoint>>.from(
        _pathHistory.sublist(0, _historyIndex + 1));
    final newNumberHistory =
        List<int>.from(_numberHistory.sublist(0, _historyIndex + 1));

    newPathHistory.add(currentPath);
    newNumberHistory.add(currentNumber);

    return copyWith(
      pathHistory: newPathHistory,
      numberHistory: newNumberHistory,
      historyIndex: newPathHistory.length - 1,
    );
  }

  FlowConnectGameState undo() {
    if (_historyIndex > 0) {
      final newIndex = _historyIndex - 1;
      return copyWith(
        currentPath: _pathHistory[newIndex],
        currentNumber: _numberHistory[newIndex],
        historyIndex: newIndex,
      );
    }
    return this;
  }

  FlowConnectGameState redo() {
    if (_historyIndex < _pathHistory.length - 1) {
      final newIndex = _historyIndex + 1;
      return copyWith(
        currentPath: _pathHistory[newIndex],
        currentNumber: _numberHistory[newIndex],
        historyIndex: newIndex,
      );
    }
    return this;
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _pathHistory.length - 1;

  FlowConnectGameState trimHistory() {
    if (_historyIndex < _pathHistory.length - 1) {
      final newPathHistory = List<List<FlowConnectPathPoint>>.from(
          _pathHistory.sublist(0, _historyIndex + 1));
      final newNumberHistory =
          List<int>.from(_numberHistory.sublist(0, _historyIndex + 1));
      return copyWith(
        pathHistory: newPathHistory,
        numberHistory: newNumberHistory,
        historyIndex: newPathHistory.length - 1,
      );
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowConnectGameState &&
          runtimeType == other.runtimeType &&
          listEquals(grid, other.grid) &&
          listEquals(currentPath, other.currentPath) &&
          currentNumber == other.currentNumber &&
          isComplete == other.isComplete &&
          gridSize == other.gridSize &&
          totalNumbers == other.totalNumbers &&
          status == other.status &&
          listEquals(_pathHistory, other._pathHistory) &&
          listEquals(_numberHistory, other._numberHistory) &&
          _historyIndex == other._historyIndex;

  @override
  int get hashCode =>
      grid.hashCode ^
      currentPath.hashCode ^
      currentNumber.hashCode ^
      isComplete.hashCode ^
      gridSize.hashCode ^
      totalNumbers.hashCode ^
      status.hashCode ^
      _pathHistory.hashCode ^
      _numberHistory.hashCode ^
      _historyIndex.hashCode;
}
