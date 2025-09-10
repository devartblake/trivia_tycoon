import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:trivia_tycoon/screens/skills_tree/render/skill_tree_painter.dart';
import '../../../ui_components/hex_grid/paint/hex_spider_background_painter.dart';
import '../../core/theme/hex_spider_theme.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../game/models/skill_branch_path_planner.dart';
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
  ConsumerState<SkillBranchDetailScreen> createState() => _SkillBranchDetailScreenState();
}

class _SkillBranchDetailScreenState extends ConsumerState<SkillBranchDetailScreen> {
  final TransformationController _transform = TransformationController();
  late final ScrollController _listCtrl;
  static const double _nodeRadius = 40;

  String? _focusedId;
  bool _showPath = false;
  int _pathIndex = -1;

  @override
  void initState() {
    super.initState();
    _transform.value = vmath.Matrix4.identity()..scale(0.9, 0.9);
    _showPath = widget.showPathInitially;
    if (widget.initialStep != null) _pathIndex = widget.initialStep!.clamp(0, 9999);

    _listCtrl = ScrollController();
    Future.microtask(() {
      final args = GoRouterState.of(context).extra as BranchDetailArgs?;
      if (args?.initialStep != null) {
        _listCtrl.jumpTo((args!.initialStep!) * 88.0);
      }
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // Build VM using the new extension and BranchPathPlanner
  BranchDetailVM _buildVM(SkillTreeState state) {
    final sg = state.graph.subgraphForBranch(widget.branchId);
    final weights = <String, double>{
      for (final n in sg.nodes)
        n.id: (n.effects['weight']?.toDouble() ?? (100 - n.tier).toDouble())
    };
    final order = BranchPathPlanner(sg, weights).plan();
    final unlocked = <String, bool>{
      for (final n in state.graph.nodes) n.id: n.unlocked
    };
    final canUnlock = <String, bool>{
      for (final id in order)
        id: _canUnlockNow(sg, id, unlocked, state.playerPoints, state.graph.byId[id]!.cost)
    };

    return BranchDetailVM(
        branchId: widget.branchId,
        nodes: sg.nodes,
        order: order,
        canUnlock: canUnlock
    );
  }

  bool _canUnlockNow(SkillTreeGraph sg, String id, Map<String, bool> unlocked, int xp, int cost) {
    if (unlocked[id] == true) return false;
    final prereqs = sg.edges.where((e) => e.toId == id).map((e) => e.fromId);
    final ready = prereqs.isEmpty || prereqs.every((p) => unlocked[p] == true);
    return ready && xp >= cost;
  }

  Map<String, Offset> _filterPositions(Map<String, Offset> all, SkillTreeGraph filtered) {
    final ids = filtered.nodes.map((n) => n.id).toSet();
    final out = <String, Offset>{};
    for (final id in ids) {
      final p = all[id];
      if (p != null) out[id] = p;
    }
    // If some nodes have no saved layout yet, place them in a quick circle.
    if (out.length < filtered.nodes.length) {
      final missing = filtered.nodes.where((n) => !out.containsKey(n.id)).toList();
      final cx = 0.0, cy = 0.0, r = 260.0;
      for (int i = 0; i < missing.length; i++) {
        final a = (i / math.max(1, missing.length)) * 2 * math.pi;
        out[missing[i].id] = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
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
      ctrl.unlock(nodeId); // Use the method you know exists
    }
  }

  // Safe use method
  void _useSkill(String nodeId) {
    final ctrl = ref.read(skillTreeProvider.notifier);
    // Check if your controller has this method, otherwise remove
    // ctrl.useSkill(nodeId);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final vm = _buildVM(state); // Use the VM pattern
    final filtered = state.graph.subgraphForBranch(widget.branchId); // Use extension
    final positions = _filterPositions(state.positions, filtered);
    final ctrl = ref.read(skillTreeProvider.notifier);

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
            onPressed: () => _showAutoPathSheet(vm), // Pass VM
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
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ZoomPad(
                      onIn: () => setState(() => _transform.value = _transform.value.scaled(1.15)),
                      onOut: () => setState(() => _transform.value = _transform.value.scaled(0.87)),
                      onReset: () => setState(() => _transform.value = vmath.Matrix4.identity()..scale(0.9, 0.9)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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