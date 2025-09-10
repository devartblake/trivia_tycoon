import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/screens/skills_tree/widgets/skill_node_widget.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/index.dart';
import '../../../core/theme/hex_spider_theme.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_category_colors.dart';
import '../../../game/providers/hex_theme_providers.dart';
import '../../../game/providers/skill_cooldown_service_provider.dart';
import '../../../ui_components/hex_grid/model/hex_free_item.dart';

class SkillTreeView extends ConsumerStatefulWidget {
  const SkillTreeView({super.key});

  @override
  ConsumerState<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends ConsumerState<SkillTreeView> with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  static const double _nodeRadius = 40;
  bool _showTree = true;

  // IMPORTANT: this must match the "size" you used when generating positions via hexToPixel
  // in _overrideWithHexLayout. You used 200.0 there, so use the same here to recover coords.
  static const double _layoutHexRadius = 200.0; // pointy-top axial radius

  @override
  void initState() {
    super.initState();
    _transform.value = vmath.Matrix4.identity()..scale(0.8, 0.8);
    // Position a few sample nodes on a hex layout *after* first frame to avoid
    // "modifying provider during build" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.microtask(() {
        if (!mounted) return;
        _overrideWithHexLayout(); // calls controller.updatePositions(...)
      });
    });
  }

  void _zoom(double scale) {
    setState(() {
      _transform.value = _transform.value.scaled(scale);
    });
  }

  void _resetZoom() {
    setState(() {
      _transform.value = vmath.Matrix4.identity();
    });
  }

  // Transform a point from world space to screen space
  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  // Hit test for nodes
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

  // Handle tap down events
  void _handleTapDown(TapDownDetails details) {
    final state = ref.read(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    // Build complete position map including children
    final allPositions = <String, Offset>{};
    allPositions.addAll(state.positions);
    _addChildPositions(state, allPositions);

    final id = _hitTestNode(details.localPosition, allPositions, _transform.value);
    ctrl.select(id);
  }

  // Handle tap events
  void _handleTap() {
    final state = ref.read(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);
    final selected = state.selectedId;
    if (selected != null) {
      ctrl.unlock(selected);
    }
  }

  // --- Simple example layout override using axial hex coordinates -> world offsets
  void _overrideWithHexLayout() {
    final state = ref.read(skillTreeProvider);
    if (state.positions.isNotEmpty) return; // don't stomp an existing layout

    const size = _layoutHexRadius;
    Offset hexToPixel(int q, int r, double size) {
      final x = size * 3 / 2 * q;
      final y = size * sqrt(3) * (r + q / 2);
      return Offset(x, y);
    }

    // Hex coordinates in world space
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

    // Schedule microtask to avoid provider write during layout edge-cases.
    Future.microtask(() {
      if (mounted) {
        ref.read(skillTreeProvider.notifier).updatePositions(updated);
      }
    });
  }

  // Add child positions in hex pattern around parents
  void _addChildPositions(SkillTreeState state, Map<String, Offset> allPositions) {
    // Hex offset directions (pointy-top hexagon neighbors)
    final hexDirections = [
      Offset(_layoutHexRadius * 1.5, 0),                           // Right
      Offset(_layoutHexRadius * 0.75, _layoutHexRadius * 1.299),   // Bottom-right
      Offset(_layoutHexRadius * -0.75, _layoutHexRadius * 1.299),  // Bottom-left
      Offset(_layoutHexRadius * -1.5, 0),                          // Left
      Offset(_layoutHexRadius * -0.75, _layoutHexRadius * -1.299), // Top-left
      Offset(_layoutHexRadius * 0.75, _layoutHexRadius * -1.299),  // Top-right
    ];

    for (final parentEntry in state.positions.entries) {
      final parentId = parentEntry.key;
      final parentPos = parentEntry.value;

      // Find children of this parent
      final children = state.graph.edges
          .where((e) => e.fromId == parentId)
          .map((e) => e.toId)
          .where((id) => state.graph.byId.containsKey(id))
          .toList();

      // Place children in hex pattern around parent
      for (int i = 0; i < children.length && i < 6; i++) {
        final childId = children[i];
        final childPos = parentPos + hexDirections[i];
        allPositions[childId] = childPos;
      }
    }
  }

  // Build sub-nodes for each parent based on outgoing edges.
  // These render as small satellites around the parent.
  List<HexSubItem> _buildSubItemsFor(SkillTreeState state, String parentId) {
    final children = state.graph.edges
        .where((e) => e.fromId == parentId)
        .map((e) => e.toId)
        .where((id) => state.graph.byId.containsKey(id))
        .toList();

    if (children.isEmpty) return const [];

    // Distribute evenly in a ring
    final step = 360.0 / children.length;
    const baseRadiusFactor = 0.9; // slightly outside parent
    const baseScale = 0.55;       // smaller than parent

    return [
      for (var i = 0; i < children.length; i++)
        HexSubItem(
          id: children[i],
          angleDeg: i * step,
          radiusFactor: baseRadiusFactor,
          scale: baseScale,
        ),
    ];
  }

  // Helper: current scale from InteractiveViewer's matrix.
  // InteractiveViewer applies uniform scale; matrix[0] is good enough here.
  double _currentScale() => _transform.value.storage[0];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    // Background theme + snap preference (from SettingsScreen)
    final bgTheme = ref.watch(hexSpiderThemeProvider);
    final snapToNodes = ref.watch(hexSnapToNodesProvider);

    // Cooldowns for badges
    final cooldowns = ref.read(skillCooldownServiceProvider);

    return Column(
      children: [
        _TopBar(
          state: state,
          controller: ctrl,
          onZoomIn: () => _zoom(1.2),
          onZoomOut: () => _zoom(0.8),
          onResetZoom: _resetZoom,
          onToggleTree: () => setState(() => _showTree = !_showTree),
          isTreeVisible: _showTree,
        ),

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
                      final currentScale = _currentScale();

                      // Build all node positions (parent + children in hex pattern)
                      final allPositions = <String, Offset>{};
                      allPositions.addAll(state.positions);
                      _addChildPositions(state, allPositions);

                      // Build coords + id map for background
                      final Set<Coordinates> coords = {};
                      final Map<Coordinates, String> coordToNodeId = {};
                      allPositions.forEach((id, world) {
                        final axial = _pixelToAxialPointy(world, _layoutHexRadius);
                        final rounded = _axialRound(axial);
                        final cell = Coordinates(rounded.q, rounded.r);
                        coords.add(cell);
                        coordToNodeId[cell] = id;
                      });

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _handleTapDown,
                        onTap: _handleTap,
                        onDoubleTapDown: (d) {
                          final id = _hitTestNode(
                              d.localPosition, allPositions, _transform.value);
                          if (id != null) ctrl.unlock(id);
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1) Background spider/hex - BEHIND EVERYTHING (very subtle)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: HexSpiderBackgroundPainter(
                                  ringCount: 4,              // Reduced further
                                  ringSpacing: 60,           // Smaller spacing
                                  rayCount: 8,               // Fewer rays
                                  hexRadius: _nodeRadius * 0.4, // Much smaller hex grid
                                  orientation: HexOrientation.pointy,
                                  scale: currentScale,
                                  alignToNodes: snapToNodes,
                                  worldToScreen: _transform.value,
                                  positions: allPositions, // Use all positions including children
                                  theme: bgTheme,
                                  // legacy params still work:
                                  baseGridAlpha: 0.08,       // Very low opacity
                                  baseRingAlpha: 0.12,       // Very low opacity
                                  baseRayAlpha: 0.10,        // Very low opacity
                                ),
                              ),
                            ),

                            // 2) Edges behind nodes but above background
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _EdgesPainter(
                                  graph: state.graph,
                                  positions: allPositions, // Use all positions for edges
                                  worldToScreen: _transform.value,
                                ),
                              ),
                            ),

                            // 3) All skill nodes (parents and children) with hex-aligned positioning
                            if (_showTree)
                              ...allPositions.entries.map((entry) {
                                final nodeId = entry.key;
                                final worldPos = entry.value;
                                final screenPos = _transformPoint(_transform.value, worldPos);
                                final node = state.graph.byId[nodeId];

                                if (node == null) return const SizedBox.shrink();

                                final isParent = state.positions.containsKey(nodeId);
                                final size = isParent ? SkillNodeSize.large : SkillNodeSize.medium;
                                final effectiveRadius = isParent ? _nodeRadius : _nodeRadius * 0.75;

                                return Positioned(
                                  left: screenPos.dx - effectiveRadius,
                                  top: screenPos.dy - effectiveRadius,
                                  width: effectiveRadius * 2,
                                  height: effectiveRadius * 2,
                                  child: SkillNodeWidget(
                                    node: node,
                                    isUnlocked: node.unlocked,
                                    isSelected: state.selectedId == node.id,
                                    size: size,
                                    categoryColor: SkillTreeCategoryColors.categoryColors[node.category] ?? Colors.grey,
                                    cooldownService: ref.read(skillCooldownServiceProvider),
                                    onTap: () => ref.read(skillTreeProvider.notifier).select(node.id),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        _BottomSheet(
          state: state,
          controller: ctrl,
          currentScale: _currentScale(), // Pass the current scale to bottom sheet
        ),
      ],
    );
  }

// ====== Axial math (pointy-top) ======
  // Convert world pixel -> axial (fractional)
  _Axial _pixelToAxialPointy(Offset p, double size) {
    // Inverse of pointy-top axial:
    // x = size * 3/2 * q
    // y = size * sqrt(3) * (r + q/2)
    final q = (2.0 / 3.0) * (p.dx / size);
    final r = (p.dy / (sqrt(3) * size)) - (q / 2.0);
    return _Axial(q, r);
  }

  // Round fractional axial to nearest integer axial using cube rounding
  _AxialInt _axialRound(_Axial a) {
    final cx = a.q;
    final cz = a.r;
    final cy = -cx - cz;

    int rx = cx.round();
    int ry = cy.round();
    int rz = cz.round();

    final dx = (rx - cx).abs();
    final dy = (ry - cy).abs();
    final dz = (rz - cz).abs();

    if (dx > dy && dx > dz) {
      rx = -ry - rz;
    } else if (dy > dz) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }

    return _AxialInt(rx, rz); // axial(q=x, r=z)
  }
}

