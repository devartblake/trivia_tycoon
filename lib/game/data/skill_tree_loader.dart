import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/skill_tree_graph.dart';

SkillCategory _parseCategory(String raw) {
  final match = SkillCategory.values.firstWhere(
        (e) => describeEnum(e) == raw,
    orElse: () => SkillCategory.unknown,
  );
  return match;
}

Future<SkillTreeGraph> loadSkillTreeFromAsset(String assetPath) async {
  final jsonStr = await rootBundle.loadString(assetPath);
  final map = json.decode(jsonStr) as Map<String, dynamic>;

  final nodes = (map['nodes'] as List<dynamic>).map((j) {
    final m = j as Map<String, dynamic>;
    return SkillNode(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      tier: m['tier'] as int,
      cost: m['cost'] as int,
      category: _parseCategory(m['category'] as String),
      effects: (m['effects'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num))),
      unlocked: (m['unlocked'] as bool?) ?? false,
      available: (m['available'] as bool?) ?? false,
    );
  }).toList();

  final edges = (map['edges'] as List<dynamic>).map((j) {
    final m = j as Map<String, dynamic>;
    return SkillEdge(fromId: m['fromId'] as String, toId: m['toId'] as String);
  }).toList();

  return SkillTreeGraph(nodes: nodes, edges: edges);
}
