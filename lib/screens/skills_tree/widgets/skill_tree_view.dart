import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../../../game/controllers/skill_tree_controller.dart';
import '../render/skill_tree_painter.dart';
import '../render/skill_tree_background_painter.dart';
import '../../../game/models/skill_tree_graph.dart';

class SkillTreeView extends ConsumerStatefulWidget {
  const SkillTreeView({super.key});

  @override
  ConsumerState<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends ConsumerState<SkillTreeView> {
  final TransformationController _transform = TransformationController();
  static const double _nodeRadius = 20;

  @override
  void initState() {
    super.initState();
    _transform.value = vmath.Matrix4.identity()..scale(0.8, 0.8);
    _overrideWithHexLayout();
  }

  void _overrideWithHexLayout() {
    final state = ref.read(skillTreeProvider);
    const size = 100.0;

    Offset hexToPixel(int q, int r, double size) {
      final x = size * 3 / 2 * q;
      final y = size * sqrt(3) * (r + q / 2);
      return Offset(x, y);
    }

    final hexCoords = <String, Offset>{
      'core': hexToPixel(0, 0, size),
      'hint': hexToPixel(-1, 0, size),
      'double_hint': hexToPixel(1, 0, size),
      'xp1': hexToPixel(0, -1, size),
      'xp2': hexToPixel(0, 1, size),
      'cooldown': hexToPixel(-1, 1, size),
      'lifeline': hexToPixel(1, -1, size),
    };

    final updated = Map<String, Offset>.from(state.positions);
    for (final entry in hexCoords.entries) {
      if (state.graph.byId.containsKey(entry.key)) {
        updated[entry.key] = entry.value;
      }
    }
    ref.read(skillTreeProvider.notifier).updatePositions(updated);
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

  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  void _handleTapDown(TapDownDetails details) {
    final state = ref.read(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);
    final id = _hitTestNode(details.localPosition, state.positions, _transform.value);
    ctrl.select(id);
  }

  void _handleTap() {
    final state = ref.read(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);
    final selected = state.selectedId;
    if (selected != null) {
      ctrl.unlock(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    return Column(
      children: [
        _TopBar(state: state, controller: ctrl),
        Expanded(
          child: Container(
            color: const Color(0xFF0D1021),
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 0.5,
                maxScale: 2.2,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final painter = SkillTreePainter(
                        graph: state.graph,
                        positions: state.positions,
                        worldToScreen: _transform.value,
                        nodeRadius: _nodeRadius,
                        selectedId: state.selectedId,
                      );

                      final backgroundPainter = SkillTreeBackgroundPainter(
                        worldToScreen: _transform.value,
                        nodeSize: _nodeRadius,
                      );

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _handleTapDown,
                        onTap: _handleTap,
                        onDoubleTapDown: (d) {
                          final id = _hitTestNode(d.localPosition, state.positions, _transform.value);
                          if (id != null) ctrl.unlock(id);
                        },
                        child: CustomPaint(
                          size: Size(c.maxWidth, c.maxHeight),
                          foregroundPainter: painter,
                          painter: backgroundPainter,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        _BottomSheet(state: state, controller: ctrl),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final SkillTreeState state;
  final SkillTreeController controller;
  const _TopBar({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF15183A),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Text('Skill Tree', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const Spacer(),
            Text('Points: ${state.playerPoints}', style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 12),
            TextButton(
              onPressed: controller.respec,
              child: const Text('Respec'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final SkillTreeState state;
  final SkillTreeController controller;
  const _BottomSheet({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = state.selectedId;
    final node = id == null ? null : state.graph.byId[id];

    return Container(
      color: const Color(0xFF0D1021),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: node == null
            ? const SizedBox(height: 0)
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 6),
            Text(node.description, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: node.effects.entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Cost: ${node.cost}', style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                ElevatedButton(
                  onPressed: controller.canUnlock(node.id) ? () => controller.unlock(node.id) : null,
                  child: Text(node.unlocked ? 'Unlocked' : 'Unlock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
