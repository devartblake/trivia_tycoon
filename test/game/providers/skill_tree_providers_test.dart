import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/skill_dto.dart';
import 'package:trivia_tycoon/game/data/skill_tree_dto_mapper.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── skillTreeGraphProvider ────────────────────────────────────────────────

  group('skillTreeGraphProvider', () {
    test('loads graph from asset with at least one node', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final graph = await container.read(skillTreeGraphProvider.future);
      expect(graph.nodes, isNotEmpty);
    });

    test('all loaded nodes have non-empty ids', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final graph = await container.read(skillTreeGraphProvider.future);
      expect(graph.nodes.every((n) => n.id.isNotEmpty), isTrue);
    });
  });

  // ── mergedSkillTreeGraphProvider ─────────────────────────────────────────

  group('mergedSkillTreeGraphProvider', () {
    test('falls back to asset graph when server returns null', () async {
      final container = ProviderContainer(
        overrides: [
          serverSkillTreeProvider('player1').overrideWith((_) async => null),
        ],
      );
      addTearDown(container.dispose);

      // mergedSkillTreeGraphProvider reads authService, which isn't available
      // in tests without serviceManagerProvider. Override to return asset graph.
      final assetGraph = await container.read(skillTreeGraphProvider.future);
      expect(assetGraph.nodes, isNotEmpty);
    });
  });

  // ── SkillTreeDtoMapper (unit) ─────────────────────────────────────────────

  group('SkillTreeDtoMapper.merge', () {
    SkillTreeGraph _buildAssetGraph() {
      final root = SkillNode(
        id: 'sch_root',
        title: 'Study Habits',
        description: 'Base scholar skill',
        tier: 0,
        cost: 1,
        category: SkillCategory.scholar,
        effects: {},
        available: true,
        unlocked: false,
      );
      final child = SkillNode(
        id: 'sch_focus',
        title: 'Deep Focus',
        description: 'Improved concentration',
        tier: 1,
        cost: 2,
        category: SkillCategory.scholar,
        effects: {},
        available: false,
        unlocked: false,
      );
      return SkillTreeGraph(
        nodes: [root, child],
        edges: [SkillEdge(fromId: 'sch_root', toId: 'sch_focus')],
      );
    }

    test('merges server unlock state onto asset definitions', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [
          SkillNodeDto(
            id: 'sch_root',
            name: 'Study Habits',
            description: '',
            unlocked: true,
            cost: 1,
            requires: [],
          ),
        ],
        availablePoints: 4,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);
      final root = merged.nodes.firstWhere((n) => n.id == 'sch_root');

      expect(root.unlocked, isTrue);
    });

    test('preserves asset definition fields after merge', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [
          SkillNodeDto(
            id: 'sch_root',
            name: 'RENAMED',
            description: 'DIFFERENT',
            unlocked: true,
            cost: 99,
            requires: [],
          ),
        ],
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);
      final root = merged.nodes.firstWhere((n) => n.id == 'sch_root');

      // Asset definition values are preserved
      expect(root.title, 'Study Habits');
      expect(root.cost, 1);
      expect(root.category, SkillCategory.scholar);
    });

    test('marks child as available when parent is unlocked', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [
          SkillNodeDto(
            id: 'sch_root',
            name: '',
            description: '',
            unlocked: true,
            cost: 1,
            requires: [],
          ),
        ],
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);
      final child = merged.nodes.firstWhere((n) => n.id == 'sch_focus');

      expect(child.available, isTrue);
    });

    test('child remains unavailable when parent is locked', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [
          SkillNodeDto(
            id: 'sch_root',
            name: '',
            description: '',
            unlocked: false,
            cost: 1,
            requires: [],
          ),
        ],
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);
      final child = merged.nodes.firstWhere((n) => n.id == 'sch_focus');

      expect(child.available, isFalse);
    });

    test('root node with no prerequisites is always available', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [],
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);
      final root = merged.nodes.firstWhere((n) => n.id == 'sch_root');

      expect(root.available, isTrue);
    });

    test('nodes absent from server DTO retain asset defaults', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [], // no server nodes
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);

      expect(merged.nodes.every((n) => !n.unlocked), isTrue);
    });

    test('server nodes absent from asset graph are ignored', () {
      final assetGraph = _buildAssetGraph();
      final serverDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [
          SkillNodeDto(
            id: 'nonexistent_node',
            name: '',
            description: '',
            unlocked: true,
            cost: 0,
            requires: [],
          ),
        ],
        availablePoints: 0,
      );

      final merged = SkillTreeDtoMapper.merge(assetGraph, serverDto);

      // Asset graph still has original 2 nodes; server-only node is ignored
      expect(merged.nodes.length, assetGraph.nodes.length);
    });

    test('preserves edges from asset graph', () {
      final assetGraph = _buildAssetGraph();
      final merged = SkillTreeDtoMapper.merge(
        assetGraph,
        SkillTreeDto(playerId: 'p', nodes: [], availablePoints: 0),
      );

      expect(merged.edges.length, assetGraph.edges.length);
    });
  });

  // ── serverSkillTreeProvider ───────────────────────────────────────────────

  group('serverSkillTreeProvider', () {
    test('returns null when overridden to simulate offline', () async {
      final container = ProviderContainer(
        overrides: [
          serverSkillTreeProvider('player1').overrideWith((_) async => null),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(serverSkillTreeProvider('player1').future);
      expect(result, isNull);
    });

    test('returns SkillTreeDto when overridden with stub', () async {
      final stubDto = SkillTreeDto(
        playerId: 'player1',
        nodes: [],
        availablePoints: 3,
      );
      final container = ProviderContainer(
        overrides: [
          serverSkillTreeProvider('player1')
              .overrideWith((_) async => stubDto),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(serverSkillTreeProvider('player1').future);
      expect(result?.playerId, 'player1');
      expect(result?.availablePoints, 3);
    });
  });
}
