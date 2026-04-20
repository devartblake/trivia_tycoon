import '../../../game/models/flow_connect_path_point.dart';
import '../../../game/state/flow_connect_game_state.dart';

class FlowConnectHintSystem {
  static FlowConnectPathPoint? getNextHint(
      FlowConnectGameState state, List<FlowConnectPathPoint> solutionPath) {
    if (state.currentPath.isEmpty) {
      return solutionPath.first;
    }

    final lastUserPoint = state.currentPath.last;

    int currentIndexInSolution = -1;
    for (int i = 0; i < solutionPath.length; i++) {
      if (solutionPath[i].row == lastUserPoint.row &&
          solutionPath[i].col == lastUserPoint.col) {
        currentIndexInSolution = i;
        break;
      }
    }

    if (currentIndexInSolution != -1 &&
        currentIndexInSolution < solutionPath.length - 1) {
      return solutionPath[currentIndexInSolution + 1];
    }

    return null;
  }
}
