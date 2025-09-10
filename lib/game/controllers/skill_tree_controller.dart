import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/skill_effect_handler.dart';
import '../models/skill_tree_graph.dart';
import '../providers/game_session_provider.dart';
import '../providers/profile_service_provider.dart';
import '../providers/skill_cooldown_service_provider.dart';
import '../providers/xp_provider.dart';

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
  }) =>
      SkillTreeState(
        graph: graph ?? this.graph,
        positions: positions ?? this.positions,
        selectedId: selectedId ?? this.selectedId,
        playerPoints: playerPoints ?? this.playerPoints,
      );

  static SkillTreeState empty() =>
      SkillTreeState(graph: const SkillTreeGraph(nodes: [], edges: []), positions: const {}, playerPoints: 0);
}

class SkillTreeController extends StateNotifier<SkillTreeState> {
  final Ref ref;

  /// Optional profile sync hooks (no-ops by default to avoid breaking changes)
  final Future<void> Function(SkillTreeGraph graph)? saveProfile;
  final Future<SkillTreeGraph?> Function()? loadProfile;

  SkillTreeController(
      this.ref, {
        required SkillTreeGraph initialGraph,
        this.saveProfile,
        this.loadProfile,
        int startingPoints = 5,
      }) : super(SkillTreeState(
          graph: initialGraph,
          positions: const {},
          playerPoints: startingPoints, // example starting points
        )) {
    _computeLayout();
    _restoreProfile();
  }

  /// Swap in a new graph (e.g., a branch). Optionally recompute layout.
  void loadGraph(SkillTreeGraph newGraph, {bool recomputeLayout = true}) {
    state = state.copyWith(graph: newGraph, selectedId: null);
    if (recomputeLayout) {
      _computeLayout();
    }
  }

  // ---- Reload Graph ----
  void replaceGraph(SkillTreeGraph g) {
    state = state.copyWith(graph: g);
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

  // ----- Selection -----
  void select(String? id) => state = state.copyWith(selectedId: id);

  // ----- Legacy unlock by points (kept to avoid breaking changes) -----
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

  /// Legacy points-based unlock (kept). Consider migrating calls to 'unlockSkill'.
  void unlock(String id) {
    if (!canUnlock(id)) return;
    final updated = state.graph.nodes.map((n) {
      if (n.id == id) return n.copyWith(unlocked: true);
      return n;
    }).toList();

    final newGraph = SkillTreeGraph(nodes: updated, edges: state.graph.edges);
    state = state.copyWith(
      graph: newGraph,
      playerPoints: state.playerPoints - state.graph.byId[id]!.cost,
    );
    _persistProfile();
  }

  // ----- XP-based unlock via XPService (requested path) -----
  void unlockSkill(String nodeId) {
    final node = state.graph.getNodeById(nodeId);
    if (node == null || node.unlocked) return;

    // If you require "available" gating by edges/tier:
    if (!node.available && node.tier > 0) {
      // Allow unlocking only if prerequisites are unlocked
      final prereqs = state.graph.edges
          .where((e) => e.toId == nodeId)
          .map((e) => state.graph.byId[e.fromId])
          .whereType<SkillNode>()
          .toList();
      final canByPrereq = prereqs.isEmpty || prereqs.every((p) => p.unlocked);
      if (!canByPrereq) return;
    }

    // XPService usage
    final xpService = ref.read(xpServiceProvider);
    final currentXP = xpService.playerXP; // or currentXP depending on your API
    if (currentXP < node.cost) return;

    // Deduct XP
    xpService.deductXP(node.cost);

    // Unlock node + mark children as available
    final updatedNodes = state.graph.nodes.map((n) {
      if (n.id == nodeId) return n.copyWith(unlocked: true, available: true);
      if (state.graph.edges.any((e) => e.fromId == nodeId && e.toId == n.id)) {
        return n.copyWith(available: true);
      }
      return n;
    }).toList();

    final newGraph = SkillTreeGraph(nodes: updatedNodes, edges: state.graph.edges);
    state = state.copyWith(graph: newGraph, selectedId: nodeId);
    _persistProfile();
  }

  // ----- Use/trigger a skill via SkillEffectHandler -----
  /// Preferred entry: pass the actual node (UI usually has it).
  bool useSkill(SkillNode node) {
    if (!node.unlocked) return false;

    final handler = SkillEffectHandler(
      gameSession: ref.read(gameSessionProvider),
      xpService: ref.read(xpServiceProvider),
      profileService: ref.read(profileServiceProvider),
      cooldownService: ref.read(skillCooldownServiceProvider),
    );

    final ok = handler.triggerSkill(node);
    if (!ok) return false;

    // If your model uses lastUsed/cooldown fields on nodes, update them here.
    final updatedNodes = state.graph.nodes.map((n) {
      if (n.id != node.id) return n;
      // Preserve cooldown if you store it on the node (optional)
      return n.copyWith(
        // lastUsed: DateTime.now(), // uncomment if your SkillNode supports it
      );
    }).toList();

    state = state.copyWith(
      graph: SkillTreeGraph(nodes: updatedNodes, edges: state.graph.edges),
      selectedId: node.id,
    );
    _persistProfile();
    return true;
  }

  /// Convenience: use by id (keeps old API style)
  bool useSkillById(String nodeId) {
    final node = state.graph.getNodeById(nodeId);
    if (node == null) return false;
    return useSkill(node);
  }

  /// Backwards-compat alias (if your UI still calls `triggerSkill`)
  bool triggerSkill(String nodeId) => useSkillById(nodeId);

  // ----- Respec -----
  void respec() {
    final refunded = state.graph.nodes.where((n) => n.unlocked).fold<int>(
      0,
          (sum, n) => sum + (n.cost / 2).floor(),
    );
    final reset = [
      for (final n in state.graph.nodes) n.copyWith(unlocked: false, available: n.tier == 0),
    ];
    state = state.copyWith(
      graph: SkillTreeGraph(nodes: reset, edges: state.graph.edges),
      playerPoints: state.playerPoints + refunded,
      selectedId: null,
    );
    _persistProfile();
  }

  // ----- Positions -----
  void updatePositions(Map<String, Offset> updated) {
    final merged = Map<String, Offset>.from(state.positions)..addAll(updated);

    // If we are in the middle of a frame build, defer to after the frame.
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuildingPhase = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (isBuildingPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          state = state.copyWith(positions: merged);
        }
      });
    } else {
      state = state.copyWith(positions: merged);
    }
    _persistProfile();
  }

  // ----- Profile Sync (optional, safe no-op if not provided) -----
  Future<void> _restoreProfile() async {
    if (loadProfile == null) return;
    try {
      final loaded = await loadProfile!.call();
      if (loaded == null) return;
      state = state.copyWith(graph: loaded);
    } catch (_) {
      // ignore to avoid breaking
    }
  }

  Future<void> _persistProfile() async {
    if (saveProfile == null) return;
    try {
      await saveProfile!.call(state.graph);
    } catch (_) {
      // ignore to avoid breaking
    }
  }
}

