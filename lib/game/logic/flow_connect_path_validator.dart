import '../models/flow_connect_grid_cell.dart';
import '../models/flow_connect_path_point.dart';
import '../state/flow_connect_game_state.dart';

class FlowConnectPathValidator {
  static bool isValidPath(List<FlowConnectPathPoint> path, List<List<FlowConnectGridCell>> grid) {
    if (path.length < 2) return true;

    final visitedPoints = <String>{};
    for (final point in path) {
      final pointId = '${point.row}-${point.col}';
      if (visitedPoints.contains(pointId)) {
        return false;
      }
      visitedPoints.add(pointId);
    }

    int expectedNumber = 1;
    for (final point in path) {
      final cell = grid[point.row][point.col];
      if (cell.number != null) {
        if (cell.number == expectedNumber) {
          expectedNumber++;
        } else {
          if (cell.number! > expectedNumber) return false;
        }
      }
    }

    for (int i = 1; i < path.length; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final dx = (curr.col - prev.col).abs();
      final dy = (curr.row - prev.row).abs();
      if (dx + dy != 1) {
        return false;
      }
    }

    return true;
  }

  static bool checkWinCondition(FlowConnectGameState state) {
    final gridSize = state.gridSize;
    final totalCells = gridSize * gridSize;

    if (state.currentPath.length != totalCells) {
      return false;
    }

    int lastVisitedNumber = 0;
    for (final point in state.currentPath) {
      final cell = state.grid[point.row][point.col];
      if (cell.number != null) {
        if (cell.number == lastVisitedNumber + 1) {
          lastVisitedNumber = cell.number!;
        } else {
          return false;
        }
      }
    }

    if (lastVisitedNumber != state.totalNumbers) {
      return false;
    }

    return true;
  }
}