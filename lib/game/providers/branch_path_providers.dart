import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/skill_tree_controller.dart';
import '../models/skill_tree_graph.dart';
import '../planning/skill_branch_path_planner.dart';

/// Returns the recommended unlock order (list of nodeIds) for a given branchId.
final branchAutoPathProvider =
    Provider.family<List<String>, String>((ref, branchId) {
  final state = ref.watch(skillTreeProvider);
  final graph = state.graph;
  final nodes = computeRecommendedOrderForBranch(graph, branchId);
  return [for (final n in nodes) n.id];
});

/// Returns a map of nodeId -> screen-space center for a given branchId,
/// using positions from the current SkillTreeState.
final branchCentersProvider =
    Provider.family<Map<String, Offset>, String>((ref, branchId) {
  final state = ref.watch(skillTreeProvider);
  final cat = _categoryFromGroupId(branchId);
  final nodes = state.graph.nodes.where((n) => n.category == cat);
  final map = <String, Offset>{};
  for (final n in nodes) {
    final c = state.positions[n.id];
    if (c != null) map[n.id] = c;
  }
  return map;
});

// Local helper to map groupId->category consistently with your app.
SkillCategory _categoryFromGroupId(String groupId) {
  switch (groupId.toLowerCase()) {
    case 'scholar': return SkillCategory.scholar;
    case 'strategist': return SkillCategory.strategist;
    // ... keep the rest identical to your existing mapper ...
    default: return SkillCategory.unknown;
  }
}
