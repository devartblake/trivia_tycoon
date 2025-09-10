import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/skill_tree_graph.dart';

SkillCategory _parseCategory(String raw) {
  // matches enum by its string name (scholar/strategist/xp/…)
  return SkillCategory.values.firstWhere(
        (e) => describeEnum(e) == raw,
    orElse: () => SkillCategory.unknown,
  );
}

/// Load branch-style JSON and convert to your existing SkillTreeGraph.
Future<SkillTreeGraph> loadBranchSkillTreeFromAsset(String assetPath) async {
  final txt = await rootBundle.loadString(assetPath);
  final data = json.decode(txt);

  // Accept either { "branches":[...] } or a bare List[...]
  final List<dynamic> branches = (data is Map<String, dynamic>)
      ? (data['branches'] as List<dynamic>)
      : (data as List<dynamic>);

  final nodes = <SkillNode>[];
  final edges = <SkillEdge>[];

  for (final b in branches) {
    final branch = b as Map<String, dynamic>;
    final branchId = branch['branch_id'] as String;
    final category = _parseCategory(branchId);

    final List<dynamic> rawNodes = branch['nodes'] as List<dynamic>;
    for (final n in rawNodes) {
      final m = n as Map<String, dynamic>;
      final id = m['id'] as String;

      // Build node — tier computed later, available derives from requires
      final requires = (m['requires'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList();

      nodes.add(
        SkillNode(
          id: id,
          title: m['title'] as String,
          description: m['description'] as String? ?? '',
          tier: 0, // temp; we’ll compute tiers below
          cost: (m['cost'] as num).toInt(),
          category: category,
          effects: const <String, num>{},  // none provided in branch schema
          unlocked: (m['unlocked'] as bool?) ?? false,
          available: requires.isEmpty,      // roots are available by default
        ),
      );

      // requires[] -> edges require -> id
      for (final req in requires) {
        edges.add(SkillEdge(fromId: req, toId: id));
      }
    }
  }

  // Compute tiers from edges (topological levels)
  final tiers = _computeTiers(nodes.map((e) => e.id), edges);
  final nodesWithTier = [
    for (final n in nodes)
      SkillNode(
        id: n.id,
        title: n.title,
        description: n.description,
        tier: tiers[n.id] ?? 0,
        cost: n.cost,
        category: n.category,
        effects: n.effects,
        unlocked: n.unlocked,
        available: n.available,
      )
  ];

  return SkillTreeGraph(nodes: nodesWithTier, edges: edges);
}

/// Assigns each node a layer (tier) based on its prerequisites (Kahn-like).
Map<String, int> _computeTiers(Iterable<String> nodeIds, List<SkillEdge> edges) {
  final inDeg = <String, int>{ for (final id in nodeIds) id: 0 };
  final adj = <String, List<String>>{ for (final id in nodeIds) id: [] };

  for (final e in edges) {
    inDeg[e.toId] = (inDeg[e.toId] ?? 0) + 1;
    adj[e.fromId] = (adj[e.fromId] ?? [])..add(e.toId);
  }

  final q = <String>[];
  final tier = <String, int>{};

  // roots (no requires)
  inDeg.forEach((id, d) {
    if (d == 0) {
      q.add(id);
      tier[id] = 0;
    }
  });

  while (q.isNotEmpty) {
    final cur = q.removeAt(0);
    final curTier = tier[cur] ?? 0;

    for (final nxt in adj[cur] ?? const []) {
      inDeg[nxt] = (inDeg[nxt] ?? 0) - 1;
      if (inDeg[nxt] == 0) {
        tier[nxt] = curTier + 1;
        q.add(nxt);
      } else {
        // If multiple parents, keep the max tier observed
        tier[nxt] = (tier[nxt] ?? 0).clamp(0, 1 << 20);
        if ((tier[nxt] ?? 0) < curTier + 1) {
          tier[nxt] = curTier + 1;
        }
      }
    }
  }

  return tier;
}
