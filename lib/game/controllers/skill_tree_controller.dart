import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/hex_grid/index.dart';
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

  // True axial hex grid layout: master_hub at world origin (0,0),
  // 12 branch roots at ring-2, each branch extends outward in one of 6 directions.
  void _computeLayout() {
    // Each node's (q, r) axial coordinate on a pointy-top hex grid.
    // Ring-2 has exactly 12 cells — one per branch root.
    const nodeAxial = <String, Coordinates>{
      'master_hub':        Coordinates(0,  0),
      // Scholar → NE (1,-1)
      'sch_root':          Coordinates(2, -2),
      'sch_faster_hint':   Coordinates(3, -3),
      'sch_double_hint':   Coordinates(4, -4),
      'sch_sage':          Coordinates(5, -5),
      // Strategist → E (1,0)
      'str_root':          Coordinates(2, -1),
      'str_combo':         Coordinates(3, -1),
      'lifeline_cooldown': Coordinates(4, -1),
      'str_master':        Coordinates(5, -1),
      // Combat → E (1,0)
      'combat_root':       Coordinates(2,  0),
      'combat_eraser':     Coordinates(3,  0),
      'combat_glitch':     Coordinates(4,  0),
      // XP → SE (0,1)
      'xp_root':           Coordinates(1,  1),
      'xp_boost_2':        Coordinates(1,  2),
      'xp_burst':          Coordinates(1,  3),
      'xp_grandmaster':    Coordinates(1,  4),
      // Timer → SE (0,1)
      'timer_root':        Coordinates(0,  2),
      'timer_freeze':      Coordinates(0,  3),
      'timer_power_play':  Coordinates(0,  4),
      // Combo → SW (-1,1)
      'combo_root':        Coordinates(-1,  2),
      'combo_booster':     Coordinates(-2,  3),
      'combo_gift':        Coordinates(-3,  4),
      // Risk → SW (-1,1)
      'risk_root':         Coordinates(-2,  2),
      'risk_multiplier':   Coordinates(-3,  3),
      'risk_supersonic':   Coordinates(-4,  4),
      // Luck → W (-1,0)
      'luck_root':         Coordinates(-2,  1),
      'luck_immunity':     Coordinates(-3,  1),
      'luck_streak_saver': Coordinates(-4,  1),
      // Stealth → W (-1,0)
      'stealth_root':      Coordinates(-2,  0),
      'stealth_phantom':   Coordinates(-3,  0),
      'stealth_decoy':     Coordinates(-4,  0),
      // Knowledge → NW (0,-1)
      'know_root':         Coordinates(-1, -1),
      'know_specialist':   Coordinates(-1, -2),
      'know_polymath':     Coordinates(-1, -3),
      // Wildcard → NW (0,-1)
      'wild_root':         Coordinates(0, -2),
      'wild_chaos':        Coordinates(0, -3),
      // General → NE (1,-1)
      'gen_root':          Coordinates(1, -2),
      'gen_versatile':     Coordinates(2, -3),
      // Elite (cross-branch child of sch_sage + str_master) → continues NE
      'elite_root':        Coordinates(6, -6),
      'elite_scholar':     Coordinates(7, -7),
      'elite_strategist':  Coordinates(7, -6),
    };

    const double hexSize = 100.0;
    final graph = state.graph;
    if (graph.nodes.isEmpty) return;

    final positions = <String, Offset>{};
    final placed = <String>{};

    // Place all nodes with known axial coordinates.
    for (final node in graph.nodes) {
      final axial = nodeAxial[node.id];
      if (axial != null) {
        positions[node.id] = HexMetrics.axialToPixel(
            axial.q, axial.r, hexSize, HexOrientation.pointy);
        placed.add(node.id);
      }
    }

    // Fallback radial BFS for any nodes not in the lookup table.
    final unplaced = graph.nodes.where((n) => !placed.contains(n.id)).toList();
    if (unplaced.isNotEmpty) {
      const double radialStep = 280.0;
      final maxR = positions.isEmpty
          ? 0.0
          : positions.values.map((o) => o.distance).reduce(math.max);
      final fallbackR = maxR + radialStep;
      final step = 2 * math.pi / unplaced.length;
      for (int i = 0; i < unplaced.length; i++) {
        final angle = -math.pi / 2 + i * step;
        positions[unplaced[i].id] = Offset(
          math.cos(angle) * fallbackR,
          math.sin(angle) * fallbackR,
        );
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
    _persistUnlockedSkillIds();
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

      // Deduct XP through service and keep the reactive provider in sync.
      xpService.deductXP(node.cost);
      ref.read(playerXPProvider.notifier).state = xpService.playerXP;
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
    _persistUnlockedSkillIds();
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

      // Keep reactive XP state in sync for skills that consume XP on use.
      ref.read(playerXPProvider.notifier).state =
          ref.read(xpServiceProvider).playerXP;

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
      _persistUseSkill(nodeId);
      _persistSkillCooldowns();
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
      xpService.addXP(refunded, applyMultiplier: false);
      ref.read(playerXPProvider.notifier).state = xpService.playerXP;
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
    _persistUnlockedSkillIds();
    _persistRespec();
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

  /// Fire-and-forget: records a skill activation on the server.
  void _persistUseSkill(String nodeId) {
    try {
      ref.read(playerProfileServiceProvider).getUserId().then((userId) {
        if (userId == null || userId.isEmpty) return;
        unawaited(() async {
          try {
            await ref
                .read(serviceManagerProvider)
                .synaptixApiClient
                .useSkillNode(playerId: userId, nodeId: nodeId);
          } catch (_) {}
        }());
      });
    } catch (_) {}
  }

  /// Fire-and-forget: notifies the server that the player has respecced.
  void _persistRespec() {
    try {
      ref.read(playerProfileServiceProvider).getUserId().then((userId) {
        if (userId == null || userId.isEmpty) return;
        unawaited(() async {
          try {
            await ref
                .read(serviceManagerProvider)
                .synaptixApiClient
                .respecSkillTree(playerId: userId);
          } catch (_) {}
        }());
      });
    } catch (_) {}
  }

  // ----- Profile Sync (optional, safe no-op if not provided) -----
  Future<void> _restoreProfile() async {
    // Restore via optional callback first (backward compat).
    if (loadProfile != null) {
      try {
        final loaded = await loadProfile!.call();
        if (loaded != null) {
          state = state.copyWith(graph: loaded);
          return;
        }
      } catch (_) {
        // ignore to avoid breaking
      }
    }

    // Restore cooldown end timestamps from storage.
    try {
      await ref.read(skillCooldownServiceProvider).restoreCooldowns();
    } catch (_) {}

    // Restore unlocked skill IDs from ProfileService and apply to graph.
    try {
      final profileService = ref.read(profileServiceProvider);
      final unlockedIds = await profileService.loadUnlockedSkillIds();
      if (unlockedIds.isNotEmpty) {
        state = state.copyWith(
          graph: state.graph.withUnlockedIds(unlockedIds),
        );
      }
    } catch (_) {}

    // Sync reactive XP provider from XPService (which loads from storage).
    try {
      final xpService = ref.read(xpServiceProvider);
      ref.read(playerXPProvider.notifier).state = xpService.playerXP;
    } catch (_) {}
  }

  Future<void> _persistProfile() async {
    if (saveProfile == null) return;
    try {
      await saveProfile!.call(state.graph);
    } catch (_) {
      // ignore to avoid breaking
    }
  }

  /// Fire-and-forget: saves the current set of unlocked skill IDs to ProfileService.
  void _persistUnlockedSkillIds() {
    try {
      final ids = state.graph.unlockedNodes.map((n) => n.id).toList();
      unawaited(
        ref
            .read(profileServiceProvider)
            .saveUnlockedSkillIds(ids)
            .catchError((_) {}),
      );
    } catch (_) {}
  }

  /// Fire-and-forget: persists active cooldown end timestamps to storage.
  void _persistSkillCooldowns() {
    try {
      unawaited(
        ref
            .read(skillCooldownServiceProvider)
            .persistCooldowns()
            .catchError((_) {}),
      );
    } catch (_) {}
  }
}
