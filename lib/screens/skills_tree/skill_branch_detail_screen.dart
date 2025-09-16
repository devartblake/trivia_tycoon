import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:trivia_tycoon/screens/skills_tree/render/skill_tree_painter.dart';
import '../../../ui_components/hex_grid/paint/hex_spider_background_painter.dart';
import '../../../ui_components/hex_grid/paint/auto_path_overlay_painter.dart'; // New import
import '../../core/theme/hex_spider_theme.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../game/planning/skill_branch_path_planner.dart';
import '../../ui_components/hex_grid/math/hex_orientation.dart';
import '../../ui_components/hex_grid/paint/branch_path_overlay_painter.dart';

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
  ConsumerState<SkillBranchDetailScreen> createState() => _SkillBranchDetailScreenState();
}

class _SkillBranchDetailScreenState extends ConsumerState<SkillBranchDetailScreen> {
  final TransformationController _transform = TransformationController();
  late final ScrollController _listCtrl;
  static const double _nodeRadius = 40;

  String? _focusedId;
  bool _showPath = false;
  int _pathIndex = 0;
  List<String> _computedPath = [];

  /// New overlay state management (ValueNotifiers for reactive updates)
  final ValueNotifier<bool> _showFullPath = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentStep = ValueNotifier<int>(0);

  /// Captured screen-space centers for overlay painter
  final Map<String, Offset> _centers = <String, Offset>{};
  List<String> _pathIds = const [];

