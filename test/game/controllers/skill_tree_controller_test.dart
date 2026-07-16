import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/hive_test_env.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';
import 'package:synaptix/game/controllers/skill_tree_controller.dart';
import 'package:synaptix/game/models/skill_tree_graph.dart';
import 'package:synaptix/game/providers/core_providers.dart';
import 'package:synaptix/game/providers/profile_service_provider.dart';
import 'package:synaptix/game/providers/skill_cooldown_service_provider.dart';
import 'package:synaptix/game/providers/skill_tree_provider.dart';
import 'package:synaptix/game/services/profile_service.dart';
import 'package:synaptix/game/services/skill_cooldown_service.dart';
import 'package:synaptix/game/services/xp_service.dart';
import 'package:synaptix/game/providers/xp_provider.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Minimal in-memory storage for tests — no Hive required.
class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, dynamic> _store = {};

  _FakeStorage({Map<String, dynamic>? initial}) {
    if (initial != null) _store.addAll(initial);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final raw = _store[key];
    if (raw is List<String>) return List<String>.from(raw);
    return null;
  }

  @override
  Future<void> setStringList(String key, List<String> values) async {
    _store[key] = List<String>.from(values);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = _store[key];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _store[key] = Map<String, dynamic>.from(value);
  }
}

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
  late HiveTestEnv hiveEnv;
  setUpAll(() async {
    hiveEnv = await HiveTestEnv.create();
  });
  tearDownAll(() async {
    await hiveEnv.dispose();
  });
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

  // ── SkillTreeGraph.withUnlockedIds ────────────────────────────────────────

  group('SkillTreeGraph.withUnlockedIds', () {
    test('marks matching nodes as unlocked and available', () {
      final graph = _testGraph();
      final restored = graph.withUnlockedIds({'root'});

      expect(restored.getNodeById('root')?.unlocked, isTrue);
      expect(restored.getNodeById('root')?.available, isTrue);
    });

    test('marks children of unlocked nodes as available', () {
      final graph = _testGraph();
      final restored = graph.withUnlockedIds({'root'});

      expect(restored.getNodeById('child')?.available, isTrue);
      expect(restored.getNodeById('child')?.unlocked, isFalse);
    });

    test('missing IDs are ignored safely', () {
      final graph = _testGraph();
      // 'ghost_node' does not exist in the graph — should not throw.
      final restored = graph.withUnlockedIds({'ghost_node', 'root'});

      expect(restored.getNodeById('root')?.unlocked, isTrue);
    });

    test('returns same graph when set is empty', () {
      final graph = _testGraph();
      final restored = graph.withUnlockedIds({});

      // Nodes should remain in their original state.
      expect(restored.getNodeById('root')?.unlocked, isFalse);
    });

    test('does not modify the original graph', () {
      final graph = _testGraph();
      graph.withUnlockedIds({'root'});

      // Original graph must be unchanged.
      expect(graph.getNodeById('root')?.unlocked, isFalse);
    });
  });

  // ── controller restores graph from persisted unlocked IDs ─────────────────

  group('SkillTreeController — loadProfile callback restore', () {
    test('restores graph from loadProfile callback when provided', () async {
      final persistedGraph = _testGraph(rootUnlocked: true);
      final xpService = XPService(startingPlayerXP: 100);

      final container = ProviderContainer(
        overrides: [
          xpServiceProvider.overrideWithValue(xpService),
          skillTreeProvider.overrideWith(
            (ref) => SkillTreeController(
              ref,
              initialGraph: _testGraph(), // start with empty graph
              loadProfile: () async => persistedGraph,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Allow the async _restoreProfile to complete.
      await Future.delayed(Duration.zero);

      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isTrue,
      );
    });
  });

  // ── storage-backed restore (no loadProfile callback) ──────────────────────

  group('SkillTreeController — storage-backed restore', () {
    test('restores unlocked nodes from storage when no loadProfile is given',
        () async {
      // Pre-populate storage with a persisted 'root' unlock.
      final fakeStorage = _FakeStorage(initial: {
        'unlockedSkillIds': <String>['root'],
      });
      final xpService = XPService(startingPlayerXP: 50);

      final container = ProviderContainer(
        overrides: [
          xpServiceProvider.overrideWithValue(xpService),
          generalKeyValueStorageProvider.overrideWithValue(fakeStorage),
          // ProfileService uses generalKeyValueStorageProvider automatically
          // through its _storage getter once we override it above.
          profileServiceProvider.overrideWith(
            (ref) => ProfileService(ref, playerId: 'p1', displayName: 'Test'),
          ),
          skillCooldownServiceProvider.overrideWith(
            (_) => SkillCooldownService(),
          ),
          skillTreeProvider.overrideWith(
            (ref) => SkillTreeController(
              ref,
              initialGraph: _testGraph(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Allow _restoreProfile (and ProfileService._loadFromStorage) to finish.
      await Future.delayed(Duration.zero);

      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isTrue,
      );
    });

    test(
        'persisted unlock IDs are reapplied when loadGraph is called after restore',
        () async {
      final fakeStorage = _FakeStorage(initial: {
        'unlockedSkillIds': <String>['root'],
      });
      final xpService = XPService(startingPlayerXP: 50);

      final container = ProviderContainer(
        overrides: [
          xpServiceProvider.overrideWithValue(xpService),
          generalKeyValueStorageProvider.overrideWithValue(fakeStorage),
          profileServiceProvider.overrideWith(
            (ref) => ProfileService(ref, playerId: 'p1', displayName: 'Test'),
          ),
          skillCooldownServiceProvider.overrideWith(
            (_) => SkillCooldownService(),
          ),
          skillTreeProvider.overrideWith(
            (ref) => SkillTreeController(
              ref,
              initialGraph: _testGraph(), // starts empty
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for restore to finish and capture the controller.
      await Future.delayed(Duration.zero);
      final ctrl = container.read(skillTreeProvider.notifier);

      // Simulate the hot-swap that skillTreeProvider does when
      // mergedSkillTreeGraphProvider resolves (root starts locked in the new graph).
      ctrl.loadGraph(_testGraph());

      // Restored unlock IDs must be reapplied to the newly loaded graph.
      expect(
        container.read(skillTreeProvider).graph.getNodeById('root')?.unlocked,
        isTrue,
      );
    });
  });
}
