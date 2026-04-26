import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/screens/skills_tree/widgets/skill_node_widget.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/index.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_category_colors.dart';
import '../../../game/providers/hex_theme_providers.dart';
import '../../../game/providers/skill_cooldown_service_provider.dart';
import '../../../game/providers/skill_tree_provider.dart';
import '../../../game/providers/xp_provider.dart';
import 'skill_node_detail_sheet.dart';

enum SkillNodeFilterMode { all, unlocked, available, locked }

extension SkillNodeFilterModeLabel on SkillNodeFilterMode {
  String get label => switch (this) {
        SkillNodeFilterMode.all => 'Show All',
        SkillNodeFilterMode.unlocked => 'Unlocked Only',
        SkillNodeFilterMode.available => 'Available to Unlock',
        SkillNodeFilterMode.locked => 'Locked Only',
      };

  IconData get icon => switch (this) {
        SkillNodeFilterMode.all => Icons.all_inclusive,
        SkillNodeFilterMode.unlocked => Icons.check_circle,
        SkillNodeFilterMode.available => Icons.lock_open,
        SkillNodeFilterMode.locked => Icons.lock,
      };

  Color get color => switch (this) {
        SkillNodeFilterMode.all => Colors.blue,
        SkillNodeFilterMode.unlocked => Colors.green,
        SkillNodeFilterMode.available => Colors.amber,
        SkillNodeFilterMode.locked => Colors.white54,
      };
}

class SkillTreeView extends ConsumerStatefulWidget {
  final SkillNodeFilterMode filterMode;
  /// When set, only nodes of this category are shown (e.g. 'scholar', 'xp').
  final String? categoryId;

  const SkillTreeView({
    super.key,
    this.filterMode = SkillNodeFilterMode.all,
    this.categoryId,
  });

  @override
  ConsumerState<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends ConsumerState<SkillTreeView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  // Rendered node half-size in screen pixels.
  static const double _nodeRadius = 65;
  // Must match hexSize in SkillTreeController._computeLayout (110).
  static const double _layoutHexRadius = 110.0;

  bool _showTree = true;

