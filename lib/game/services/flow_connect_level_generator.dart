import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/flow_connect_grid_cell.dart';
import '../models/flow_connect_level_data.dart';
import '../models/flow_connect_path_point.dart';

enum FlowConnectDifficulty {
  easy,
  medium,
  hard,
}

class FlowConnectLevelGenerator {
  static FlowConnectLevelData generateLevel(
      int gridSize, FlowConnectDifficulty difficulty) {
    final path = _generateHamiltonianPath(gridSize);
    if (path.isEmpty) {
      if (kDebugMode) {
        print(
            "LevelGenerator: Hamiltonian path generation failed for grid size $gridSize");
      }
      return FlowConnectLevelData(
          grid: [], gridSize: gridSize, totalNumbers: 0, solutionPath: []);
    }

    int numberOfCheckpoints = (gridSize * gridSize / 5).toInt().clamp(4, 12);

    // Adjust based on difficulty
    switch (difficulty) {
      case FlowConnectDifficulty.easy:
        numberOfCheckpoints = (numberOfCheckpoints * 0.8).toInt().clamp(4, 12);
        break;
      case FlowConnectDifficulty.medium:
        // Use calculated value
        break;
      case FlowConnectDifficulty.hard:
        numberOfCheckpoints = (numberOfCheckpoints * 1.2).toInt().clamp(4, 12);
        break;
    }

    final checkpointIndices = _selectCheckpoints(path, numberOfCheckpoints);

    final grid = List.generate(
        gridSize,
        (row) => List.generate(
            gridSize, (col) => FlowConnectGridCell(row: row, col: col)));

    int numberCounter = 1;
    final Map<int, FlowConnectPathPoint> numberedPoints = {};

    for (int i = 0; i < path.length; i++) {
      if (checkpointIndices.contains(i)) {
        final point = path[i];
        grid[point.row][point.col] =
            grid[point.row][point.col].copyWith(number: numberCounter);
        numberedPoints[numberCounter] = point;
        numberCounter++;
      }
    }

    return FlowConnectLevelData(
      grid: grid,
      gridSize: gridSize,
      totalNumbers: numberCounter - 1,
      solutionPath: path,
    );
  }

  static List<FlowConnectPathPoint> _generateHamiltonianPath(int gridSize) {
    final random = Random();
    const int maxAttempts = 10; // Try a few times

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final startRow = random.nextInt(gridSize);
      final startCol = random.nextInt(gridSize);

      final path = <FlowConnectPathPoint>[];
      var visited =
          List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

      bool solve(int r, int c) {
        path.add(FlowConnectPathPoint(row: r, col: c, order: path.length));
        visited[r][c] = true;

        if (path.length == gridSize * gridSize) {
          return true;
        }

        final neighbors = [
          [r - 1, c],
          [r + 1, c],
          [r, c - 1],
          [r, c + 1]
        ]..shuffle(random);

        for (var n in neighbors) {
          final newR = n[0];
          final newC = n[1];

          if (newR >= 0 &&
              newR < gridSize &&
              newC >= 0 &&
              newC < gridSize &&
              !visited[newR][newC]) {
            if (solve(newR, newC)) {
              return true;
            }
          }
        }

        // Backtrack
        path.removeLast();
        visited[r][c] = false;
        return false;
      }

      if (solve(startRow, startCol)) {
        return path;
      }
    }

    if (kDebugMode) {
      print(
          "LevelGenerator: Failed to generate Hamiltonian path after $maxAttempts attempts.");
    }
    return []; // Still failed after multiple attempts
  }

  static List<int> _selectCheckpoints(
      List<FlowConnectPathPoint> path, int count) {
    final indices = <int>{};
    final pathLength = path.length;

    // Ensure first and last points are always checkpoints
    indices.add(0);
    if (pathLength > 1) {
      indices.add(pathLength - 1);
    }

    // Distribute remaining checkpoints more evenly
    final random = Random();
    final step =
        pathLength / (count - 1); // Calculate step for even distribution

    for (int i = 1; i < count - 1; i++) {
      int index = (i * step).toInt();
      // Add some randomness around the calculated step to make it less predictable
      index = (index +
              random.nextInt(step.toInt().clamp(1, pathLength ~/ 4)) -
              (step.toInt().clamp(1, pathLength ~/ 4) ~/ 2))
          .clamp(1, pathLength - 2);
      indices.add(index);
    }

    final sortedIndices = indices.toList()..sort();
    return sortedIndices;
  }
}
