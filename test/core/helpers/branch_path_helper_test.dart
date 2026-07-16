import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/helpers/branch_path_helper.dart';
import 'package:synaptix/game/models/skill_tree_graph.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SkillNode _node({
  required String id,
  int tier = 0,
  int cost = 10,
  String? branchId,
  Map<String, num> effects = const {},
}) =>
    SkillNode(
      id: id,
      title: 'Node $id',
      description: 'desc',
      tier: tier,
      cost: cost,
      category: SkillCategory.general,
      effects: effects,
      branchId: branchId,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // getNodeDisplayPriority
  // -------------------------------------------------------------------------

  group('BranchPathHelper.getNodeDisplayPriority', () {
    test('priority = tier * 1000 + cost', () {
      final node = _node(id: 'n1', tier: 2, cost: 50);
      expect(BranchPathHelper.getNodeDisplayPriority(node), 2050);
    });

    test('tier 0, cost 5 → 5', () {
      final node = _node(id: 'n2', tier: 0, cost: 5);
      expect(BranchPathHelper.getNodeDisplayPriority(node), 5);
    });

    test('tier 1, cost 0 → 1000', () {
      final node = _node(id: 'n3', tier: 1, cost: 0);
      expect(BranchPathHelper.getNodeDisplayPriority(node), 1000);
    });

    test('higher tier always produces higher priority than lower tier', () {
      final low = _node(id: 'a', tier: 1, cost: 999);
      final high = _node(id: 'b', tier: 2, cost: 0);
      expect(
        BranchPathHelper.getNodeDisplayPriority(high),
        greaterThan(BranchPathHelper.getNodeDisplayPriority(low)),
      );
    });
  });

  // -------------------------------------------------------------------------
  // isOnCriticalPath
  // -------------------------------------------------------------------------

  group('BranchPathHelper.isOnCriticalPath', () {
    // 10 nodes — first 7 (indices 0–6) are critical (70%)
    late List<SkillNode> ordered;

    setUp(() {
      ordered = List.generate(10, (i) => _node(id: 'n$i', tier: i));
    });

    test('node at index 0 is on critical path', () {
      expect(BranchPathHelper.isOnCriticalPath(ordered[0], ordered), isTrue);
    });

    test('node at index 6 is on critical path (first 70%)', () {
      expect(BranchPathHelper.isOnCriticalPath(ordered[6], ordered), isTrue);
    });

    test('node at index 7 is NOT on critical path', () {
      expect(BranchPathHelper.isOnCriticalPath(ordered[7], ordered), isFalse);
    });

    test('node not in list returns false', () {
      final outside = _node(id: 'outside');
      expect(BranchPathHelper.isOnCriticalPath(outside, ordered), isFalse);
    });

    test('single-node list: that node is on critical path', () {
      final single = [_node(id: 's1', tier: 0)];
      expect(BranchPathHelper.isOnCriticalPath(single[0], single), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getNodeWeight
  // -------------------------------------------------------------------------

  group('BranchPathHelper.getNodeWeight', () {
    test('uses effects["weight"] when present', () {
      final node = _node(id: 'n1', tier: 3, effects: {'weight': 42});
      expect(BranchPathHelper.getNodeWeight(node), 42.0);
    });

    test('fallback = 100 - tier when no "weight" effect', () {
      final node = _node(id: 'n2', tier: 10);
      expect(BranchPathHelper.getNodeWeight(node), 90.0);
    });

    test('tier 0 → fallback weight = 100', () {
      final node = _node(id: 'n3', tier: 0);
      expect(BranchPathHelper.getNodeWeight(node), 100.0);
    });

    test('effects weight of 0 is used (not treated as falsy)', () {
      final node = _node(id: 'n4', tier: 5, effects: {'weight': 0});
      expect(BranchPathHelper.getNodeWeight(node), 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // computeRecommendedOrderForBranch
  // -------------------------------------------------------------------------

  group('BranchPathHelper.computeRecommendedOrderForBranch', () {
    test('empty graph returns empty list', () {
      final graph = const SkillTreeGraph(nodes: [], edges: []);
      expect(
        BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic'),
        isEmpty,
      );
    });

    test('no nodes matching branchId returns empty list', () {
      final graph = SkillTreeGraph(
        nodes: [_node(id: 'a', branchId: 'other')],
        edges: const [],
      );
      expect(
        BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic'),
        isEmpty,
      );
    });

    test('single matching node is returned', () {
      final graph = SkillTreeGraph(
        nodes: [_node(id: 'a1', branchId: 'logic', tier: 0)],
        edges: const [],
      );
      final result =
          BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic');
      expect(result.length, 1);
      expect(result[0].id, 'a1');
    });

    test('nodes sorted by tier (lower tier first) when no edges', () {
      final graph = SkillTreeGraph(
        nodes: [
          _node(id: 'high', branchId: 'logic', tier: 2, cost: 5),
          _node(id: 'low', branchId: 'logic', tier: 0, cost: 5),
          _node(id: 'mid', branchId: 'logic', tier: 1, cost: 5),
        ],
        edges: const [],
      );
      final result =
          BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic');
      expect(result.length, 3);
      expect(result[0].tier, lessThanOrEqualTo(result[1].tier));
      expect(result[1].tier, lessThanOrEqualTo(result[2].tier));
    });

    test('within same tier, lower cost comes first', () {
      final graph = SkillTreeGraph(
        nodes: [
          _node(id: 'expensive', branchId: 'logic', tier: 1, cost: 100),
          _node(id: 'cheap', branchId: 'logic', tier: 1, cost: 10),
        ],
        edges: const [],
      );
      final result =
          BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic');
      expect(result[0].id, 'cheap');
    });

    test('matches by node.id prefix', () {
      final graph = SkillTreeGraph(
        nodes: [_node(id: 'logic_01', branchId: null, tier: 0)],
        edges: const [],
      );
      final result =
          BranchPathHelper.computeRecommendedOrderForBranch(graph, 'logic');
      expect(result.length, 1);
    });
  });
}
