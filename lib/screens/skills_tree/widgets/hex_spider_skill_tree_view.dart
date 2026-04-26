import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/index.dart';
import '../../../game/models/skill_tree_category_colors.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/providers/skill_cooldown_service_provider.dart';
import '../../../game/providers/skill_tree_provider.dart';
import '../../../ui_components/hex_grid/hex_interactive.dart';
import '../widgets/skill_node_widget.dart';
import '../widgets/skill_node_detail_sheet.dart';

class HexSpiderSkillTreeView extends ConsumerStatefulWidget {
  const HexSpiderSkillTreeView({super.key});

  @override
  ConsumerState<HexSpiderSkillTreeView> createState() =>
      _HexSpiderSkillTreeViewState();
}

class _HexSpiderSkillTreeViewState
    extends ConsumerState<HexSpiderSkillTreeView> {
  // Prerequisite path from root to selected node (ordered ids)
  List<String> _selectedPath = [];

  static const double _hexSize = 80;
  static const double _hexSpacing = 20;
  static const HexOrientation _orientation = HexOrientation.pointy;
  static const double _effectiveSize = _hexSize + _hexSpacing;

  /// Builds axial coordinate map with correct centering.
  ///
  /// For pointy hex, pixel x = √3·size·(q + r/2). Each tier r shifts the row
  /// right by r/2 hexes, so the q-offset must subtract that stagger to keep
  /// all rows centered on screen.
  Map<String, Coordinates> _buildHexOf(List<SkillNode> nodes) {
    final hexOf = <String, Coordinates>{};
    final tiers = <int, List<SkillNode>>{};
    for (final n in nodes) {
      (tiers[n.tier] ??= []).add(n);
    }
    tiers.forEach((tier, list) {
      list.sort((a, b) => a.title.compareTo(b.title));
      // Compensate for the axial stagger: screen_x = √3·size·(q + r/2)
      // To center: q_start = -(n-1)/2 - tier/2
      final qStartFrac = -((list.length - 1) / 2.0) - (tier / 2.0);
      final qStart = qStartFrac.round();
      for (var i = 0; i < list.length; i++) {
        hexOf[list[i].id] = Coordinates.axial(qStart + i, tier);
      }
    });
    return hexOf;
  }

  /// Computes pixel screen centers for all nodes using the same math as
  /// [HexagonFreeGrid], so edges and overlays align perfectly with tiles.
  Map<String, Offset> _computeScreenPositions(
    Map<String, Coordinates> hexOf,
    Size constraints,
  ) {
    // Raw axial-to-pixel (same scale HexagonFreeGrid uses)
    final raw = <String, Offset>{
      for (final e in hexOf.entries)
        e.key: HexMetrics.axialToPixel(
          e.value.q,
          e.value.r,
          _effectiveSize,
          _orientation,
        ),
    };
    if (raw.isEmpty) return {};

    final minX = raw.values.map((o) => o.dx).reduce(math.min);
    final maxX = raw.values.map((o) => o.dx).reduce(math.max);
    final minY = raw.values.map((o) => o.dy).reduce(math.min);
    final maxY = raw.values.map((o) => o.dy).reduce(math.max);

    final contentW = maxX - minX;
    final contentH = maxY - minY;
    final offX = constraints.width / 2 - (minX + contentW / 2);
    final offY = constraints.height / 2 - (minY + contentH / 2);
    final offset = Offset(offX, offY);

    return {for (final e in raw.entries) e.key: e.value + offset};
  }

  /// Walks edges backwards from [nodeId] to find root → node prerequisite path.
  List<String> _buildPrerequisitePath(String nodeId, SkillTreeGraph graph) {
    final prereqMap = <String, List<String>>{};
    for (final e in graph.edges) {
      (prereqMap[e.toId] ??= []).add(e.fromId);
    }

    final path = <String>[];
    String? current = nodeId;
    final visited = <String>{};
    while (current != null && !visited.contains(current)) {
      visited.add(current);
      path.insert(0, current);
      final prereqs = prereqMap[current];
      current = (prereqs != null && prereqs.isNotEmpty) ? prereqs.first : null;
    }
    return path;
  }

  void _onNodeTap(String nodeId, SkillTreeGraph graph,
      Map<String, Offset> screenPositions) {
    final ctrl = ref.read(skillTreeProvider.notifier);
    ctrl.select(nodeId);

    setState(() {
      _selectedPath = _buildPrerequisitePath(nodeId, graph);
    });

    final node = graph.byId[nodeId];
    if (node == null) return;
    SkillNodeDetailSheet.show(context, ref, node);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skillTreeProvider);
    final hexOf = _buildHexOf(state.graph.nodes);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final screenPositions =
            _computeScreenPositions(hexOf, screenSize);

        // Derive selected node axial coord for axis painter
        final selectedCoord = state.selectedId != null
            ? hexOf[state.selectedId]
            : null;

        return Stack(children: [
          // 1. Background guide grid
          Positioned.fill(
            child: CustomPaint(
              painter: HexSpiderBackgroundPainter(
                ringCount: 8,
                ringSpacing: 120,
                rayCount: 20,
                hexRadius: _hexSize,
                orientation: _orientation,
                gridColor: const Color(0x11FFFFFF),
              ),
            ),
          ),

          // 2. Hex tiles (nodes)
          Positioned.fill(
            child: HexInteractive(
              child: HexagonFreeGrid(
                coords: hexOf.values.toSet(),
                hexSize: _hexSize,
                spacing: _hexSpacing,
                orientation: _orientation,
                buildChild: (axial) {
                  final entry = hexOf.entries.firstWhere(
                      (e) => e.value == axial,
                      orElse: () =>
                          const MapEntry('', Coordinates.axial(0, 0)));
                  final id = entry.key;
                  if (id.isEmpty) return const SizedBox.shrink();
                  final node = state.graph.byId[id]!;
                  final cooldownService =
                      ref.read(skillCooldownServiceProvider);

                  return GestureDetector(
                    onTap: () => _onNodeTap(
                        id, state.graph, screenPositions),
                    onDoubleTap: () =>
                        ref.read(skillTreeProvider.notifier).unlockSkill(id),
                    child: SkillNodeWidget(
                      node: node,
                      isUnlocked: node.unlocked,
                      isSelected: state.selectedId == id,
                      radius: _hexSize,
                      categoryColor:
                          SkillTreeCategoryColors.categoryColors[node.category] ??
                              Colors.grey,
                      cooldownService: cooldownService,
                      onTap: () => _onNodeTap(
                          id, state.graph, screenPositions),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Prerequisite edges
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HexEdgePainter(
                  graph: state.graph,
                  hexOf: hexOf,
                  hexSize: _hexSize,
                  orientation: _orientation,
                  color: Colors.white24,
                  strokeWidth: 2,
                  screenPositions:
                      screenPositions.isNotEmpty ? screenPositions : null,
                ),
              ),
            ),
          ),

          // 4. Cube-axis highlight lines (q / r / s axes through selected hex)
          if (selectedCoord != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HexAxisOverlayPainter(
                    selected: selectedCoord,
                    hexOf: hexOf,
                    screenPositions: screenPositions,
                    hexSize: _hexSize,
                    orientation: _orientation,
                  ),
                ),
              ),
            ),

          // 5. Prerequisite path glow
          if (_selectedPath.length >= 2)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BranchPathOverlayPainter(
                    positionsWorld: screenPositions,
                    path: _selectedPath,
                    currentStep: _selectedPath.length - 1,
                    nodeRadius: _hexSize,
                    pathColor: const Color(0xFF6EE7F9),
                    pathGlowColor: const Color(0x886EE7F9),
                    haloColor: const Color(0xFF6EE7F9),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
