import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/skill_tree_controller.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_provider.dart';
import 'package:trivia_tycoon/game/services/xp_service.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Creates a minimal skill tree graph for testing:
///   root (tier 0, cost 1, available) ──► child (tier 1, cost 2)
SkillTreeGraph _testGraph({bool rootUnlocked = false}) {
  final root = SkillNode(
    id: 'root',
    title: 'Root',
    description: '',
    tier: 0,
    cost: 1,
    category: SkillCategory.xp,
    effects: {},
    available: true,
    unlocked: rootUnlocked,
  );
  final child = SkillNode(
    id: 'child',
    title: 'Child',
    description: '',
    tier: 1,
    cost: 2,
    category: SkillCategory.xp,
    effects: {},
    available: rootUnlocked, // available only when root is unlocked
  );
  return SkillTreeGraph(
    nodes: [root, child],
    edges: [SkillEdge(fromId: 'root', toId: 'child')],
  );
}

/// Builds a [ProviderContainer] with [skillTreeProvider] backed by
/// [graph] and [xpServiceProvider] seeded with [startingXP].
ProviderContainer _makeContainer(
    SkillTreeGraph graph, {
      int startingXP = 100,
      int startingPoints = 10,
    }) {
  final xpService = XPService(startingPlayerXP: startingXP);

  return ProviderContainer(
    overrides: [
      xpServiceProvider.overrideWithValue(xpService),
      skillTreeProvider.overrideWith((ref) => SkillTreeController(
        ref,
        initialGraph: graph,
        startingPoints: startingPoints,
      )),
    ],
  );
}

void main() {
  // ── unlock() — legacy points-based ──────────────────────────────────────

  group('unlock (points-based)', () {
    test('reduces playerPoints by node cost', () {
      final container = _makeContainer(_testGraph(), startingPoints: 5);
      addTearDown(container.dispose);

      final ctrl = container.read(skillTreeProvider.notifier);
      final before = container.read(skillTreeProvider).playerPoints;

      ctrl.unlock('root');

      final after = container.read(skillTreeProvider).playerPoints;
      expect(after, before - 1); // root costs 1
    });

    test('marks node as unlocked', () {
      final container = _makeContainer(_testGraph(), startingPoints: 5);
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).unlock('root');

      final node = container.read(skillTreeProvider).graph.getNodeById('root');
      expect(node?.unlocked, isTrue);
    });

    test('is no-op when playerPoints are insufficient', () {
      final container = _makeContainer(_testGraph(), startingPoints: 0);
      addTearDown(container.dispose);

      final before = container.read(skillTreeProvider).playerPoints;
      container.read(skillTreeProvider.notifier).unlock('root');

      expect(container.read(skillTreeProvider).playerPoints, before);
      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isFalse,
      );
    });

    test('is no-op when prerequisite is not met', () {
      final container = _makeContainer(_testGraph(), startingPoints: 10);
      addTearDown(container.dispose);

      // Try to unlock 'child' without unlocking 'root' first
      container.read(skillTreeProvider.notifier).unlock('child');

      expect(
        container.read(skillTreeProvider).graph.getNodeById('child')?.unlocked,
        isFalse,
      );
    });
  });

  // ── unlockSkill() — XP-based ─────────────────────────────────────────────

  group('unlockSkill (XP-based)', () {
    test('marks node unlocked when XP is sufficient', () {
      final container = _makeContainer(_testGraph(), startingXP: 50);
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).unlockSkill('root');

      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isTrue,
      );
    });

    test('marks direct children as available after unlock', () {
      final container = _makeContainer(_testGraph(), startingXP: 50);
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).unlockSkill('root');

      expect(
        container.read(skillTreeProvider).graph.getNodeById('child')?.available,
        isTrue,
      );
    });

    test('is no-op when XP is insufficient', () {
      final container = _makeContainer(_testGraph(), startingXP: 0);
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).unlockSkill('root');

      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isFalse,
      );
    });

    test('is no-op when prerequisite is not met', () {
      final container = _makeContainer(_testGraph(), startingXP: 100);
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).unlockSkill('child');

      expect(
        container.read(skillTreeProvider).graph.getNodeById('child')?.unlocked,
        isFalse,
      );
    });
  });

  // ── respec() ─────────────────────────────────────────────────────────────

  group('respec', () {
    test('resets all nodes to locked', () {
      // Start with root already unlocked
      final container = _makeContainer(_testGraph(rootUnlocked: true));
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).respec();

      final nodes = container.read(skillTreeProvider).graph.nodes;
      expect(nodes.every((n) => !n.unlocked), isTrue);
    });

    test('refunds 50% of spent XP via xpService', () {
      final xpService = XPService(startingPlayerXP: 10);
      // Build container with root already unlocked (cost=1), so respec refunds 0 (floor of 0.5)
      // Use child (cost=2) unlocked for a clear 50% = 1 point refund
      final nodes = [
        SkillNode(
          id: 'n1',
          title: 'N1',
          description: '',
          tier: 0,
          cost: 2,
          category: SkillCategory.xp,
          effects: {},
          unlocked: true,
          available: true,
        ),
      ];
      final graph = SkillTreeGraph(nodes: nodes, edges: []);
      final container = ProviderContainer(
        overrides: [
          xpServiceProvider.overrideWithValue(xpService),
          skillTreeProvider.overrideWith((ref) => SkillTreeController(
            ref,
            initialGraph: graph,
          )),
        ],
      );
      addTearDown(container.dispose);

      final xpBefore = xpService.playerXP;
      container.read(skillTreeProvider.notifier).respec();

      // 50% of cost=2 = 1 point refunded
      expect(xpService.playerXP, xpBefore + 1);
    });
  });

  // ── select() ─────────────────────────────────────────────────────────────

  group('select', () {
    test('updates selectedId', () {
      final container = _makeContainer(_testGraph());
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).select('root');
      expect(container.read(skillTreeProvider).selectedId, 'root');
    });

    test('can clear selection', () {
      final container = _makeContainer(_testGraph());
      addTearDown(container.dispose);

      container.read(skillTreeProvider.notifier).select('root');
      container.read(skillTreeProvider.notifier).select(null);
      expect(container.read(skillTreeProvider).selectedId, isNull);
    });
  });
}