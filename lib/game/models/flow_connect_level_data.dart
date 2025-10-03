import 'flow_connect_grid_cell.dart';
import 'flow_connect_path_point.dart';

class FlowConnectLevelData {
  final List<List<FlowConnectGridCell>> grid;
  final int gridSize;
  final int totalNumbers;
  final List<FlowConnectPathPoint> solutionPath;

  FlowConnectLevelData({
    required this.grid,
    required this.gridSize,
    required this.totalNumbers,
    required this.solutionPath,
  });
}