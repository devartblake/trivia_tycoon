import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill_tree_graph.dart';


@immutable
class SkillTreeState {
  final SkillTreeGraph graph;
  // Node positions in logical (layout) coordinates:
  final Map<String, Offset> positions;
  final String? selectedId;
  final int playerPoints;

  const SkillTreeState({
    required this.graph,
    required this.positions,
    required this.playerPoints,
    this.selectedId,
  });

  SkillTreeState copyWith({
    SkillTreeGraph? graph,
    Map<String, Offset>? positions,
    String? selectedId,
    int? playerPoints,
  }) => SkillTreeState(
    graph: graph ?? this.graph,
    positions: positions ?? this.positions,
    selectedId: selectedId ?? this.selectedId,
    playerPoints: playerPoints ?? this.playerPoints,
  );
}

class SkillTreeController extends StateNotifier<SkillTreeState> {
  SkillTreeController(SkillTreeGraph initialGraph)
      : super(SkillTreeState(
    graph: initialGraph,
    positions: const {},
    playerPoints: 5, // example starting points
  )) {
    _computeLayout();
  }

  // Simple layered layout: nodes grouped by tier, spaced evenly.
  void _computeLayout() {
    const double xGap = 280.0;
    const double yGap = 180.0;
    final positions = <String, Offset>{};
    final tiers = List.generate(state.graph.maxTier + 1, (_) => <SkillNode>[]);
    for (final n in state.graph.nodes) {
      tiers[n.tier].add(n);
    }
    for (var t = 0; t < tiers.length; t++) {
      final row = tiers[t];
      for (var i = 0; i < row.length; i++) {
        // Center items around 0 on x
        final x = (i - (row.length - 1) / 2.0) * xGap;
        final y = t * yGap;
        positions[row[i].id] = Offset(x, y);
      }
    }
    state = state.copyWith(positions: positions);
  }

  void select(String? id) => state = state.copyWith(selectedId: id);

  bool canUnlock(String id) {
    final n = state.graph.byId[id];
    if (n == null || n.unlocked) return false;
    if (state.playerPoints < n.cost) return false;
    // All prerequisites must be unlocked
    final prereqs = state.graph.edges
        .where((e) => e.toId == id)
        .map((e) => state.graph.byId[e.fromId]!)
        .toList();
    return prereqs.isEmpty || prereqs.every((p) => p.unlocked);
  }

  void unlock(String id) {
    if (!canUnlock(id)) return;
    final updated = state.graph.nodes.map((n) {
      if (n.id == id) return n.copyWith(unlocked: true);
      return n;
    }).toList();
    state = state.copyWith(
      graph: SkillTreeGraph(nodes: updated, edges: state.graph.edges),
      playerPoints: state.playerPoints - state.graph.byId[id]!.cost,
    );
  }

  // Optional: respec (refund all at 50%)
  void respec() {
    final refunded = state.graph.nodes.where((n) => n.unlocked).fold<int>(
      0, (sum, n) => sum + (n.cost / 2).floor(),
    );
    final reset = [
      for (final n in state.graph.nodes) n.copyWith(unlocked: false),
    ];
    state = state.copyWith(
      graph: SkillTreeGraph(nodes: reset, edges: state.graph.edges),
      playerPoints: state.playerPoints + refunded,
      selectedId: null,
    );
  }

  void updatePositions(Map<String, Offset> updated) {}
}

final skillTreeProvider =
StateNotifierProvider<SkillTreeController, SkillTreeState>((ref) {
  // Demo data:
  final nodes = [
    SkillNode(id: 'root',   title: 'Quick Learner', description: '+10% XP', tier: 0, cost: 1, effects: {'xpBoost': 0.1}, category: SkillCategory.XP),
    SkillNode(id: 'time1',  title: 'Steady Timer', description: '+5s', tier: 1, cost: 1, effects: {'timeBonusSec': 5}, category: SkillCategory.Strategist),
    SkillNode(id: 'combo1', title: 'Combo Starter', description: 'Streak x1.2', tier: 1, cost: 1, effects: {'streakMult': 1.2}, category: SkillCategory.Strategist),
    SkillNode(id: 'cat1',   title: 'Sports Expert', description: '+10% Sports', tier: 2, cost: 2, effects: {'sportsScoreBoost': 0.1}, category: SkillCategory.Scholar),
    SkillNode(id: 'risk1',  title: 'Risk Taker', description: 'Hard Q bonus', tier: 2, cost: 2, effects: {'hardBonus': 0.15}, category: SkillCategory.XP),
    SkillNode(id: 'sage',   title: 'Trivia Sage', description: 'Elite mode', tier: 3, cost: 3, effects: {'eliteAccess': 1}, category: SkillCategory.Scholar),
  ];
  final edges = [
    SkillEdge(fromId: 'root', toId: 'time1'),
    SkillEdge(fromId: 'root', toId: 'combo1'),
    SkillEdge(fromId: 'time1', toId: 'cat1'),
    SkillEdge(fromId: 'combo1', toId: 'risk1'),
    SkillEdge(fromId: 'cat1', toId: 'sage'),
    SkillEdge(fromId: 'risk1', toId: 'sage'),
  ];
  return SkillTreeController(SkillTreeGraph(nodes: nodes, edges: edges));
});
