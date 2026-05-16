import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SkillNode _node({
  String id = 'node_1',
  String title = 'Test Node',
  String description = 'A test node',
  int tier = 0,
  int cost = 10,
  SkillCategory category = SkillCategory.scholar,
  Map<String, num> effects = const {},
  Duration? cooldown,
  DateTime? lastUsed,
  String? branchId,
  bool unlocked = false,
  bool available = false,
  SkillEffectType? effectType,
  double? effectValue,
  int? duration,
  String? effectTarget,
  String? effectTrigger,
}) {
  return SkillNode(
    id: id,
    title: title,
    description: description,
    tier: tier,
    cost: cost,
    category: category,
    effects: effects,
    cooldown: cooldown,
    lastUsed: lastUsed,
    branchId: branchId,
    unlocked: unlocked,
    available: available,
    effectType: effectType,
    effectValue: effectValue,
    duration: duration,
    effectTarget: effectTarget,
    effectTrigger: effectTrigger,
  );
}

SkillTreeGraph _graph({
  List<SkillNode> nodes = const [],
  List<SkillEdge> edges = const [],
}) =>
    SkillTreeGraph(nodes: nodes, edges: edges);

void main() {
  // -------------------------------------------------------------------------
  // SkillCategory — groupId / brandId
  // -------------------------------------------------------------------------

  group('SkillCategory — groupId', () {
    test('scholar is in combat_focused', () {
      expect(SkillCategory.scholar.groupId, 'combat_focused');
    });

    test('strategist is in combat_focused', () {
      expect(SkillCategory.strategist.groupId, 'combat_focused');
    });

    test('combat is in combat_focused', () {
      expect(SkillCategory.combat.groupId, 'combat_focused');
    });

    test('xp is in enhancement_branches', () {
      expect(SkillCategory.xp.groupId, 'enhancement_branches');
    });

    test('timer is in enhancement_branches', () {
      expect(SkillCategory.timer.groupId, 'enhancement_branches');
    });

    test('combo is in enhancement_branches', () {
      expect(SkillCategory.combo.groupId, 'enhancement_branches');
    });

    test('risk is in enhancement_branches', () {
      expect(SkillCategory.risk.groupId, 'enhancement_branches');
    });

    test('luck is in utility_branches', () {
      expect(SkillCategory.luck.groupId, 'utility_branches');
    });

    test('stealth is in utility_branches', () {
      expect(SkillCategory.stealth.groupId, 'utility_branches');
    });

    test('knowledge is in utility_branches', () {
      expect(SkillCategory.knowledge.groupId, 'utility_branches');
    });

    test('elite is in advanced_branches', () {
      expect(SkillCategory.elite.groupId, 'advanced_branches');
    });

    test('wildcard is in advanced_branches', () {
      expect(SkillCategory.wildcard.groupId, 'advanced_branches');
    });

    test('general is in advanced_branches', () {
      expect(SkillCategory.general.groupId, 'advanced_branches');
    });

    test('unknown falls through to unknown group', () {
      expect(SkillCategory.unknown.groupId, 'unknown');
    });

    test('category falls through to unknown group', () {
      expect(SkillCategory.category.groupId, 'unknown');
    });
  });

  group('SkillCategory — brandId', () {
    test('brandId equals enum name', () {
      for (final cat in SkillCategory.values) {
        expect(cat.brandId, cat.name);
      }
    });
  });

  // -------------------------------------------------------------------------
  // SkillNode.fromJson
  // -------------------------------------------------------------------------

  group('SkillNode.fromJson — basic fields', () {
    test('parses all scalar fields correctly', () {
      final json = {
        'id': 'n1',
        'title': 'Scholar Root',
        'description': 'Boost XP',
        'tier': 2,
        'cost': 50,
        'category': 'scholar',
        'branchId': 'scholar_branch',
        'unlocked': true,
        'available': true,
        'effectValue': 0.25,
        'duration': 30,
        'effectTarget': 'history',
        'effectTrigger': 'on_correct',
      };

      final node = SkillNode.fromJson(json);

      expect(node.id, 'n1');
      expect(node.title, 'Scholar Root');
      expect(node.description, 'Boost XP');
      expect(node.tier, 2);
      expect(node.cost, 50);
      expect(node.category, SkillCategory.scholar);
      expect(node.branchId, 'scholar_branch');
      expect(node.unlocked, isTrue);
      expect(node.available, isTrue);
      expect(node.effectValue, 0.25);
      expect(node.duration, 30);
      expect(node.effectTarget, 'history');
      expect(node.effectTrigger, 'on_correct');
    });

    test('defaults missing optional fields', () {
      final node = SkillNode.fromJson(
          {'id': 'x', 'title': '', 'description': '', 'tier': 0, 'cost': 0});

      expect(node.category, SkillCategory.unknown);
      expect(node.effects, isEmpty);
      expect(node.cooldown, isNull);
      expect(node.lastUsed, isNull);
      expect(node.branchId, isNull);
      expect(node.unlocked, isFalse);
      expect(node.available, isFalse);
      expect(node.effectType, isNull);
      expect(node.effectValue, isNull);
      expect(node.duration, isNull);
      expect(node.effectTarget, isNull);
      expect(node.effectTrigger, isNull);
    });

    test('defaults id and title to empty string when missing from json', () {
      final node = SkillNode.fromJson({});
      expect(node.id, '');
      expect(node.title, '');
    });
  });

  group('SkillNode.fromJson — category parsing', () {
    test('parses each known category name', () {
      for (final cat in SkillCategory.values) {
        if (cat == SkillCategory.unknown) continue;
        final node = SkillNode.fromJson({'category': cat.name});
        expect(node.category, cat, reason: 'failed for ${cat.name}');
      }
    });

    test('falls back to unknown for unrecognised category string', () {
      final node = SkillNode.fromJson({'category': 'not_a_real_category'});
      expect(node.category, SkillCategory.unknown);
    });

    test('falls back to unknown when category key is absent', () {
      final node = SkillNode.fromJson({});
      expect(node.category, SkillCategory.unknown);
    });
  });

  group('SkillNode.fromJson — effectType parsing', () {
    test('parses xpBoost effectType', () {
      final node = SkillNode.fromJson({'effectType': 'xpBoost'});
      expect(node.effectType, SkillEffectType.xpBoost);
    });

    test('parses doublePoints effectType', () {
      final node = SkillNode.fromJson({'effectType': 'doublePoints'});
      expect(node.effectType, SkillEffectType.doublePoints);
    });

    test('falls back to custom for unknown effectType string', () {
      final node = SkillNode.fromJson({'effectType': 'mystery_effect'});
      expect(node.effectType, SkillEffectType.custom);
    });

    test('effectType is null when key is absent', () {
      final node = SkillNode.fromJson({});
      expect(node.effectType, isNull);
    });
  });

  group('SkillNode.fromJson — cooldown parsing', () {
    test('parses cooldown from milliseconds', () {
      final node = SkillNode.fromJson({'cooldown': 60000});
      expect(node.cooldown, const Duration(minutes: 1));
    });

    test('cooldown is null when key is absent', () {
      final node = SkillNode.fromJson({});
      expect(node.cooldown, isNull);
    });
  });

  group('SkillNode.fromJson — effects map parsing', () {
    test('parses numeric effect values', () {
      final node = SkillNode.fromJson({
        'effects': {'timeBonusSec': 5, 'scoreBoost': 0.1},
      });
      expect(node.effects['timeBonusSec'], 5);
      expect(node.effects['scoreBoost'], 0.1);
    });

    test('converts bool effects: true → 1, false → 0', () {
      final node = SkillNode.fromJson({
        'effects': {'active': true, 'disabled': false},
      });
      expect(node.effects['active'], 1);
      expect(node.effects['disabled'], 0);
    });

    test('empty effects map when key is absent', () {
      final node = SkillNode.fromJson({});
      expect(node.effects, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SkillNode.copyWith
  // -------------------------------------------------------------------------

  group('SkillNode.copyWith', () {
    test('copies unlocked flag', () {
      final node = _node(unlocked: false);
      final updated = node.copyWith(unlocked: true);
      expect(updated.unlocked, isTrue);
      expect(node.unlocked, isFalse); // original unchanged
    });

    test('copies available flag', () {
      final node = _node(available: false);
      final updated = node.copyWith(available: true);
      expect(updated.available, isTrue);
    });

    test('copies lastUsed', () {
      final ts = DateTime(2025, 1, 1);
      final node = _node();
      final updated = node.copyWith(lastUsed: ts);
      expect(updated.lastUsed, ts);
      expect(node.lastUsed, isNull);
    });

    test('preserves all other fields', () {
      final node = _node(
        id: 'abc',
        title: 'T',
        tier: 3,
        cost: 99,
        category: SkillCategory.elite,
        branchId: 'elite_branch',
      );
      final updated = node.copyWith(unlocked: true);
      expect(updated.id, 'abc');
      expect(updated.title, 'T');
      expect(updated.tier, 3);
      expect(updated.cost, 99);
      expect(updated.category, SkillCategory.elite);
      expect(updated.branchId, 'elite_branch');
    });
  });

  // -------------------------------------------------------------------------
  // SkillNodeCooldown extension
  // -------------------------------------------------------------------------

  group('SkillNodeCooldown — isOnCooldown', () {
    test('false when cooldown is null', () {
      final node = _node(cooldown: null, lastUsed: DateTime.now());
      expect(node.isOnCooldown, isFalse);
    });

    test('false when lastUsed is null', () {
      final node = _node(cooldown: const Duration(minutes: 5), lastUsed: null);
      expect(node.isOnCooldown, isFalse);
    });

    test('true when used recently within cooldown window', () {
      final node = _node(
        cooldown: const Duration(hours: 1),
        lastUsed: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(node.isOnCooldown, isTrue);
    });

    test('false when cooldown has expired', () {
      final node = _node(
        cooldown: const Duration(minutes: 5),
        lastUsed: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(node.isOnCooldown, isFalse);
    });
  });

  group('SkillNodeCooldown — remainingCooldown', () {
    test('returns null when not on cooldown', () {
      final node = _node(cooldown: null, lastUsed: null);
      expect(node.remainingCooldown, isNull);
    });

    test('returns positive duration when on cooldown', () {
      final node = _node(
        cooldown: const Duration(hours: 1),
        lastUsed: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final remaining = node.remainingCooldown;
      expect(remaining, isNotNull);
      expect(remaining!.inMinutes, greaterThan(40));
      expect(remaining.inMinutes, lessThanOrEqualTo(50));
    });
  });

  group('SkillNodeCooldown — canUse', () {
    test('true when unlocked and not on cooldown', () {
      final node = _node(unlocked: true, cooldown: null);
      expect(node.canUse, isTrue);
    });

    test('false when not unlocked', () {
      final node = _node(unlocked: false, cooldown: null);
      expect(node.canUse, isFalse);
    });

    test('false when on cooldown', () {
      final node = _node(
        unlocked: true,
        cooldown: const Duration(hours: 1),
        lastUsed: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(node.canUse, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SkillEdge
  // -------------------------------------------------------------------------

  group('SkillEdge', () {
    test('fromJson parses fromId and toId', () {
      final edge = SkillEdge.fromJson({'fromId': 'a', 'toId': 'b'});
      expect(edge.fromId, 'a');
      expect(edge.toId, 'b');
    });

    test('fromJson defaults to empty string for missing keys', () {
      final edge = SkillEdge.fromJson({});
      expect(edge.fromId, '');
      expect(edge.toId, '');
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph — computed properties
  // -------------------------------------------------------------------------

  group('SkillTreeGraph — byId', () {
    test('returns a map keyed by node id', () {
      final n1 = _node(id: 'n1');
      final n2 = _node(id: 'n2');
      final graph = _graph(nodes: [n1, n2]);

      final byId = graph.byId;
      expect(byId['n1'], same(n1));
      expect(byId['n2'], same(n2));
    });

    test('empty graph returns empty map', () {
      expect(_graph().byId, isEmpty);
    });
  });

  group('SkillTreeGraph — tier', () {
    test('filters nodes by tier number', () {
      final t0 = _node(id: 'a', tier: 0);
      final t1a = _node(id: 'b', tier: 1);
      final t1b = _node(id: 'c', tier: 1);
      final t2 = _node(id: 'd', tier: 2);
      final graph = _graph(nodes: [t0, t1a, t1b, t2]);

      expect(graph.tier(1).map((n) => n.id).toSet(), {'b', 'c'});
      expect(graph.tier(0).map((n) => n.id).toSet(), {'a'});
      expect(graph.tier(2).map((n) => n.id).toSet(), {'d'});
      expect(graph.tier(99), isEmpty);
    });
  });

  group('SkillTreeGraph — maxTier', () {
    test('returns 0 for empty graph', () {
      expect(_graph().maxTier, 0);
    });

    test('returns highest tier value among nodes', () {
      final graph = _graph(nodes: [
        _node(id: 'a', tier: 0),
        _node(id: 'b', tier: 3),
        _node(id: 'c', tier: 1),
      ]);
      expect(graph.maxTier, 3);
    });
  });

  group('SkillTreeGraph — getNodeById', () {
    test('returns node when id matches', () {
      final node = _node(id: 'target');
      final graph = _graph(nodes: [node]);
      expect(graph.getNodeById('target'), same(node));
    });

    test('returns null when id is not found', () {
      final graph = _graph(nodes: [_node(id: 'x')]);
      expect(graph.getNodeById('missing'), isNull);
    });

    test('returns null for empty graph', () {
      expect(_graph().getNodeById('any'), isNull);
    });
  });

  group('SkillTreeGraph — nodesInGroup', () {
    test('returns nodes whose category maps to the given groupId', () {
      final scholar = _node(id: 's', category: SkillCategory.scholar);
      final xp = _node(id: 'x', category: SkillCategory.xp);
      final luck = _node(id: 'l', category: SkillCategory.luck);
      final graph = _graph(nodes: [scholar, xp, luck]);

      final combat = graph.nodesInGroup('combat_focused').toList();
      expect(combat.length, 1);
      expect(combat.first.id, 's');

      final enhancement = graph.nodesInGroup('enhancement_branches').toList();
      expect(enhancement.first.id, 'x');
    });
  });

  group('SkillTreeGraph — nodesInBranch', () {
    test('returns nodes with matching category', () {
      final a = _node(id: 'a', category: SkillCategory.timer);
      final b = _node(id: 'b', category: SkillCategory.timer);
      final c = _node(id: 'c', category: SkillCategory.luck);
      final graph = _graph(nodes: [a, b, c]);

      final timerNodes = graph.nodesInBranch(SkillCategory.timer).toList();
      expect(timerNodes.length, 2);
      expect(timerNodes.map((n) => n.id).toSet(), {'a', 'b'});
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph — canUnlock / prerequisites / dependents
  // -------------------------------------------------------------------------

  group('SkillTreeGraph — canUnlock', () {
    test('returns false for non-existent node', () {
      expect(_graph().canUnlock('ghost'), isFalse);
    });

    test('returns false for already-unlocked node', () {
      final node = _node(id: 'n', unlocked: true);
      expect(_graph(nodes: [node]).canUnlock('n'), isFalse);
    });

    test('returns true when node has no prerequisites', () {
      final node = _node(id: 'n', unlocked: false);
      expect(_graph(nodes: [node]).canUnlock('n'), isTrue);
    });

    test('returns false when a prerequisite is not unlocked', () {
      final prereq = _node(id: 'pre', unlocked: false);
      final target = _node(id: 'tgt', unlocked: false);
      final graph = _graph(
        nodes: [prereq, target],
        edges: [const SkillEdge(fromId: 'pre', toId: 'tgt')],
      );
      expect(graph.canUnlock('tgt'), isFalse);
    });

    test('returns true when all prerequisites are unlocked', () {
      final prereq = _node(id: 'pre', unlocked: true);
      final target = _node(id: 'tgt', unlocked: false);
      final graph = _graph(
        nodes: [prereq, target],
        edges: [const SkillEdge(fromId: 'pre', toId: 'tgt')],
      );
      expect(graph.canUnlock('tgt'), isTrue);
    });

    test('returns false when only some prerequisites are unlocked', () {
      final pre1 = _node(id: 'p1', unlocked: true);
      final pre2 = _node(id: 'p2', unlocked: false);
      final target = _node(id: 'tgt', unlocked: false);
      final graph = _graph(
        nodes: [pre1, pre2, target],
        edges: [
          const SkillEdge(fromId: 'p1', toId: 'tgt'),
          const SkillEdge(fromId: 'p2', toId: 'tgt'),
        ],
      );
      expect(graph.canUnlock('tgt'), isFalse);
    });
  });

  group('SkillTreeGraph — getPrerequisites', () {
    test('returns empty list when node has no incoming edges', () {
      final graph = _graph(nodes: [_node(id: 'n')]);
      expect(graph.getPrerequisites('n'), isEmpty);
    });

    test('returns list of prerequisite ids', () {
      final graph = _graph(
        nodes: [_node(id: 'a'), _node(id: 'b'), _node(id: 'c')],
        edges: [
          const SkillEdge(fromId: 'a', toId: 'c'),
          const SkillEdge(fromId: 'b', toId: 'c'),
        ],
      );
      expect(graph.getPrerequisites('c'), containsAll(['a', 'b']));
    });
  });

  group('SkillTreeGraph — getDependents', () {
    test('returns empty list when node has no outgoing edges', () {
      final graph = _graph(nodes: [_node(id: 'n')]);
      expect(graph.getDependents('n'), isEmpty);
    });

    test('returns list of dependent ids', () {
      final graph = _graph(
        nodes: [_node(id: 'a'), _node(id: 'b'), _node(id: 'c')],
        edges: [
          const SkillEdge(fromId: 'a', toId: 'b'),
          const SkillEdge(fromId: 'a', toId: 'c'),
        ],
      );
      expect(graph.getDependents('a'), containsAll(['b', 'c']));
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph — availableNodes / unlockedNodes
  // -------------------------------------------------------------------------

  group('SkillTreeGraph — availableNodes', () {
    test('returns nodes whose prerequisites are all met', () {
      final prereq = _node(id: 'pre', unlocked: true);
      final available = _node(id: 'avail', unlocked: false);
      final locked = _node(id: 'locked', unlocked: false);
      final graph = _graph(
        nodes: [prereq, available, locked],
        edges: [
          const SkillEdge(fromId: 'pre', toId: 'avail'),
          // locked has no prereq edge → canUnlock returns true for it too
        ],
      );
      final avail = graph.availableNodes.map((n) => n.id).toSet();
      // Both 'avail' (prereq met) and 'locked' (no prereqs → can unlock) are available.
      expect(avail, containsAll(['avail', 'locked']));
      // 'pre' is already unlocked so it's not in availableNodes.
      expect(avail, isNot(contains('pre')));
    });
  });

  group('SkillTreeGraph — unlockedNodes', () {
    test('returns only unlocked nodes', () {
      final u = _node(id: 'u', unlocked: true);
      final l = _node(id: 'l', unlocked: false);
      final graph = _graph(nodes: [u, l]);
      expect(graph.unlockedNodes.map((n) => n.id).toList(), ['u']);
    });

    test('returns empty when no nodes are unlocked', () {
      final graph = _graph(nodes: [_node(id: 'a'), _node(id: 'b')]);
      expect(graph.unlockedNodes, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph — withUnlockedIds
  // -------------------------------------------------------------------------

  group('SkillTreeGraph — withUnlockedIds', () {
    test('returns same graph when set is empty', () {
      final graph = _graph(nodes: [_node(id: 'n')]);
      expect(graph.withUnlockedIds({}), same(graph));
    });

    test('marks target node as unlocked and available', () {
      final node = _node(id: 'n', unlocked: false, available: false);
      final graph = _graph(nodes: [node]);
      final updated = graph.withUnlockedIds({'n'});

      final updatedNode = updated.getNodeById('n')!;
      expect(updatedNode.unlocked, isTrue);
      expect(updatedNode.available, isTrue);
    });

    test('marks direct dependents as available', () {
      final root = _node(id: 'root');
      final child = _node(id: 'child', available: false);
      final graph = _graph(
        nodes: [root, child],
        edges: [const SkillEdge(fromId: 'root', toId: 'child')],
      );
      final updated = graph.withUnlockedIds({'root'});

      final updatedChild = updated.getNodeById('child')!;
      expect(updatedChild.available, isTrue);
      expect(updatedChild.unlocked, isFalse);
    });

    test('silently ignores ids not present in graph', () {
      final node = _node(id: 'existing');
      final graph = _graph(nodes: [node]);
      // Should not throw
      final updated = graph.withUnlockedIds({'existing', 'ghost_id'});
      expect(updated.getNodeById('existing')!.unlocked, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph.fromJson
  // -------------------------------------------------------------------------

  group('SkillTreeGraph.fromJson', () {
    test('parses nodes and edges from flat JSON', () {
      final json = {
        'nodes': [
          {
            'id': 'a',
            'title': 'A',
            'description': '',
            'tier': 0,
            'cost': 5,
            'category': 'luck'
          },
          {
            'id': 'b',
            'title': 'B',
            'description': '',
            'tier': 1,
            'cost': 10,
            'category': 'risk'
          },
        ],
        'edges': [
          {'fromId': 'a', 'toId': 'b'},
        ],
      };

      final graph = SkillTreeGraph.fromJson(json);

      expect(graph.nodes.length, 2);
      expect(graph.edges.length, 1);
      expect(graph.nodes[0].id, 'a');
      expect(graph.nodes[1].category, SkillCategory.risk);
      expect(graph.edges[0].fromId, 'a');
      expect(graph.edges[0].toId, 'b');
    });

    test('handles missing nodes/edges keys gracefully', () {
      final graph = SkillTreeGraph.fromJson({});
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraphBranch extension
  // -------------------------------------------------------------------------

  group('SkillTreeGraphBranch — subgraphForBranch', () {
    test('returns subgraph containing only matching branch nodes and edges',
        () {
      final a = _node(id: 'a', branchId: 'scholar');
      final b = _node(id: 'b', branchId: 'scholar');
      final c = _node(id: 'c', branchId: 'strategist');
      final graph = _graph(
        nodes: [a, b, c],
        edges: [
          const SkillEdge(fromId: 'a', toId: 'b'),
          const SkillEdge(fromId: 'b', toId: 'c'), // cross-branch — excluded
        ],
      );

      final sub = graph.subgraphForBranch('scholar');
      expect(sub.nodes.map((n) => n.id).toSet(), {'a', 'b'});
      expect(sub.edges.length, 1);
      expect(sub.edges.first.toId, 'b');
    });
  });

  group('SkillTreeGraphBranch — indegree / neighbors', () {
    test('indegree returns number of incoming edges', () {
      final graph = _graph(
        nodes: [_node(id: 'a'), _node(id: 'b'), _node(id: 'c')],
        edges: [
          const SkillEdge(fromId: 'a', toId: 'c'),
          const SkillEdge(fromId: 'b', toId: 'c'),
        ],
      );
      expect(graph.indegree('c'), 2);
      expect(graph.indegree('a'), 0);
    });

    test('neighbors returns ids of nodes connected via outgoing edges', () {
      final graph = _graph(
        nodes: [_node(id: 'a'), _node(id: 'b'), _node(id: 'c')],
        edges: [
          const SkillEdge(fromId: 'a', toId: 'b'),
          const SkillEdge(fromId: 'a', toId: 'c'),
        ],
      );
      expect(graph.neighbors('a').toSet(), {'b', 'c'});
      expect(graph.neighbors('b'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGraph.copy
  // -------------------------------------------------------------------------

  group('SkillTreeGraph.copy', () {
    test('copy produces independent node list', () {
      final node = _node(id: 'n', unlocked: false);
      final graph = _graph(nodes: [node]);
      final copied = graph.copy();

      // Mutate original node list indirectly via copyWith on copied graph's node
      copied.nodes.first.unlocked = true;

      // Original graph node should still be false
      expect(graph.nodes.first.unlocked, isFalse);
    });
  });
}
