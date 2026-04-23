import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/skill_tree_graph.dart';

Future<SkillTreeGraph> loadSkillTreeFromAsset(String assetPath) async {
  final jsonStr = await rootBundle.loadString(assetPath);
  final map = json.decode(jsonStr) as Map<String, dynamic>;

  // Grouped format (skill_tree_groups key) — used by the current asset file.
  if (map.containsKey('skill_tree_groups')) {
    return SkillTreeGraph.fromGroupedJson(map);
  }

  // Flat format fallback (nodes + edges at top level).
  final nodes = (map['nodes'] as List<dynamic>? ?? []).map((j) {
    return SkillNode.fromJson(j as Map<String, dynamic>);
  }).toList();

  final edges = (map['edges'] as List<dynamic>? ?? []).map((j) {
    final m = j as Map<String, dynamic>;
    return SkillEdge(fromId: m['fromId'] as String, toId: m['toId'] as String);
  }).toList();

  return SkillTreeGraph(nodes: nodes, edges: edges);
}