class _Axial {
  final double q, r;
  const _Axial(this.q, this.r);
}

class _AxialInt {
  final int q, r;
  const _AxialInt(this.q, this.r);
}

// ---------------- UI Framing ----------------

class _TopBar extends StatelessWidget {
  final SkillTreeState state;
  final SkillTreeController controller;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onToggleTree;
  final bool isTreeVisible;
  final Color barColor;

  const _TopBar({
    required this.state,
    required this.controller,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onToggleTree,
    required this.isTreeVisible,
    this.barColor = const Color(0xFF101828),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: barColor,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 12),
            const Text('Skill Tree', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const Spacer(),
            Text('Points: ${state.playerPoints}', style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: controller.respec,
              child: const Text('Respec'),
            ),
            const Spacer(),
            IconButton( icon: const Icon(Icons.zoom_in), onPressed: onZoomIn),
            IconButton( icon: const Icon(Icons.zoom_out), onPressed: onZoomOut),
            IconButton( icon: const Icon(Icons.refresh),  onPressed: onResetZoom),
            IconButton(
              icon: Icon(isTreeVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleTree,
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
  final double currentScale;
  final Color sheetColor;

  const _BottomSheet({
    required this.state,
    required this.controller,
    required this.currentScale,
    this.sheetColor = const Color(0xFF0E1522),
  });

  @override
  Widget build(BuildContext context) {
    final id = state.selectedId;
    final node = id == null ? null : state.graph.byId[id];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      width: double.infinity,
      color: sheetColor,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: node == null
            ? _buildScaleBadgeOnly()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scale badge at the top of the bottom sheet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(node.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
                _buildScaleBadge(),
              ],
            ),
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

  Widget _buildScaleBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x5512182B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'Scale: ${currentScale.toStringAsFixed(2)}x',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildScaleBadgeOnly() {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildScaleBadge(),
        ],
      ),
    );
  }
}

// ---------------- Private Edges Painter ----------------
class _EdgesPainter extends CustomPainter {
  final SkillTreeGraph graph;
  final Map<String, Offset> positions; // world coords
  final vmath.Matrix4 worldToScreen;

  _EdgesPainter({
    required this.graph,
    required this.positions,
    required this.worldToScreen,
  });

  Offset _toScreen(vmath.Matrix4 m, Offset world) {
    final v = m.transform3(vmath.Vector3(world.dx, world.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33FFFFFF) // More subtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // Thinner

    for (final e in graph.edges) {
      final a = positions[e.fromId];
      final b = positions[e.toId];
      if (a == null || b == null) continue;

      final p1 = _toScreen(worldToScreen, a);
      final p2 = _toScreen(worldToScreen, b);

      // Draw only short connection stubs instead of full lines
      final direction = (p2 - p1);
      final distance = direction.distance;
      if (distance == 0) continue;

      final normalized = direction / distance;
      final stubLength = 25.0; // Short stub length

      final stub1End = p1 + (normalized * stubLength);
      final stub2Start = p2 - (normalized * stubLength);

      // Draw two short stubs instead of full line
      canvas.drawLine(p1, stub1End, paint);
      canvas.drawLine(stub2Start, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter old) =>
      old.graph != graph ||
          old.positions != positions ||
          old.worldToScreen != worldToScreen;
}