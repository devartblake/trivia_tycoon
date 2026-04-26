import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/skill_effect_handler.dart';
import '../models/skill_tree_graph.dart';
import '../providers/core_providers.dart';
import '../providers/game_providers.dart' show playerProfileServiceProvider;
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

  static SkillTreeState empty() => SkillTreeState(
      graph: const SkillTreeGraph(nodes: [], edges: []),
      positions: const {},
      playerPoints: 0);
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

  // Hex-grid layout: pointy-top axial coordinates, same-category nodes adjacent.
  void _computeLayout() {
    const double hexSize = 120.0;
    final positions = <String, Offset>{};

    // Group by tier; within each tier sort by category then title so
    // nodes of the same branch cluster together in the honeycomb.
    final tiers = List.generate(state.graph.maxTier + 1, (_) => <SkillNode>[]);
    for (final n in state.graph.nodes) {
      tiers[n.tier].add(n);
    }
    for (var t = 0; t < tiers.length; t++) {
      final row = List<SkillNode>.from(tiers[t])
        ..sort((a, b) {
          final c = a.category.name.compareTo(b.category.name);
          return c != 0 ? c : a.title.compareTo(b.title);
        });

      // Compensate for pointy-top axial stagger: x = √3·size·(q + r/2).
      // To keep each row visually centred on x=0: q_start = -(n-1)/2 - t/2.
      final qStart = (-((row.length - 1) / 2.0) - (t / 2.0)).round();
      for (var i = 0; i < row.length; i++) {
        final q = qStart + i;
        final r = t;
        final x = math.sqrt(3) * hexSize * (q + r / 2.0);
        final y = 1.5 * hexSize * r;
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
    final node = state.graph.byId[id];
    if (node == null) return;
    final updated = state.graph.nodes.map((n) {
      if (n.id == id) return n.copyWith(unlocked: true);
      return n;
    }).toList();

    final newGraph = SkillTreeGraph(nodes: updated, edges: state.graph.edges);
    state = state.copyWith(
      graph: newGraph,
      playerPoints: state.playerPoints - node.cost,
    );
    _persistProfile();
    _persistUnlock(id);
  }

  // ----- XP-based unlock via XPService (unified approach) -----
  void unlockSkill(String nodeId) {
    final node = state.graph.getNodeById(nodeId);
    if (node == null || node.unlocked) return;

    // Check prerequisites
    final prereqs = state.graph.edges
        .where((e) => e.toId == nodeId)
        .map((e) => state.graph.byId[e.fromId])
        .whereType<SkillNode>()
        .toList();
    final canByPrereq = prereqs.isEmpty || prereqs.every((p) => p.unlocked);
    if (!canByPrereq) return;

    // XPService usage with fallback to points
    try {
      final xpService = ref.read(xpServiceProvider);
      final currentXP = xpService.playerXP;
      if (currentXP < node.cost) return;

      // Deduct XP through service
      xpService.deductXP(node.cost);
    } catch (_) {
      // Fallback to points system if XP service unavailable
      if (state.playerPoints < node.cost) return;
    }

    // Unlock node + mark children as available
    final updatedNodes = state.graph.nodes.map((n) {
      if (n.id == nodeId) return n.copyWith(unlocked: true, available: true);
      if (state.graph.edges.any((e) => e.fromId == nodeId && e.toId == n.id)) {
        return n.copyWith(available: true);
      }
      return n;
    }).toList();

    final newGraph =
        SkillTreeGraph(nodes: updatedNodes, edges: state.graph.edges);

    // Update state (deduct points only if XP service failed)
    try {
      ref.read(xpServiceProvider);
      state = state.copyWith(graph: newGraph, selectedId: nodeId);
    } catch (_) {
      state = state.copyWith(
        graph: newGraph,
        selectedId: nodeId,
        playerPoints: state.playerPoints - node.cost,
      );
    }

    _persistProfile();
    _persistUnlock(nodeId);
  }

  // ----- Unified skill usage through SkillEffectHandler -----
  /// Primary method: Use skill with full service integration
  bool useSkill(String nodeId) {
    final node = state.graph.getNodeById(nodeId);
    if (node == null || !node.unlocked) return false;

    // Check cooldown through service
    try {
      final cooldownService = ref.read(skillCooldownServiceProvider);
      if (cooldownService.isOnCooldown(nodeId)) return false;
    } catch (_) {
      // Fallback to node-level cooldown check
      if (node.isOnCooldown) return false;
    }

    // Route through SkillEffectHandler for unified effect processing
    try {
      final handler = SkillEffectHandler(
        gameSession: ref.read(gameSessionProvider),
        xpService: ref.read(xpServiceProvider),
        profileService: ref.read(profileServiceProvider),
        cooldownService: ref.read(skillCooldownServiceProvider),
      );

      final success = handler.triggerSkill(node);
      if (!success) return false;

      // Update node state with usage timestamp
      final updatedNodes = state.graph.nodes.map((n) {
        if (n.id != node.id) return n;
        return n.copyWith(lastUsed: DateTime.now());
      }).toList();

      state = state.copyWith(
        graph: SkillTreeGraph(nodes: updatedNodes, edges: state.graph.edges),
        selectedId: nodeId,
      );

      _persistProfile();
      return true;
    } catch (_) {
      // Fallback for when services aren't available
      return false;
    }
  }

  /// Convenience method: Use skill with node object (for UI that has the node)
  bool useSkillNode(SkillNode node) {
    return useSkill(node.id);
  }

  // ----- Respec -----
  void respec() {
    final refunded = state.graph.nodes.where((n) => n.unlocked).fold<int>(
          0,
          (sum, n) => sum + (n.cost / 2).floor(),
        );
    final reset = [
      for (final n in state.graph.nodes)
        n.copyWith(unlocked: false, available: n.tier == 0),
    ];

    // Try to refund through XP service, fallback to points
    try {
      final xpService = ref.read(xpServiceProvider);
      xpService.addXP(refunded);
      state = state.copyWith(
        graph: SkillTreeGraph(nodes: reset, edges: state.graph.edges),
        selectedId: null,
      );
    } catch (_) {
      // Fallback to points system
      state = state.copyWith(
        graph: SkillTreeGraph(nodes: reset, edges: state.graph.edges),
        playerPoints: state.playerPoints + refunded,
        selectedId: null,
      );
    }

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

  // ----- Server Sync -----

  /// Fire-and-forget API call to persist an unlocked node to the server.
  /// Local state is already updated optimistically; server will re-sync on
  /// the next app launch. All errors are swallowed — do not revert local state.
  void _persistUnlock(String nodeId) {
    try {
      ref.read(playerProfileServiceProvider).getUserId().then((userId) {
        if (userId == null || userId.isEmpty) return;
        unawaited(() async {
          try {
            await ref
                .read(serviceManagerProvider)
                .synaptixApiClient
                .unlockSkillNode(playerId: userId, nodeId: nodeId);
          } catch (_) {
            // Log only — local state is source of truth until next server sync
          }
        }());
      });
    } catch (_) {
      // Service unavailable (e.g., test environment) — skip server sync
    }
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
