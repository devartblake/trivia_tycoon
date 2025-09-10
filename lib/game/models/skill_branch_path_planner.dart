import '../models/skill_tree_graph.dart';

/// Plans optimal unlock order for a branch using topological sort + priority weights
class BranchPathPlanner {
  final SkillTreeGraph graph;
  final Map<String, double> weightOf;

  BranchPathPlanner(this.graph, this.weightOf);

  /// Returns list of node IDs in recommended unlock order
  List<String> plan() {
    final indeg = <String, int>{
      for (final n in graph.nodes) n.id: graph.indegree(n.id)
    };

    final adj = <String, List<String>>{
      for (final n in graph.nodes) n.id: graph.neighbors(n.id).toList()
    };

    final ready = <String>[
      for (final n in graph.nodes)
        if (indeg[n.id] == 0) n.id
    ]..sort((a, b) => (weightOf[b] ?? 0).compareTo(weightOf[a] ?? 0));

    final order = <String>[];

    while (ready.isNotEmpty) {
      final id = ready.removeAt(0);
      order.add(id);

      for (final neighborId in adj[id] ?? <String>[]) {
        indeg[neighborId] = (indeg[neighborId] ?? 0) - 1;
        if (indeg[neighborId] == 0) {
          ready.add(neighborId);
          ready.sort((a, b) => (weightOf[b] ?? 0).compareTo(weightOf[a] ?? 0));
        }
      }
    }

    // Handle any remaining nodes (shouldn't happen in a DAG)
    final remaining = graph.nodes
        .where((n) => !order.contains(n.id))
        .map((n) => n.id)
        .toList()
      ..sort((a, b) => (weightOf[b] ?? 0).compareTo(weightOf[a] ?? 0));

    order.addAll(remaining);
    return order;
  }
}