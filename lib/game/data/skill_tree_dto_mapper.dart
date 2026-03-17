import '../models/skill_tree_graph.dart';
import '../../core/dto/skill_dto.dart';

/// Merges server-side unlock state onto a locally-loaded [SkillTreeGraph].
///
/// The asset graph is the source of truth for all node definition fields
/// (tier, category, effects, cooldown, branchId, etc.). The server [SkillTreeDto]
/// is the source of truth for which nodes the player has unlocked.
class SkillTreeDtoMapper {
  /// Overlays server unlock state from [dto] onto [assetGraph].
  ///
  /// - Nodes present in [dto] but absent from [assetGraph] are ignored.
  /// - Nodes present in [assetGraph] but absent from [dto] retain their asset
  ///   default (`unlocked = false`).
  /// - `available` is re-derived after merging: a node is available when all
  ///   incoming edges originate from unlocked nodes (or it has no prerequisites).
  static SkillTreeGraph merge(SkillTreeGraph assetGraph, SkillTreeDto dto) {
    final serverById = {for (final n in dto.nodes) n.id: n};

    final mergedNodes = assetGraph.nodes.map((node) {
      final serverNode = serverById[node.id];
      final isUnlocked = serverNode?.unlocked ?? node.unlocked;
      final isAvailable = _deriveAvailable(node, assetGraph, serverById);
      return node.copyWith(unlocked: isUnlocked, available: isAvailable);
    }).toList();

    return SkillTreeGraph(
      nodes: mergedNodes,
      edges: assetGraph.edges,
      groups: assetGraph.groups,
    );
  }

  /// A node is available when it is not yet unlocked and all prerequisite
  /// nodes (i.e. nodes with edges pointing to this node) are unlocked.
  /// Nodes with no prerequisites are always available.
  static bool _deriveAvailable(
    SkillNode node,
    SkillTreeGraph graph,
    Map<String, SkillNodeDto> serverById,
  ) {
    if (node.unlocked) return false;

    final prereqIds = graph.edges
        .where((e) => e.toId == node.id)
        .map((e) => e.fromId);

    // A node with no prerequisites (root node) is always available.
    if (prereqIds.isEmpty) return true;

    return prereqIds.every((id) => serverById[id]?.unlocked ?? false);
  }
}
