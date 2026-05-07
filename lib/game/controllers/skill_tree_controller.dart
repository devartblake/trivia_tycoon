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

  // Radial BFS layout: master_hub at world origin, branches radiate outward.
  void _computeLayout() {
    const double nodeSize = 144.0; // world-pixel diameter of each node (2 * _nodeRadius)
    const double radialStep = 280.0; // world-pixel gap between successive rings
    final positions = <String, Offset>{};
    final graph = state.graph;

    if (graph.nodes.isEmpty) return;

    // Find the hub node (the root with no incoming edges, preferring master_hub).
    final hasIncoming = graph.edges.map((e) => e.toId).toSet();
    final SkillNode hub = graph.nodes.firstWhere(
      (n) => n.id == 'master_hub',
      orElse: () => graph.nodes.firstWhere(
        (n) => !hasIncoming.contains(n.id),
        orElse: () => graph.nodes.first,
      ),
    );

    positions[hub.id] = Offset.zero;

    // Collect direct children of hub and compute first-ring radius such that
    // adjacent nodes are at least nodeSize apart.
    final hubChildren = graph.edges
        .where((e) => e.fromId == hub.id)
        .map((e) => e.toId)
        .toList();

    if (hubChildren.isEmpty) {
      state = state.copyWith(positions: positions);
      return;
    }

    final n = hubChildren.length;
    final r0 = n == 1
        ? radialStep
        : math.max(radialStep, nodeSize / (2 * math.sin(math.pi / n)));

    // BFS queue: (nodeId, centerAngle, angularSpread, radius)
    final queue = <_LayoutEntry>[];
    final placed = <String>{hub.id};

    if (n == 1) {
      queue.add(_LayoutEntry(hubChildren[0], -math.pi / 2, 2 * math.pi, r0));
    } else {
      final angleStep = 2 * math.pi / n;
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        queue.add(_LayoutEntry(hubChildren[i], angle, angleStep, r0));
      }
    }

    while (queue.isNotEmpty) {
      final entry = queue.removeAt(0);
      if (placed.contains(entry.nodeId)) continue;
      placed.add(entry.nodeId);

      positions[entry.nodeId] = Offset(
        math.cos(entry.angle) * entry.radius,
        math.sin(entry.angle) * entry.radius,
      );

      final children = graph.edges
          .where((e) => e.fromId == entry.nodeId && !placed.contains(e.toId))
          .map((e) => e.toId)
          .toList();

      if (children.isEmpty) continue;

      final spread = math.min(entry.spread, 2 * math.pi / 3);
      final childSpread = spread / children.length;
      final nextRadius = entry.radius + radialStep;

      for (int i = 0; i < children.length; i++) {
        final childAngle =
            entry.angle - spread / 2 + childSpread / 2 + i * childSpread;
        queue.add(_LayoutEntry(children[i], childAngle, childSpread, nextRadius));
      }
    }

    // Fallback: place any graph nodes unreachable from hub in an outer ring.
    final unplaced = graph.nodes.where((n) => !placed.contains(n.id)).toList();
    if (unplaced.isNotEmpty) {
      final maxR = positions.values.map((o) => o.distance).reduce(math.max);
      final fallbackR = maxR + radialStep;
      final step = 2 * math.pi / unplaced.length;
      for (int i = 0; i < unplaced.length; i++) {
        positions[unplaced[i].id] = Offset(
          math.cos(i * step) * fallbackR,
          math.sin(i * step) * fallbackR,
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

class _LayoutEntry {
  final String nodeId;
  final double angle;
  final double spread;
  final double radius;
  const _LayoutEntry(this.nodeId, this.angle, this.spread, this.radius);
}
