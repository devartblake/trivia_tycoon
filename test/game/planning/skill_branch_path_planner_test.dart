import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/planning/skill_branch_path_planner.dart';

void main() {
  group('SkillBranchPathPlanner.computeRecommendedPath', () {
    test('returns weighted topological order for a DAG', () {
      const edges = [
        SkillEdge(fromId: 'a', toId: 'c'),
        SkillEdge(fromId: 'b', toId: 'c'),
      ];

      final planner = SkillBranchPathPlanner(
        const SkillTreeGraph(nodes: [], edges: edges),
      );

      final order = planner.computeRecommendedPath(
        branchNodeIds: {'a', 'b', 'c'},
        edges: edges,
        weightByNodeId: const {'a': 1, 'b': 5, 'c': 2},
      );

      expect(order, ['b', 'a', 'c']);
    });

    test('falls back to weighted order for cyclic remainder', () {
      const edges = [
        SkillEdge(fromId: 'a', toId: 'b'),
        SkillEdge(fromId: 'b', toId: 'a'),
      ];

      final planner = SkillBranchPathPlanner(
        const SkillTreeGraph(nodes: [], edges: edges),
      );

      final order = planner.computeRecommendedPath(
        branchNodeIds: {'a', 'b', 'c'},
        edges: edges,
        weightByNodeId: const {'a': 10, 'b': 3, 'c': 1},
      );

      expect(order.toSet(), {'a', 'b', 'c'});
      expect(order.first, 'c');
      expect(order.indexOf('a'), lessThan(order.indexOf('b')));
    });
  });
}
