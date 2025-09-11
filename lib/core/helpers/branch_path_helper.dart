import '../../game/models/skill_tree_graph.dart';

/// Utility class for computing recommended paths and orders for skill branches
class BranchPathHelper {
  BranchPathHelper._();

  /// Computes a recommended unlock order for nodes in a specific branch
  /// This is a simplified version that can be used by UI components
  static List<SkillNode> computeRecommendedOrderForBranch(
      SkillTreeGraph graph,
      String branchId
      ) {
    // Filter nodes by branchId or category matching
    final branchNodes = graph.nodes.where((node) {
      // Check if node belongs to this branch (adjust logic based on your data structure)
      return node.branchId == branchId ||
          node.category.name.toLowerCase() == branchId.toLowerCase() ||
          node.id.startsWith(branchId);
    }).toList();

    if (branchNodes.isEmpty) return [];

    // Simple topological sort with tier preference
    final result = <SkillNode>[];
    final remaining = List<SkillNode>.from(branchNodes);
    final processed = <String>{};

    while (remaining.isNotEmpty) {
      // Find nodes with no unprocessed prerequisites
      final available = remaining.where((node) {
        final prereqs = graph.edges
            .where((e) => e.toId == node.id)
            .map((e) => e.fromId);

        return prereqs.every((prereqId) =>
        processed.contains(prereqId) ||
            !branchNodes.any((n) => n.id == prereqId));
      }).toList();

      if (available.isEmpty) {
        // Handle cycles by taking the lowest tier node
        available.addAll(remaining.take(1));
      }

      // Sort by tier first, then by cost/weight
      available.sort((a, b) {
        final tierDiff = a.tier.compareTo(b.tier);
        if (tierDiff != 0) return tierDiff;
        return a.cost.compareTo(b.cost);
      });

      final next = available.first;
      result.add(next);
      processed.add(next.id);
      remaining.remove(next);
    }

    return result;
  }

  /// Gets the display priority for a node (used for visual ordering)
  static int getNodeDisplayPriority(SkillNode node) {
    // Higher tier nodes should appear later, lower cost nodes first within tier
    return node.tier * 1000 + node.cost;
  }

  /// Checks if a node is on the critical path for a branch
  static bool isOnCriticalPath(SkillNode node, List<SkillNode> orderedNodes) {
    final index = orderedNodes.indexWhere((n) => n.id == node.id);
    return index >= 0 && index < (orderedNodes.length * 0.7).round(); // First 70% are "critical"
  }

  /// Gets weight for a node based on its effects or tier
  static double getNodeWeight(SkillNode node) {
    return node.effects['weight']?.toDouble() ?? (100 - node.tier).toDouble();
  }
}
