import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:trivia_tycoon/screens/skills_tree/render/skill_tree_painter.dart';
import '../../../ui_components/hex_grid/paint/hex_spider_background_painter.dart';
import '../../../ui_components/hex_grid/paint/auto_path_overlay_painter.dart';
import '../../core/theme/hex_spider_theme.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../game/planning/skill_branch_path_planner.dart';
import '../../game/providers/branch_path_providers.dart';
import '../../game/providers/skill_cooldown_service_provider.dart';
import '../../game/providers/skill_tree_provider.dart';
import '../../game/providers/xp_provider.dart';
import '../../ui_components/hex_grid/math/hex_orientation.dart';

class SkillBranchDetailScreen extends ConsumerStatefulWidget {
  final String branchId;
  final int? initialStep;
  final bool showPathInitially;

  const SkillBranchDetailScreen({
    super.key,
    required this.branchId,
    this.initialStep,
    this.showPathInitially = false,
  });

  @override
  ConsumerState<SkillBranchDetailScreen> createState() =>
      _SkillBranchDetailScreenState();
}

class _SkillBranchDetailScreenState
    extends ConsumerState<SkillBranchDetailScreen> {
  final TransformationController _transform = TransformationController();
  late final ScrollController _listCtrl;
  static const double _nodeRadius = 40;
  /// Radius used for the fallback circle layout when node positions are absent.
  static const double _fallbackLayoutRadius = 260.0;

  String? _focusedId;
  bool _showPath = false;
  int _pathIndex = 0;
  bool _stepClampPending = false;

  /// Overlay state management (ValueNotifiers for reactive updates)
  final ValueNotifier<bool> _showFullPath = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentStep = ValueNotifier<int>(0);
  final ValueNotifier<int> _cooldownTick = ValueNotifier<int>(0);
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _transform.value = vmath.Matrix4.identity()..scale(0.9, 0.9);
    _showPath = widget.showPathInitially;
    if (widget.initialStep != null)
      _pathIndex = widget.initialStep!.clamp(0, 9999);

    _listCtrl = ScrollController();
    _cooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _cooldownTick.value++);

    // Defer parsing query params until we have context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromQueryParamsIfNeeded();
      // Clamp initial step index to the provider-derived path length.
      _clampStepIndex(ref.read(branchAutoPathProvider(widget.branchId)));
      setState(() {});
    });

    Future.microtask(() {
      final args = GoRouterState.of(context).extra as BranchDetailArgs?;
      if (args?.initialStep != null) {
        _listCtrl.jumpTo((args!.initialStep!) * 88.0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hydrate from query params if present (additional safety)
    try {
      final qs = GoRouterState.of(context).uri.queryParameters;
      final step = int.tryParse(qs['step'] ?? '') ?? 0;
      final showPath = (qs['showPath'] ?? '0') == '1';
      _currentStep.value = step < 0 ? 0 : step;
      _showFullPath.value = showPath;
      // Sync with existing state
      _pathIndex = _currentStep.value;
      _showPath = _showFullPath.value;
    } catch (_) {
      // Safe fallback (no-op)
    }
  }

  void _hydrateFromQueryParamsIfNeeded() {
    // If caller passed explicit values, prefer those
    int? step = widget.initialStep;
    bool? show = widget.showPathInitially ? true : null;

    // Otherwise parse from router location
    final loc =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final uri = Uri.tryParse(loc);
    if (uri != null) {
      step ??= int.tryParse(uri.queryParameters['step'] ?? '');
      final sp = uri.queryParameters['showPath'];
      show ??= (sp == '1' || sp?.toLowerCase() == 'true');
    }

    if (step != null) {
      _pathIndex = math.max(0, step);
      _currentStep.value = _pathIndex;
    }
    if (show != null) {
      _showPath = show;
      _showFullPath.value = show;
    }
  }

  /// Clamps `_pathIndex` and `_currentStep` to the valid range for [pathIds].
  /// Safe to call outside of `build()` (e.g. from a post-frame callback or
  /// `initState`). Sets state and ValueNotifier only when the value changes.
  void _clampStepIndex(List<String> pathIds) {
    if (!mounted || pathIds.isEmpty || _pathIndex < pathIds.length) return;
    final clamped = pathIds.length - 1;
    setState(() => _pathIndex = clamped);
    _currentStep.value = clamped;
  }

  @override
  void dispose() {
    _stepClampPending = false;
    _transform.dispose();
    _listCtrl.dispose();
    _showFullPath.dispose();
    _currentStep.dispose();
    _cooldownTimer?.cancel();
    _cooldownTick.dispose();
    super.dispose();
  }

  // Build VM using the centralized planner.
  // [playerXP] comes from playerXPProvider so unlock eligibility reflects real
  // XP rather than the legacy playerPoints counter.
  BranchDetailVM _buildVM(SkillTreeState state, {required int playerXP}) {
    final planner = SkillBranchPathPlanner.fromGraph(state.graph);
    final orderedNodes = planner.forBranch(widget.branchId);
    final order = orderedNodes.map((n) => n.id).toList();

    final unlockedMap = <String, bool>{
      for (final n in state.graph.nodes) n.id: n.unlocked
    };

    final canUnlock = <String, bool>{
      for (final id in order)
        id: _canUnlockNow(
            state.graph, id, unlockedMap, playerXP, state.graph.byId[id]!.cost)
    };

    return BranchDetailVM(
        branchId: widget.branchId,
        nodes: orderedNodes,
        order: order,
        canUnlock: canUnlock);
  }

  bool _canUnlockNow(SkillTreeGraph graph, String id,
      Map<String, bool> unlocked, int xp, int cost) {
    if (unlocked[id] == true) return false;
    final prereqs = graph.edges.where((e) => e.toId == id).map((e) => e.fromId);
    final ready = prereqs.isEmpty || prereqs.every((p) => unlocked[p] == true);
    return ready && xp >= cost;
  }

  Map<String, Offset> _filterPositions(
      Map<String, Offset> all, SkillTreeGraph filtered) {
    final ids = filtered.nodes.map((n) => n.id).toSet();
    final out = <String, Offset>{};
    for (final id in ids) {
      final p = all[id];
      if (p != null) {
        out[id] = p;
      }
    }
    // If some nodes have no saved layout yet, place them in a quick circle.
    if (out.length < filtered.nodes.length) {
      final missing =
          filtered.nodes.where((n) => !out.containsKey(n.id)).toList();
      for (int i = 0; i < missing.length; i++) {
        final a = (i / math.max(1, missing.length)) * 2 * math.pi;
        out[missing[i].id] = Offset(
          _fallbackLayoutRadius * math.cos(a),
          _fallbackLayoutRadius * math.sin(a),
        );
      }
    }
    return out;
  }

  /// Computes screen-space centers for overlay painting from world positions.
  /// Returns a fresh map; does not mutate any field.
  Map<String, Offset> _computeCenters(
      Map<String, Offset> all, SkillTreeGraph filtered) {
    final ids = filtered.nodes.map((n) => n.id).toSet();
    final centers = <String, Offset>{};
    for (final id in ids) {
      final p = all[id];
      if (p != null) {
        centers[id] = _transformPoint(_transform.value, p);
      }
    }
    // Fallback circle for nodes missing a saved position.
    if (centers.length < filtered.nodes.length) {
      final missing =
          filtered.nodes.where((n) => !centers.containsKey(n.id)).toList();
      for (int i = 0; i < missing.length; i++) {
        final a = (i / math.max(1, missing.length)) * 2 * math.pi;
        final worldPos = Offset(
          _fallbackLayoutRadius * math.cos(a),
          _fallbackLayoutRadius * math.sin(a),
        );
        centers[missing[i].id] = _transformPoint(_transform.value, worldPos);
      }
    }
    return centers;
  }

  // Delegates to the unified XP-based unlock path (handles prereqs + server sync).
  void _unlockSkill(String nodeId) {
    ref.read(skillTreeProvider.notifier).unlockSkill(nodeId);
  }

  // Hit-test helpers
  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  String? _hitTestNode(Offset localPos, Map<String, Offset> positions,
      vmath.Matrix4 worldToScreen) {
    final inv = vmath.Matrix4.inverted(worldToScreen);
    final world = _transformPoint(inv, localPos);
    for (final entry in positions.entries) {
      if ((entry.value - world).distance <= _nodeRadius + 8) {
        return entry.key;
      }
    }
    return null;
  }

  void _handleTapDown(TapDownDetails d, Map<String, Offset> positions) {
    final ctrl = ref.read(skillTreeProvider.notifier);
    final id = _hitTestNode(d.localPosition, positions, _transform.value);
    ctrl.select(id);
    setState(() => _focusedId = id);
  }

  void _handleUnlockSelected() {
    final state = ref.read(skillTreeProvider);
    final selected = state.selectedId;
    if (selected != null) {
      _unlockSkill(selected);
    }
  }

  void _goToStep(int i) {
    final pathIds = ref.read(branchAutoPathProvider(widget.branchId));
    if (pathIds.isEmpty) return;
    final newStep = i.clamp(0, pathIds.length - 1);
    final nodeId = pathIds[newStep];
    ref.read(skillTreeProvider.notifier).select(nodeId);
    setState(() {
      _pathIndex = newStep;
      _currentStep.value = newStep; // Sync ValueNotifier
      _focusedId = nodeId;
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showPath = !_showPath;
      _showFullPath.value = _showPath; // Sync ValueNotifier
    });
  }

  void _showAutoPathSheet(BranchDetailVM vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15183A),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended unlock order',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: vm.order.length,
                itemBuilder: (context, i) {
                  final nodeId = vm.order[i];
                  final node = vm.nodes.firstWhere((n) => n.id == nodeId);
                  final canUnlock = vm.canUnlock[nodeId] ?? false;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor:
                          node.unlocked ? Colors.green : Colors.white12,
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(node.title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Cost: ${node.cost} • Tier ${node.tier}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: node.unlocked
                        ? const Icon(Icons.check, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  canUnlock ? Colors.teal : Colors.grey,
                            ),
                            onPressed: canUnlock
                                ? () {
                                    _unlockSkill(node.id);
                                    setState(() => _focusedId = node.id);
                                  }
                                : null,
                            child: const Text('Unlock'),
                          ),
                    onTap: () => setState(() => _focusedId = node.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar({
    required SkillTreeState state,
    required List<String> pathIds,
    required int playerXP,
  }) {
    final total = pathIds.length;
    if (total == 0) return const SizedBox.shrink();

    final safeIndex = _pathIndex.clamp(0, total - 1);
    final nodeId = pathIds[safeIndex];
    final node = state.graph.byId[nodeId];
    if (node == null) return const SizedBox.shrink();

    final cooldowns = ref.watch(skillCooldownServiceProvider);
    return ValueListenableBuilder<int>(
      valueListenable: _cooldownTick,
      builder: (_, __, ___) {
        final onCooldown = cooldowns.isOnCooldown(node.id);
        final prereqIds = state.graph.getPrerequisites(node.id);
        final missingPrereqs = prereqIds
            .map(state.graph.getNodeById)
            .whereType<SkillNode>()
            .where((n) => !n.unlocked)
            .toList();

        final canUnlock =
            !node.unlocked && missingPrereqs.isEmpty && playerXP >= node.cost;
        final canUse = node.unlocked && !onCooldown;
        final canGoBack = safeIndex > 0;
        final canGoNext = safeIndex < total - 1;

        String status;
        if (!node.unlocked && missingPrereqs.isNotEmpty) {
          status = 'Requires: ${missingPrereqs.first.title}';
        } else if (!node.unlocked && playerXP < node.cost) {
          status = 'Need ${node.cost - playerXP} more XP';
        } else if (onCooldown) {
          status = 'Cooldown: ${cooldowns.remainingLabel(node.id)}';
        } else if (node.unlocked) {
          status = 'Ready to use';
        } else {
          status = 'Ready to unlock';
        }

        void handleAction() {
          final notifier = ref.read(skillTreeProvider.notifier);
          final wasUnlocked = node.unlocked;
          bool success;
          if (wasUnlocked) {
            success = notifier.useSkill(node.id);
          } else {
            notifier.unlockSkill(node.id);
            final unlockedAfterAction =
                ref.read(skillTreeProvider).graph.byId[node.id]?.unlocked ==
                    true;
            success = unlockedAfterAction;
          }

          if (!success) return;
          if (safeIndex < total - 1) {
            _goToStep(safeIndex + 1);
          } else {
            notifier.select(node.id);
            setState(() => _focusedId = node.id);
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF15183A),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: canGoBack ? () => _goToStep(safeIndex - 1) : null,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${safeIndex + 1} / $total • ${node.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cost: ${node.cost} XP • $status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canUnlock || canUse ? handleAction : null,
                  child: Text(node.unlocked ? 'Use' : 'Unlock'),
                ),
                IconButton(
                  onPressed: canGoNext ? () => _goToStep(safeIndex + 1) : null,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simple toolbar row to toggle overlay & step for debugging (optional):
  Widget _overlayControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showFullPath,
      builder: (_, show, __) => Row(
        children: [
          Switch(
            value: show,
            onChanged: (v) {
              _showFullPath.value = v;
              setState(() => _showPath = v); // Sync existing state
            },
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: _currentStep,
            builder: (_, step, __) => Row(
              children: [
                IconButton(
                    onPressed: () => _goToStep(step - 1),
                    icon: const Icon(Icons.chevron_left, color: Colors.white)),
                Text('Step $step', style: const TextStyle(color: Colors.white)),
                IconButton(
                    onPressed: () => _goToStep(step + 1),
                    icon: const Icon(Icons.chevron_right, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final playerXP = ref.watch(playerXPProvider);
    final vm = _buildVM(state, playerXP: playerXP);
    final filtered = state.graph.subgraphForBranch(widget.branchId);
    final positions = _filterPositions(state.positions, filtered);

    // Local derived values — no mutations during build.
    final pathIds = ref.watch(branchAutoPathProvider(widget.branchId));
    final centers = _computeCenters(positions, filtered);

    // Clamp step index to current path length via a guarded post-frame callback.
    if (pathIds.isNotEmpty && _pathIndex >= pathIds.length && !_stepClampPending) {
      _stepClampPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stepClampPending = false;
        final latestPathIds = ref.read(branchAutoPathProvider(widget.branchId));
        _clampStepIndex(latestPathIds);
      });
    }

    final currentScale = _transform.value.storage[0];
    final branchColor = _branchColor(widget.branchId);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15183A),
        title: Text(
          '${widget.branchId[0].toUpperCase()}${widget.branchId.substring(1)} Branch',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.alt_route),
            tooltip: 'Auto-path',
            onPressed: () => _showAutoPathSheet(vm),
          ),
          IconButton(
            icon: Icon(_showPath ? Icons.layers_clear : Icons.layers),
            tooltip: _showPath ? 'Hide path' : 'Show path',
            onPressed: _toggleOverlay,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: 'Unlock selected',
            onPressed: _handleUnlockSelected,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        color: const Color(0xFF0D1021),
        child: LayoutBuilder(
          builder: (context, c) {
            final painter = SkillTreePainter(
              graph: filtered,
              positions: positions,
              worldToScreen: _transform.value,
              nodeRadius: _nodeRadius,
              selectedId: state.selectedId,
              unlocked: state.graph.nodes
                  .where((n) => n.unlocked)
                  .map((n) => n.id)
                  .toSet(),
              categoryImages: const <SkillCategory, ui.Image?>{},
              focusedId: _focusedId,
            );

            final backgroundPainter = HexSpiderBackgroundPainter(
              ringCount: 8,
              ringSpacing: 140,
              rayCount: 24,
              hexRadius: _nodeRadius,
              orientation: HexOrientation.pointy,
              scale: currentScale,
              alignToNodes: true,
              worldToScreen: _transform.value,
              positions: positions,
              theme: HexSpiderTheme.brand,
              gridColor: branchColor.withValues(alpha: 0.18),
              ringColor: Colors.white.withValues(alpha: 0.22),
              rayColor: branchColor.withValues(alpha: 0.18),
              baseGridAlpha: 1.0,
              baseRingAlpha: 0.75,
              baseRayAlpha: 0.65,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _handleTapDown(d, positions),
              onDoubleTapDown: (d) {
                final id =
                    _hitTestNode(d.localPosition, positions, _transform.value);
                if (id != null) _unlockSkill(id);
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: backgroundPainter,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      foregroundPainter: painter,
                    ),
                  ),
                  Positioned.fill(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _showFullPath,
                      builder: (_, show, __) => ValueListenableBuilder<int>(
                        valueListenable: _currentStep,
                        builder: (_, step, __) => IgnorePointer(
                          child: CustomPaint(
                            painter: AutoPathOverlayPainter(
                              centers: centers,
                              pathIds: pathIds,
                              currentIndex: step,
                              showFullPath: show,
                              fullPathColor: branchColor.withValues(alpha: 0.4),
                              stepPathColor: branchColor,
                              stepPathWidth: 4.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ZoomPad(
                      onIn: () => setState(() =>
                          _transform.value = _transform.value.scaled(1.15)),
                      onOut: () => setState(() =>
                          _transform.value = _transform.value.scaled(0.87)),
                      onReset: () => setState(() => _transform.value =
                          vmath.Matrix4.identity()..scale(0.9, 0.9)),
                    ),
                  ),
                  // Add overlay controls for debugging (optional)
                  Positioned(
                    left: 12,
                    top: 80,
                    child: _overlayControls(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: pathIds.isEmpty
          ? null
          : _actionBar(
              state: state,
              pathIds: pathIds,
              playerXP: playerXP,
            ),
    );
  }

  Color _branchColor(String id) {
    switch (id.toLowerCase()) {
      case 'combat':
        return const Color(0xFFE74C3C);
      case 'scholar':
        return const Color(0xFF4A90E2);
      case 'strategist':
        return const Color(0xFF9B59B6);
      case 'xp':
        return const Color(0xFF27AE60);
      case 'timer':
        return const Color(0xFF3498DB);
      case 'combo':
        return const Color(0xFFE67E22);
      case 'risk':
        return const Color(0xFFC0392B);
      case 'luck':
        return const Color(0xFFF1C40F);
      case 'stealth':
        return const Color(0xFF34495E);
      case 'knowledge':
        return const Color(0xFF16A085);
      case 'elite':
        return const Color(0xFFFFD700);
      case 'wildcard':
        return const Color(0xFF8E44AD);
      case 'general':
        return const Color(0xFF7F8C8D);
      default:
        return const Color(0xFF6EE7F9);
    }
  }
}

class _ZoomPad extends StatelessWidget {
  final VoidCallback onIn, onOut, onReset;
  const _ZoomPad(
      {required this.onIn, required this.onOut, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF15183A),
      elevation: 3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              onPressed: onIn,
              icon: const Icon(Icons.zoom_in, color: Colors.white)),
          IconButton(
              onPressed: onOut,
              icon: const Icon(Icons.zoom_out, color: Colors.white)),
          IconButton(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
    );
  }
}

class BranchDetailArgs {
  final String branchId;
  final int? initialStep;
  final bool highlightPath;
  const BranchDetailArgs(this.branchId,
      {this.initialStep, this.highlightPath = false});
}

class BranchDetailVM {
  final String branchId;
  final List<SkillNode> nodes;
  final List<String> order;
  final Map<String, bool> canUnlock;

  BranchDetailVM(
      {required this.branchId,
      required this.nodes,
      required this.order,
      required this.canUnlock});
}