  @override
  void initState() {
    super.initState();
    // Centering happens in the first post-frame callback once we know the size.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Place world-origin at screen centre so the hex grid is immediately visible.
      final box = context.findRenderObject() as RenderBox?;
      final size = box?.size ?? const Size(400, 700);
      _transform.value = vmath.Matrix4.identity()
        ..translate(size.width / 2.0, size.height / 2.0)
        ..scale(0.8, 0.8);
    });
  }

  void _zoom(double scale) {
    setState(() {
      _transform.value = _transform.value.scaled(scale);
    });
  }

  void _resetZoom() {
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(400, 700);
    setState(() {
      _transform.value = vmath.Matrix4.identity()
        ..translate(size.width / 2.0, size.height / 2.0)
        ..scale(0.8, 0.8);
    });
  }

  // Transform a point from world space to screen space
  Offset _transformPoint(vmath.Matrix4 m, Offset p) {
    final v = m.transform3(vmath.Vector3(p.dx, p.dy, 0)).xy;
    return Offset(v.x, v.y);
  }

  // Hit test for nodes
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

  // Handle tap down events - select node and show detail sheet
  void _handleTapDown(TapDownDetails details) {
    final state = ref.read(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    final allPositions = <String, Offset>{};
    allPositions.addAll(state.positions);
    _addChildPositions(state, allPositions);

    final id =
        _hitTestNode(details.localPosition, allPositions, _transform.value);
    if (id == null) return;
    ctrl.select(id);

    final node = state.graph.byId[id];
    if (node == null) return;

    // Show the rich detail modal
    SkillNodeDetailSheet.show(context, ref, node);
  }

  // Handle tap events - no longer unlocks directly
  void _handleTap() {
    // Unlock/use is now handled exclusively inside SkillNodeDetailSheet.
  }

  // Add child positions only for nodes that have no position yet.
  // Since _computeLayout assigns all known nodes, this is a safety net only.
  void _addChildPositions(
      SkillTreeState state, Map<String, Offset> allPositions) {
    final hexDirections = [
      Offset(_layoutHexRadius * 1.5, 0),
      Offset(_layoutHexRadius * 0.75, _layoutHexRadius * 1.299),
      Offset(_layoutHexRadius * -0.75, _layoutHexRadius * 1.299),
      Offset(_layoutHexRadius * -1.5, 0),
      Offset(_layoutHexRadius * -0.75, _layoutHexRadius * -1.299),
      Offset(_layoutHexRadius * 0.75, _layoutHexRadius * -1.299),
    ];

    for (final parentEntry in state.positions.entries) {
      final parentId = parentEntry.key;
      final parentPos = parentEntry.value;

      final children = state.graph.edges
          .where((e) => e.fromId == parentId)
          .map((e) => e.toId)
          .where((id) => state.graph.byId.containsKey(id))
          .toList();

      for (int i = 0; i < children.length && i < 6; i++) {
        final childId = children[i];
        // Only place child if it doesn't already have a computed position.
        if (!allPositions.containsKey(childId)) {
          allPositions[childId] = parentPos + hexDirections[i];
        }
      }
    }
  }

  double _currentScale() => _transform.value.storage[0];

  /// Apply the current [widget.filterMode] to a positions map.
  Map<String, Offset> _applyFilter(
      Map<String, Offset> allPositions, SkillTreeGraph graph) {
    if (widget.filterMode == SkillNodeFilterMode.all) return allPositions;

    return Map.fromEntries(allPositions.entries.where((entry) {
      final node = graph.byId[entry.key];
      if (node == null) return false;
      return switch (widget.filterMode) {
        SkillNodeFilterMode.unlocked => node.unlocked,
        SkillNodeFilterMode.available => node.available && !node.unlocked,
        SkillNodeFilterMode.locked => !node.unlocked && !node.available,
        SkillNodeFilterMode.all => true,
      };
    }));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    final bgTheme = ref.watch(hexSpiderThemeProvider);
    final snapToNodes = ref.watch(hexSnapToNodesProvider);
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

                      final rawPositions = <String, Offset>{};
                      rawPositions.addAll(state.positions);
                      _addChildPositions(state, rawPositions);

                      // Filter to a single category if requested (branch view).
                      if (widget.categoryId != null) {
                        rawPositions.removeWhere((id, _) {
                          final node = state.graph.byId[id];
                          return node == null ||
                              node.category.name != widget.categoryId;
                        });
                      }

                      // Apply lock/unlock filter for rendering nodes
                      final allPositions =
                          _applyFilter(rawPositions, state.graph);

                      final Set<Coordinates> coords = {};
                      final Map<Coordinates, String> coordToNodeId = {};
                      allPositions.forEach((id, world) {
                        final axial =
                            _pixelToAxialPointy(world, _layoutHexRadius);
                        final rounded = _axialRound(axial);
                        final cell = Coordinates(rounded.q, rounded.r);
                        coords.add(cell);
                        coordToNodeId[cell] = id;
                      });

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _handleTapDown,
                        onTap: _handleTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1) Background spider/hex
                            Positioned.fill(
                              child: CustomPaint(
                                painter: HexSpiderBackgroundPainter(
                                  ringCount: 4,
                                  ringSpacing: 60,
                                  rayCount: 8,
                                  hexRadius: _nodeRadius * 0.4,
                                  orientation: HexOrientation.pointy,
                                  scale: currentScale,
                                  alignToNodes: snapToNodes,
                                  worldToScreen: _transform.value,
                                  positions: allPositions,
                                  theme: bgTheme,
                                  baseGridAlpha: 0.08,
                                  baseRingAlpha: 0.12,
                                  baseRayAlpha: 0.10,
                                ),
                              ),
                            ),

                            // 2) Edges — full lines coloured by unlock state
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _EdgesPainter(
                                  graph: state.graph,
                                  positions:
                                      rawPositions, // use unfiltered so edges are always drawn
                                  worldToScreen: _transform.value,
                                ),
                              ),
                            ),

                            // 3) Skill nodes
                            if (_showTree)
                              ...allPositions.entries.map((entry) {
                                final nodeId = entry.key;
                                final worldPos = entry.value;
                                final screenPos =
                                    _transformPoint(_transform.value, worldPos);
                                final node = state.graph.byId[nodeId];

                                if (node == null)
                                  return const SizedBox.shrink();

                                return Positioned(
                                  left: screenPos.dx - _nodeRadius,
                                  top: screenPos.dy - _nodeRadius,
                                  width: _nodeRadius * 2,
                                  height: _nodeRadius * 2,
                                  child: SkillNodeWidget(
                                    node: node,
                                    isUnlocked: node.unlocked,
                                    isSelected: state.selectedId == node.id,
                                    size: SkillNodeSize.large,
                                    radius: _nodeRadius,
                                    categoryColor: SkillTreeCategoryColors
                                            .categoryColors[node.category] ??
                                        Colors.grey,
                                    cooldownService:
                                        ref.read(skillCooldownServiceProvider),
                                    onTap: () {
                                      ref
                                          .read(skillTreeProvider.notifier)
                                          .select(node.id);
                                      SkillNodeDetailSheet.show(
                                          context, ref, node);
                                    },
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
      ],
    );
  }

// ====== Axial math (pointy-top) ======
  _Axial _pixelToAxialPointy(Offset p, double size) {
    final q = (2.0 / 3.0) * (p.dx / size);
    final r = (p.dy / (sqrt(3) * size)) - (q / 2.0);
    return _Axial(q, r);
  }

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

    return _AxialInt(rx, rz);
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

// ---------------- Top Bar ----------------

class _TopBar extends ConsumerWidget {
  final SkillTreeState state;
  final SkillTreeController controller;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onToggleTree;
  final bool isTreeVisible;

  const _TopBar({
    required this.state,
    required this.controller,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onToggleTree,
    required this.isTreeVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerXP = ref.watch(playerXPProvider);
    final unlockedCount = state.graph.unlockedNodes.length;
    final totalCount = state.graph.nodes.length;

    return Material(
      color: const Color(0xFF101828),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            // XP display
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$playerXP XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Progress
            Text(
              '$unlockedCount / $totalCount unlocked',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Spacer(),
            // Zoom controls
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 20),
              onPressed: onZoomIn,
              tooltip: 'Zoom in',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              onPressed: onZoomOut,
              tooltip: 'Zoom out',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onResetZoom,
              tooltip: 'Reset zoom',
            ),
            IconButton(
              icon: Icon(
                isTreeVisible ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: onToggleTree,
              tooltip: isTreeVisible ? 'Hide nodes' : 'Show nodes',
            ),
            // Overflow menu — respec lives here to prevent accidental taps
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              color: const Color(0xFF1A2035),
              onSelected: (value) {
                if (value == 'respec') {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF15183A),
                      title: const Text(
                        'Respec Skills?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'This will reset all unlocked skills and refund 50% of their XP cost.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.respec();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Respec',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'respec',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Respec Skills',
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Edges Painter ----------------
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

  /// Draw a dashed line between [p1] and [p2].
  void _drawDashed(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashLen = 8.0,
    double gapLen = 5.0,
  }) {
    final dir = p2 - p1;
    final dist = dir.distance;
    if (dist == 0) return;
    final unit = dir / dist;
    double drawn = 0;
    while (drawn < dist) {
      final start = p1 + unit * drawn;
      final end = p1 + unit * (drawn + dashLen).clamp(0.0, dist);
      canvas.drawLine(start, end, paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in graph.edges) {
      final a = positions[e.fromId];
      final b = positions[e.toId];
      if (a == null || b == null) continue;

      final fromNode = graph.byId[e.fromId];
      final toNode = graph.byId[e.toId];

      final p1 = _toScreen(worldToScreen, a);
      final p2 = _toScreen(worldToScreen, b);

      final paint = Paint()..style = PaintingStyle.stroke;

      if (fromNode?.unlocked == true && toNode?.unlocked == true) {
        // Both unlocked — bright solid line tinted to fromNode's category
        final catColor =
            SkillTreeCategoryColors.categoryColors[fromNode?.category] ??
                Colors.white;
        paint
          ..color = catColor.withValues(alpha: 0.55)
          ..strokeWidth = 2.0;
        canvas.drawLine(p1, p2, paint);
      } else if (fromNode?.unlocked == true) {
        // Path available (parent unlocked, child not yet) — dashed amber
        paint
          ..color = const Color(0xFFFFB300).withValues(alpha: 0.45)
          ..strokeWidth = 1.5;
        _drawDashed(canvas, p1, p2, paint);
      } else {
        // Fully locked — dim white
        paint
          ..color = Colors.white.withValues(alpha: 0.10)
          ..strokeWidth = 1.0;
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter old) =>
      old.graph != graph ||
      old.positions != positions ||
      old.worldToScreen != worldToScreen;
}
