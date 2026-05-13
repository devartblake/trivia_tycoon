import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/skill_tree_nav_models.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';

void main() {
  // -------------------------------------------------------------------------
  // parseGroupId
  // -------------------------------------------------------------------------

  group('parseGroupId', () {
    test('"combat" → combat', () {
      expect(parseGroupId('combat'), SkillTreeGroupId.combat);
    });

    test('"combat-focused" → combat', () {
      expect(parseGroupId('combat-focused'), SkillTreeGroupId.combat);
    });

    test('"combat_focused" → combat', () {
      expect(parseGroupId('combat_focused'), SkillTreeGroupId.combat);
    });

    test('case-insensitive: "COMBAT" → combat', () {
      expect(parseGroupId('COMBAT'), SkillTreeGroupId.combat);
    });

    test('"enhancement" → enhancement', () {
      expect(parseGroupId('enhancement'), SkillTreeGroupId.enhancement);
    });

    test('"utility" → utility', () {
      expect(parseGroupId('utility'), SkillTreeGroupId.utility);
    });

    test('"advanced" → advanced', () {
      expect(parseGroupId('advanced'), SkillTreeGroupId.advanced);
    });

    test('unknown string falls back to utility', () {
      expect(parseGroupId('unknown_group'), SkillTreeGroupId.utility);
    });

    test('empty string falls back to utility', () {
      expect(parseGroupId(''), SkillTreeGroupId.utility);
    });
  });

  // -------------------------------------------------------------------------
  // groupAccent
  // -------------------------------------------------------------------------

  group('groupAccent', () {
    test('combat → red 0xFFFF4444', () {
      expect(groupAccent(SkillTreeGroupId.combat), const Color(0xFFFF4444));
    });

    test('enhancement → orange 0xFFF39C12', () {
      expect(
          groupAccent(SkillTreeGroupId.enhancement), const Color(0xFFF39C12));
    });

    test('utility → purple 0xFF8E44AD', () {
      expect(groupAccent(SkillTreeGroupId.utility), const Color(0xFF8E44AD));
    });

    test('advanced → gold 0xFFFFD700', () {
      expect(groupAccent(SkillTreeGroupId.advanced), const Color(0xFFFFD700));
    });
  });

  // -------------------------------------------------------------------------
  // branchIdToCategory
  // -------------------------------------------------------------------------

  group('branchIdToCategory', () {
    test('"scholar" → SkillCategory.scholar', () {
      expect(branchIdToCategory('scholar'), SkillCategory.scholar);
    });

    test('"strategist" → SkillCategory.strategist', () {
      expect(branchIdToCategory('strategist'), SkillCategory.strategist);
    });

    test('"combat" → SkillCategory.combat', () {
      expect(branchIdToCategory('combat'), SkillCategory.combat);
    });

    test('"xp" → SkillCategory.xp', () {
      expect(branchIdToCategory('xp'), SkillCategory.xp);
    });

    test('"timer" → SkillCategory.timer', () {
      expect(branchIdToCategory('timer'), SkillCategory.timer);
    });

    test('"combo" → SkillCategory.combo', () {
      expect(branchIdToCategory('combo'), SkillCategory.combo);
    });

    test('"risk" → SkillCategory.risk', () {
      expect(branchIdToCategory('risk'), SkillCategory.risk);
    });

    test('"luck" → SkillCategory.luck', () {
      expect(branchIdToCategory('luck'), SkillCategory.luck);
    });

    test('"stealth" → SkillCategory.stealth', () {
      expect(branchIdToCategory('stealth'), SkillCategory.stealth);
    });

    test('"knowledge" → SkillCategory.knowledge', () {
      expect(branchIdToCategory('knowledge'), SkillCategory.knowledge);
    });

    test('"elite" → SkillCategory.elite', () {
      expect(branchIdToCategory('elite'), SkillCategory.elite);
    });

    test('"wildcard" → SkillCategory.wildcard', () {
      expect(branchIdToCategory('wildcard'), SkillCategory.wildcard);
    });

    test('"general" → SkillCategory.general', () {
      expect(branchIdToCategory('general'), SkillCategory.general);
    });

    test('unknown branchId falls back to unknown', () {
      expect(branchIdToCategory('nonexistent'), SkillCategory.unknown);
    });

    test('case-insensitive: "Scholar" → scholar', () {
      expect(branchIdToCategory('Scholar'), SkillCategory.scholar);
    });
  });

  // -------------------------------------------------------------------------
  // SkillBranchVM — computed properties
  // -------------------------------------------------------------------------

  group('SkillBranchVM — computed properties', () {
    SkillBranchVM _makeBranch(List<Map<String, dynamic>> nodeMaps) =>
        SkillBranchVM(
          branchId: 'scholar',
          groupId: SkillTreeGroupId.enhancement,
          title: 'Scholar',
          description: 'Knowledge skills',
          accent: Colors.blue,
          colorHex: '#3B82F6',
          nodeMaps: nodeMaps,
        );

    test('totalNodes returns node count', () {
      final vm = _makeBranch([
        {'id': 'n1'},
        {'id': 'n2'},
        {'id': 'n3'},
      ]);
      expect(vm.totalNodes, 3);
    });

    test('totalNodes is 0 for empty list', () {
      expect(_makeBranch([]).totalNodes, 0);
    });

    test('unlockedCount counts only unlocked nodes', () {
      final vm = _makeBranch([
        {'id': 'n1', 'unlocked': true},
        {'id': 'n2', 'unlocked': false},
        {'id': 'n3', 'unlocked': true},
      ]);
      expect(vm.unlockedCount, 2);
    });

    test('unlockedCount treats missing unlocked as false', () {
      final vm = _makeBranch([
        {'id': 'n1'},
        {'id': 'n2', 'unlocked': true},
      ]);
      expect(vm.unlockedCount, 1);
    });

    test('progress is 0 when no nodes', () {
      expect(_makeBranch([]).progress, 0.0);
    });

    test('progress is correct fraction', () {
      final vm = _makeBranch([
        {'id': 'n1', 'unlocked': true},
        {'id': 'n2', 'unlocked': false},
      ]);
      expect(vm.progress, closeTo(0.5, 0.001));
    });

    test('progress is 1.0 when all unlocked', () {
      final vm = _makeBranch([
        {'id': 'n1', 'unlocked': true},
        {'id': 'n2', 'unlocked': true},
      ]);
      expect(vm.progress, closeTo(1.0, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // SkillBranchVM.toGraph — basic structure
  // -------------------------------------------------------------------------

  group('SkillBranchVM.toGraph — basic structure', () {
    SkillBranchVM _makeBranch({
      required List<Map<String, dynamic>> nodeMaps,
      String branchId = 'scholar',
    }) =>
        SkillBranchVM(
          branchId: branchId,
          groupId: SkillTreeGroupId.enhancement,
          title: 'Test Branch',
          description: '',
          accent: Colors.green,
          colorHex: '#10B981',
          nodeMaps: nodeMaps,
        );

    test('returns SkillTreeGraph with correct node count', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'a', 'title': 'Node A', 'cost': 1},
        {'id': 'b', 'title': 'Node B', 'cost': 2},
      ]);
      final graph = vm.toGraph();
      expect(graph.nodes.length, 2);
    });

    test('empty nodeMaps → empty graph', () {
      final graph = _makeBranch(nodeMaps: []).toGraph();
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });

    test('node titles and IDs are set correctly', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'scholar_root', 'title': 'Scholar Root', 'cost': 3},
      ]);
      final graph = vm.toGraph();
      final node = graph.nodes.first;
      expect(node.id, 'scholar_root');
      expect(node.title, 'Scholar Root');
      expect(node.cost, 3);
    });

    test('node title falls back to id when absent', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'fallback_node'},
      ]);
      final graph = vm.toGraph();
      expect(graph.nodes.first.title, 'fallback_node');
    });

    test('node unlocked flag is preserved', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'n1', 'unlocked': true},
        {'id': 'n2', 'unlocked': false},
      ]);
      final graph = vm.toGraph();
      expect(graph.nodes.firstWhere((n) => n.id == 'n1').unlocked, isTrue);
      expect(graph.nodes.firstWhere((n) => n.id == 'n2').unlocked, isFalse);
    });

    test('category assigned from branchId', () {
      final vm = _makeBranch(
        nodeMaps: [{'id': 'n1'}],
        branchId: 'combat',
      );
      final graph = vm.toGraph();
      expect(graph.nodes.first.category, SkillCategory.combat);
    });

    test('edges created from requires field', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'root'},
        {'id': 'child', 'requires': ['root']},
      ]);
      final graph = vm.toGraph();
      expect(graph.edges.length, 1);
      expect(graph.edges.first.fromId, 'root');
      expect(graph.edges.first.toId, 'child');
    });

    test('multiple requires create multiple edges', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c', 'requires': ['a', 'b']},
      ]);
      final graph = vm.toGraph();
      expect(graph.edges.length, 2);
    });

    test('no requires → no edges', () {
      final vm = _makeBranch(nodeMaps: [
        {'id': 'a'},
        {'id': 'b'},
      ]);
      expect(vm.toGraph().edges, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SkillBranchVM.toGraph — tier assignment via DFS
  // -------------------------------------------------------------------------

  group('SkillBranchVM.toGraph — tier assignment', () {
    SkillBranchVM _makeBranch(List<Map<String, dynamic>> nodeMaps) =>
        SkillBranchVM(
          branchId: 'xp',
          groupId: SkillTreeGroupId.utility,
          title: 'XP',
          description: '',
          accent: Colors.purple,
          colorHex: '#8E44AD',
          nodeMaps: nodeMaps,
        );

    SkillTreeGraph _graph(List<Map<String, dynamic>> maps) =>
        _makeBranch(maps).toGraph();

    SkillNode _node(SkillTreeGraph g, String id) =>
        g.nodes.firstWhere((n) => n.id == id);

    test('root node gets tier 0', () {
      final g = _graph([
        {'id': 'root'},
        {'id': 'child', 'requires': ['root']},
      ]);
      expect(_node(g, 'root').tier, 0);
    });

    test('direct child of root gets tier 1', () {
      final g = _graph([
        {'id': 'root'},
        {'id': 'child', 'requires': ['root']},
      ]);
      expect(_node(g, 'child').tier, 1);
    });

    test('grandchild gets tier 2', () {
      final g = _graph([
        {'id': 'root'},
        {'id': 'mid', 'requires': ['root']},
        {'id': 'leaf', 'requires': ['mid']},
      ]);
      expect(_node(g, 'leaf').tier, 2);
    });

    test('longest-path tier when multiple parents (diamond shape)', () {
      // a → c → d
      // b → d  (b has no dependencies → tier 0)
      // c is at tier 1; d should be tier 2 (max(1,0) + 1)
      final g = _graph([
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c', 'requires': ['a']},
        {'id': 'd', 'requires': ['c', 'b']},
      ]);
      expect(_node(g, 'a').tier, 0);
      expect(_node(g, 'b').tier, 0);
      expect(_node(g, 'c').tier, 1);
      expect(_node(g, 'd').tier, 2);
    });

    test('isolated node (no edges) gets tier 0', () {
      final g = _graph([{'id': 'alone'}]);
      expect(_node(g, 'alone').tier, 0);
    });

    test('effects parsed from node map', () {
      final g = _graph([
        {
          'id': 'n1',
          'effects': {'xp_multiplier': 1.5, 'extra_time': 3},
        }
      ]);
      final effects = _node(g, 'n1').effects;
      expect(effects['xp_multiplier'], 1.5);
      expect(effects['extra_time'], 3);
    });

    test('non-num effect values are ignored', () {
      final g = _graph([
        {
          'id': 'n1',
          'effects': {'label': 'bonus', 'value': 10},
        }
      ]);
      final effects = _node(g, 'n1').effects;
      expect(effects.containsKey('label'), isFalse);
      expect(effects['value'], 10);
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeGroupVM — aggregated properties
  // -------------------------------------------------------------------------

  group('SkillTreeGroupVM', () {
    SkillBranchVM _branch(
        {required String id,
        required List<Map<String, dynamic>> nodes}) =>
        SkillBranchVM(
          branchId: id,
          groupId: SkillTreeGroupId.combat,
          title: id,
          description: '',
          accent: Colors.red,
          colorHex: '#FF4444',
          nodeMaps: nodes,
        );

    late SkillTreeGroupVM groupVm;

    setUp(() {
      groupVm = SkillTreeGroupVM(
        id: SkillTreeGroupId.combat,
        title: 'Combat',
        description: 'Attack skills',
        accent: const Color(0xFFFF4444),
        colorHex: '#FF4444',
        branches: [
          _branch(id: 'combat', nodes: [
            {'id': 'a', 'unlocked': true},
            {'id': 'b', 'unlocked': false},
            {'id': 'c', 'unlocked': true},
          ]),
          _branch(id: 'risk', nodes: [
            {'id': 'd', 'unlocked': false},
            {'id': 'e', 'unlocked': true},
          ]),
        ],
      );
    });

    test('totalNodes sums nodes across branches', () {
      expect(groupVm.totalNodes, 5);
    });

    test('unlockedNodes sums unlocked across branches', () {
      expect(groupVm.unlockedNodes, 3);
    });

    test('progress is correct fraction', () {
      expect(groupVm.progress, closeTo(3 / 5, 0.001));
    });

    test('progress is 0 when no nodes in any branch', () {
      final empty = SkillTreeGroupVM(
        id: SkillTreeGroupId.utility,
        title: 'Empty',
        description: '',
        accent: Colors.purple,
        colorHex: '#8E44AD',
        branches: [
          _branch(id: 'xp', nodes: []),
        ],
      );
      expect(empty.progress, 0.0);
    });

    test('progress is 1.0 when all nodes unlocked', () {
      final full = SkillTreeGroupVM(
        id: SkillTreeGroupId.enhancement,
        title: 'Full',
        description: '',
        accent: Colors.orange,
        colorHex: '#F39C12',
        branches: [
          _branch(id: 'scholar', nodes: [
            {'id': 'a', 'unlocked': true},
            {'id': 'b', 'unlocked': true},
          ]),
        ],
      );
      expect(full.progress, closeTo(1.0, 0.001));
    });

    test('totalNodes is 0 for empty branches list', () {
      final vm = SkillTreeGroupVM(
        id: SkillTreeGroupId.advanced,
        title: 'Advanced',
        description: '',
        accent: Colors.yellow,
        colorHex: '#FFD700',
        branches: [],
      );
      expect(vm.totalNodes, 0);
      expect(vm.unlockedNodes, 0);
    });
  });
}