// ---------------- Provider ----------------

final skillTreeProvider =
StateNotifierProvider<SkillTreeController, SkillTreeState>((ref) {
  // Demo data:
  final nodes = [
    SkillNode(
      id: 'root',
      title: 'Quick Learner',
      description: '+10% XP',
      tier: 0,
      cost: 1,
      effects: {'xpBoost': 0.1},
      category: SkillCategory.xp,
      available: true, // usually root/tier 0 is available
    ),
    SkillNode(
      id: 'time1',
      title: 'Steady Timer',
      description: '+5s',
      tier: 1,
      cost: 1,
      effects: {'timeBonusSec': 5},
      category: SkillCategory.strategist,
    ),
    SkillNode(
      id: 'combo1',
      title: 'Combo Starter',
      description: 'Streak x1.2',
      tier: 1,
      cost: 1,
      effects: {'streakMult': 1.2},
      category: SkillCategory.strategist,
    ),
    SkillNode(
      id: 'cat1',
      title: 'Sports Expert',
      description: '+10% Sports',
      tier: 2,
      cost: 2,
      effects: {'sportsScoreBoost': 0.1},
      category: SkillCategory.scholar,
    ),
    SkillNode(
      id: 'risk1',
      title: 'Risk Taker',
      description: 'Hard Q bonus',
      tier: 2,
      cost: 2,
      effects: {'hardBonus': 0.15},
      category: SkillCategory.xp,
    ),
    SkillNode(
      id: 'sage',
      title: 'Trivia Sage',
      description: 'Elite mode',
      tier: 3,
      cost: 3,
      effects: {'eliteAccess': 1},
      category: SkillCategory.scholar,
    ),
  ];

  final edges = [
    SkillEdge(fromId: 'root', toId: 'time1'),
    SkillEdge(fromId: 'root', toId: 'combo1'),
    SkillEdge(fromId: 'time1', toId: 'cat1'),
    SkillEdge(fromId: 'combo1', toId: 'risk1'),
    SkillEdge(fromId: 'cat1', toId: 'sage'),
    SkillEdge(fromId: 'risk1', toId: 'sage'),
  ];

  return SkillTreeController(
    ref,
    initialGraph: SkillTreeGraph(nodes: nodes, edges: edges),
    // Optional: pass persistence hooks if you have a profile service ready.
    // saveProfile: (g) => ref.read(profileServiceProvider).saveSkillGraph(g),
    // loadProfile: () => ref.read(profileServiceProvider).loadSkillGraph(),
  );
});
