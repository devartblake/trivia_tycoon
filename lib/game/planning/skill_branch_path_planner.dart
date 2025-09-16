import '../models/skill_tree_graph.dart';

/// Computes a recommended unlock order per-branch using Kahn's algorithm,
/// with a simple priority (cheaper cost + recognizable boost effects).
class SkillBranchPathPlanner {
  final SkillTreeGraph graph;
  final Map<String, double>? weightOf; // Keep for backward compatibility

  // Main constructor (backward compatible)
  SkillBranchPathPlanner(this.graph, [this.weightOf]);

  // Const constructor for new usage pattern
  const SkillBranchPathPlanner.fromGraph(this.graph) : weightOf = null;

  /// New method: Returns SkillNode objects for a specific branch
  List<SkillNode> forBranch(String branchId) {
    final cat = _categoryFromGroupId(branchId);
    final nodes = graph.nodes.where((n) =>
    n.category == cat ||
        n.branchId == branchId ||
        n.id.startsWith(branchId)
    ).toList();

    if (nodes.isEmpty) return const [];

    final idSet = { for (final n in nodes) n.id };
    final edges = graph.edges
        .where((e) => idSet.contains(e.fromId) && idSet.contains(e.toId))
        .toList();

    // indegree / adjacency
    final indeg = <String, int>{ for (final n in nodes) n.id: 0 };
    final adj = <String, List<String>>{ for (final n in nodes) n.id: [] };
    for (final e in edges) {
      indeg[e.toId] = (indeg[e.toId] ?? 0) + 1;
      adj[e.fromId]!.add(e.toId);
    }

    double priority(SkillNode n) {
      // Use provided weights if available, otherwise compute priority
      if (weightOf != null && weightOf!.containsKey(n.id)) {
        return weightOf![n.id]!;
      }

      // Recognizable bumps; tweak to your liking:
      final xpBoost = (n.effects['xpBoost'] ?? 0).toDouble();
      final timeBonus = (n.effects['timeBonusSec'] ?? 0).toDouble();
      final streakMult = (n.effects['streakMult'] ?? 0).toDouble();
      final weight = (n.effects['weight'] ?? 0).toDouble();

      return -n.cost + xpBoost * 10 + timeBonus * 0.5 + streakMult * 2 + weight;
    }

    final byId = { for (final n in nodes) n.id: n };
    final ready = <SkillNode>[
      for (final n in nodes) if ((indeg[n.id] ?? 0) == 0) n
    ]..sort((a,b) => priority(b).compareTo(priority(a)));

    final result = <SkillNode>[];

    while (ready.isNotEmpty) {
      final cur = ready.removeAt(0);
      result.add(cur);
      for (final v in adj[cur.id]!) {
        final d = (indeg[v] ?? 0) - 1;
        indeg[v] = d;
        if (d == 0) {
          ready.add(byId[v]!);
        }
      }
      ready.sort((a,b) => priority(b).compareTo(priority(a)));
    }

    if (result.length != nodes.length) {
      // Failsafe in case of cycles
      final missing = nodes.where((n) => !result.any((x) => x.id == n.id)).toList()
        ..sort((a,b) => priority(b).compareTo(priority(a)));
      result.addAll(missing);
    }
    return result;
  }

  /// Backward compatible method: Returns list of node IDs in recommended unlock order
  List<String> plan() {
    return computeRecommendedPath(
      branchNodeIds: graph.nodes.map((n) => n.id).toSet(),
      edges: graph.edges,
      weightByNodeId: weightOf,
    );
  }

  /// Computes a recommended unlock path inside a branch.
  /// This is a topological order that prefers higher-weight nodes when choices exist.
  ///
  /// Conventions:
  /// - `branchNodeIds`: nodes belonging to this branch (already filtered).
  /// - `edges`: the subset of edges connecting those nodes.
  /// - `weightByNodeId`: optional priority score (higher first) – e.g. designer-specified.
  List<String> computeRecommendedPath({
    required Set<String> branchNodeIds,
    required List<SkillEdge> edges,
    Map<String, num>? weightByNodeId,
  }) {
    // Build adjacency and indegree restricted to the branch
    final adj = <String, List<String>>{};
    final indeg = <String, int>{};

    for (final id in branchNodeIds) {
      adj[id] = <String>[];
      indeg[id] = 0;
    }

    for (final e in edges) {
      if (!branchNodeIds.contains(e.fromId) || !branchNodeIds.contains(e.toId)) continue;
      adj[e.fromId]!.add(e.toId);
      indeg[e.toId] = (indeg[e.toId] ?? 0) + 1;
    }

    // Seed: all zero-indegree nodes
    final path = <String>[];
    final available = <String>[
      for (final entry in indeg.entries)
        if (entry.value == 0) entry.key
    ];

    num w(String id) => (weightByNodeId?[id] ?? weightOf?[id] ?? 1);

    while (available.isNotEmpty) {
      // Pick the highest-weight available node (stable tie-breaker by id)
      available.sort((a, b) {
        final dw = w(b).compareTo(w(a));
        if (dw != 0) return dw;
        return a.compareTo(b);
      });
      final u = available.removeAt(0);
      path.add(u);

      for (final v in adj[u]!) {
        indeg[v] = (indeg[v] ?? 0) - 1;
        if (indeg[v] == 0) {
          available.add(v);
        }
      }
    }

    // If we didn't visit all, there's a cycle; append the rest in weight order.
    if (path.length != branchNodeIds.length) {
      final missing = branchNodeIds.difference(path.toSet()).toList()
        ..sort((a, b) {
          final dw = w(b).compareTo(w(a));
          if (dw != 0) return dw;
          return a.compareTo(b);
        });
      path.addAll(missing);
    }
    return path;
  }
}

/// Keep this helper close so both screens share the same category mapping.
SkillCategory _categoryFromGroupId(String groupId) {
  switch (groupId.toLowerCase()) {
    case 'scholar': return SkillCategory.scholar;
    case 'strategist': return SkillCategory.strategist;
    case 'combat': return SkillCategory.combat;
    case 'xp': return SkillCategory.xp;
    case 'timer': return SkillCategory.timer;
    case 'combo': return SkillCategory.combo;
    case 'risk': return SkillCategory.risk;
    case 'luck': return SkillCategory.luck;
    case 'stealth': return SkillCategory.stealth;
    case 'knowledge': return SkillCategory.knowledge;
    case 'elite': return SkillCategory.elite;
    case 'wildcard': return SkillCategory.wildcard;
    case 'general': return SkillCategory.general;
    default: return SkillCategory.unknown;
  }
}

/// Static helper function for UI components to avoid circular dependencies
/// This can be used by Nav screens and other UI components
List<SkillNode> computeRecommendedOrderForBranch(SkillTreeGraph graph, String branchId) {
  final planner = SkillBranchPathPlanner.fromGraph(graph);
  return planner.forBranch(branchId);
}