  @override
  void initState() {
    super.initState();
    _transform.value = vmath.Matrix4.identity()..scale(0.9, 0.9);
    _showPath = widget.showPathInitially;
    if (widget.initialStep != null) _pathIndex = widget.initialStep!.clamp(0, 9999);

    _listCtrl = ScrollController();

    // Defer parsing query params until we have context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromQueryParamsIfNeeded();
      _recomputePath();
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
    final loc = GoRouter.of(context).routeInformationProvider.value.uri.toString();
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

  void _recomputePath() {
    final state = ref.read(skillTreeProvider);
    // Use the new centralized planner
    final planner = SkillBranchPathPlanner.fromGraph(state.graph);
    final orderedNodes = planner.forBranch(widget.branchId);
    _computedPath = orderedNodes.map((n) => n.id).toList();
    _pathIds = _computedPath; // Sync with overlay

    if (_pathIndex >= _computedPath.length) {
      _pathIndex = _computedPath.isEmpty ? 0 : _computedPath.length - 1;
      _currentStep.value = _pathIndex;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _listCtrl.dispose();
    _showFullPath.dispose();
    _currentStep.dispose();
    super.dispose();
  }

  // Build VM using the centralized planner
  BranchDetailVM _buildVM(SkillTreeState state) {
    final planner = SkillBranchPathPlanner.fromGraph(state.graph);
    final orderedNodes = planner.forBranch(widget.branchId);
    final order = orderedNodes.map((n) => n.id).toList();

    final unlocked = <String, bool>{
      for (final n in state.graph.nodes) n.id: n.unlocked
    };

    final canUnlock = <String, bool>{
      for (final id in order)
        id: _canUnlockNow(state.graph, id, unlocked, state.playerPoints, state.graph.byId[id]!.cost)
    };

    return BranchDetailVM(
        branchId: widget.branchId,
        nodes: orderedNodes,
        order: order,
        canUnlock: canUnlock
    );
  }

  bool _canUnlockNow(SkillTreeGraph graph, String id, Map<String, bool> unlocked, int xp, int cost) {
    if (unlocked[id] == true) return false;
    final prereqs = graph.edges.where((e) => e.toId == id).map((e) => e.fromId);
    final ready = prereqs.isEmpty || prereqs.every((p) => unlocked[p] == true);
    return ready && xp >= cost;
  }

  Map<String, Offset> _filterPositions(Map<String, Offset> all, SkillTreeGraph filtered) {
    final ids = filtered.nodes.map((n) => n.id).toSet();
    final out = <String, Offset>{};
    for (final id in ids) {
      final p = all[id];
      if (p != null) {
        out[id] = p;
        // Capture screen-space centers for overlay (transform to screen space)
        final screenPos = _transformPoint(_transform.value, p);
        _centers[id] = screenPos;
      }
    }
    // If some nodes have no saved layout yet, place them in a quick circle.
    if (out.length < filtered.nodes.length) {
      final missing = filtered.nodes.where((n) => !out.containsKey(n.id)).toList();
      final cx = 0.0, cy = 0.0, r = 260.0;
      for (int i = 0; i < missing.length; i++) {
        final a = (i / math.max(1, missing.length)) * 2 * math.pi;
        final worldPos = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
        out[missing[i].id] = worldPos;
        // Also capture screen space for overlay
        final screenPos = _transformPoint(_transform.value, worldPos);
        _centers[missing[i].id] = screenPos;
      }
    }
    return out;
  }

  // Safe unlock method that checks permissions
  void _unlockSkill(String nodeId) {
    final ctrl = ref.read(skillTreeProvider.notifier);
    final state = ref.read(skillTreeProvider);
    final node = state.graph.byId[nodeId];

    if (node != null && ctrl.canUnlock(nodeId) && state.playerPoints >= node.cost) {
      ctrl.unlock(nodeId);
    }
  }

  // Hit-test helpers
  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  String? _hitTestNode(Offset localPos, Map<String, Offset> positions, vmath.Matrix4 worldToScreen) {
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
    if (_computedPath.isEmpty) return;
    final newStep = i.clamp(0, _computedPath.length - 1);
    setState(() {
      _pathIndex = newStep;
      _currentStep.value = newStep; // Sync ValueNotifier
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showPath = !_showPath;
      _showFullPath.value = _showPath; // Sync ValueNotifier
      if (_showPath) {
        _recomputePath();
      }
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                      backgroundColor: node.unlocked ? Colors.green : Colors.white12,
                      child: Text('${i+1}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(node.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Cost: ${node.cost} • Tier ${node.tier}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: node.unlocked
                        ? const Icon(Icons.check, color: Colors.green)
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canUnlock ? Colors.teal : Colors.grey,
                      ),
                      onPressed: canUnlock ? () {
                        _unlockSkill(node.id);
                        setState(() => _focusedId = node.id);
                      } : null,
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

  Widget _pathControls(BuildContext context) {
    final total = _computedPath.length;
    final label = total == 0
        ? 'No steps'
        : 'Step ${_pathIndex + 1} / $total';

    if (!_showPath || total == 0) return const SizedBox.shrink();

    return Card(
      color: const Color(0xCC1E2139),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: total == 0 ? null : () => _goToStep(_pathIndex - 1),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: total == 0 ? null : () => _goToStep(_pathIndex + 1),
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
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
                    icon: const Icon(Icons.chevron_left, color: Colors.white)
                ),
                Text('Step $step', style: const TextStyle(color: Colors.white)),
                IconButton(
                    onPressed: () => _goToStep(step + 1),
                    icon: const Icon(Icons.chevron_right, color: Colors.white)
                ),
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
    final vm = _buildVM(state);
    final filtered = state.graph.subgraphForBranch(widget.branchId);
    final positions = _filterPositions(state.positions, filtered);

    final currentScale = _transform.value.storage[0];
    final branchColor = _branchColor(widget.branchId);

    // Ensure path is recomputed when state changes
    _recomputePath();

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
              gridColor: branchColor.withOpacity(0.18),
              ringColor: Colors.white.withOpacity(0.22),
              rayColor: branchColor.withOpacity(0.18),
              baseGridAlpha: 1.0,
              baseRingAlpha: 0.75,
              baseRayAlpha: 0.65,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _handleTapDown(d, positions),
              onDoubleTapDown: (d) {
                final id = _hitTestNode(d.localPosition, positions, _transform.value);
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
                  // Add the original BranchPathOverlayPainter when enabled
                  if (_showPath && _computedPath.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: BranchPathOverlayPainter(
                            positionsWorld: positions,
                            worldToScreen: _transform.value,
                            path: _computedPath,
                            currentStep: _pathIndex,
                            nodeRadius: _nodeRadius,
                            showStepNumbers: true,
                            pathColor: branchColor,
                            pathGlowColor: branchColor.withOpacity(0.5),
                            haloColor: const Color(0xFFFFC857),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                  // Add the new AutoPathOverlayPainter as additional layer
                  Positioned.fill(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _showFullPath,
                      builder: (_, show, __) => ValueListenableBuilder<int>(
                        valueListenable: _currentStep,
                        builder: (_, step, __) => IgnorePointer(
                          child: CustomPaint(
                            painter: AutoPathOverlayPainter(
                              centers: _centers,
                              pathIds: _pathIds,
                              currentIndex: step,
                              showFullPath: show,
                              fullPathColor: branchColor.withOpacity(0.4),
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
                      onIn: () => setState(() => _transform.value = _transform.value.scaled(1.15)),
                      onOut: () => setState(() => _transform.value = _transform.value.scaled(0.87)),
                      onReset: () => setState(() => _transform.value = vmath.Matrix4.identity()..scale(0.9, 0.9)),
                    ),
                  ),
                  // Add path controls at the bottom
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 80, // Above zoom controls
                    child: _pathControls(context),
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
    );
  }

  Widget _bottomActionBar(BuildContext context) {
    if (_computedPath.isEmpty) return const SizedBox.shrink();

    final state = ref.watch(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);
    final step = _currentStep.value.clamp(0, _computedPath.length - 1);
    final nodeId = _computedPath[step];
    final node = state.graph.byId[nodeId];
    if (node == null) return const SizedBox.shrink();

    final canUnlock = ctrl.canUnlock(nodeId);
    final isUnlocked = node.unlocked;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF15183A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Prev
            IconButton(
              onPressed: () {
                final next = (step - 1).clamp(0, _computedPath.length - 1);
                _currentStep.value = next;
                _goToStep(next); // Sync with existing state
              },
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            // Node title and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    node.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isUnlocked
                        ? 'Unlocked'
                        : (canUnlock ? 'Available (${node.cost} XP)' : 'Locked'),
                    style: TextStyle(
                      color: isUnlocked
                          ? Colors.greenAccent
                          : (canUnlock ? Colors.white70 : Colors.orangeAccent),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            if (!isUnlocked)
              ElevatedButton(
                onPressed: canUnlock ? () {
                  _unlockSkill(nodeId);
                  _advanceIfPossible();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUnlock ? Colors.teal : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text('Unlock'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  // Use existing controller method
                  final success = ctrl.useSkill(nodeId);
                  if (success) _advanceIfPossible();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Use'),
              ),
            const SizedBox(width: 8),
            // Next
            IconButton(
              onPressed: () {
                final next = (step + 1).clamp(0, _computedPath.length - 1);
                _currentStep.value = next;
                _goToStep(next); // Sync with existing state
              },
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _advanceIfPossible() {
    if (_computedPath.isEmpty) return;
    final next = (_currentStep.value + 1).clamp(0, _computedPath.length - 1);
    _currentStep.value = next;
    _goToStep(next); // Sync with existing state management
  }

  Color _branchColor(String id) {
    switch (id.toLowerCase()) {
      case 'combat': return const Color(0xFFE74C3C);
      case 'scholar': return const Color(0xFF4A90E2);
      case 'strategist': return const Color(0xFF9B59B6);
      case 'xp': return const Color(0xFF27AE60);
      case 'timer': return const Color(0xFF3498DB);
      case 'combo': return const Color(0xFFE67E22);
      case 'risk': return const Color(0xFFC0392B);
      case 'luck': return const Color(0xFFF1C40F);
      case 'stealth': return const Color(0xFF34495E);
      case 'knowledge': return const Color(0xFF16A085);
      case 'elite': return const Color(0xFFFFD700);
      case 'wildcard': return const Color(0xFF8E44AD);
      case 'general': return const Color(0xFF7F8C8D);
      default: return const Color(0xFF6EE7F9);
    }
  }
}

class _ZoomPad extends StatelessWidget {
  final VoidCallback onIn, onOut, onReset;
  const _ZoomPad({required this.onIn, required this.onOut, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF15183A),
      elevation: 3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onIn, icon: const Icon(Icons.zoom_in, color: Colors.white)),
          IconButton(onPressed: onOut, icon: const Icon(Icons.zoom_out, color: Colors.white)),
          IconButton(onPressed: onReset, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
    );
  }
}

class BranchDetailArgs {
  final String branchId;
  final int? initialStep;
  final bool highlightPath;
  const BranchDetailArgs(this.branchId, {this.initialStep, this.highlightPath = false});
}

class BranchDetailVM {
  final String branchId;
  final List<SkillNode> nodes;
  final List<String> order;
  final Map<String, bool> canUnlock;

  BranchDetailVM({
    required this.branchId,
    required this.nodes,
    required this.order,
    required this.canUnlock
  });
}