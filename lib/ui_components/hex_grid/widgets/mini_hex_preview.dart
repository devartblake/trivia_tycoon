import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/planning/skill_branch_path_planner.dart';
import '../../../ui_components/hex_grid/math/hex_orientation.dart';
import '../../../ui_components/hex_grid/widgets/hex_nav_button.dart';
import '../../../ui_components/hex_grid/paint/auto_path_overlay_painter.dart';
import '../model/hex_free_item.dart';
import 'hex_free_grid.dart';

class MiniHexBranchPreview extends ConsumerWidget {
  final String branchId;
  final Color baseColor;
  final Color textColor;
  final bool highlightPath;
  final List<String>? pathIds; // New parameter for explicit path IDs

  const MiniHexBranchPreview({
    super.key,
    required this.branchId,
    required this.baseColor,
    required this.textColor,
    this.highlightPath = false,
    this.pathIds, // New optional parameter
  });

  /// Factory constructor that uses real graph data instead of static demo
  factory MiniHexBranchPreview.fromGraph({
    Key? key,
    required SkillTreeGraph graph,
    required String branchId, // Using branchId string instead of category enum
    Color? baseColor,
    Color? textColor,
    bool highlightPath = false,
    List<String>? pathIds, // New parameter
  }) {
    // For the factory, we can pre-compute some data if needed,
    // but the main computation will still happen in build() to stay reactive
    return MiniHexBranchPreview(
      key: key,
      branchId: branchId,
      baseColor: baseColor ?? Colors.white24,
      textColor: textColor ?? Colors.white,
      highlightPath: highlightPath,
      pathIds: pathIds, // Pass through pathIds
    );
  }

  /// Alternative factory using SkillCategory enum (if preferred)
  factory MiniHexBranchPreview.fromCategory({
    Key? key,
    required SkillTreeGraph graph,
    required SkillCategory category,
    Color? baseColor,
    Color? textColor,
    bool highlightPath = false,
    List<String>? pathIds, // New parameter
  }) {
    return MiniHexBranchPreview.fromGraph(
      key: key,
      graph: graph,
      branchId: category.name,
      baseColor: baseColor,
      textColor: textColor,
      highlightPath: highlightPath,
      pathIds: pathIds, // Pass through pathIds
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skillTreeProvider);
    final graph = state.graph;

    // Use the centralized helper function to compute recommended order
    final ordered = computeRecommendedOrderForBranch(graph, branchId);
    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 90, // compact space inside the card
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cx = constraints.maxWidth / 2;
          final cy = 42.0; // vertically centered within 90
          final r = 14.0;  // mini hex radius
          final spacing = r * 1.6;

          // Create honeycomb pattern (center + 6 around)
          final centers = <Offset>[
            Offset(cx, cy), // center
            Offset(cx + spacing, cy), // right
            Offset(cx + spacing/2, cy + spacing * 0.866), // bottom-right
            Offset(cx - spacing/2, cy + spacing * 0.866), // bottom-left
            Offset(cx - spacing, cy), // left
            Offset(cx - spacing/2, cy - spacing * 0.866), // top-left
            Offset(cx + spacing/2, cy - spacing * 0.866), // top-right
          ];

          // Match at most 7 items to our centers
          final used = ordered.take(centers.length).toList();

          final items = <HexFreeItem>[
            for (int i = 0; i < used.length; i++)
              HexFreeItem(id: used[i].id, center: centers[i]),
          ];

          // Create order mapping for display
          final orderMap = <String, int>{
            for (int i = 0; i < used.length; i++) used[i].id: i + 1
          };

          // Create centers map for overlay painter
          final centersMap = <String, Offset>{
            for (int i = 0; i < used.length; i++) used[i].id: centers[i],
          };

          // Determine which path to use for highlighting
          final effectivePathIds = pathIds ?? (highlightPath ? used.map((n) => n.id).toList() : null);

          // Get path IDs if highlighting is enabled
          final pathIdsSet = highlightPath
              ? used.map((n) => n.id).toSet()
              : <String>{};

          return Stack(
            fit: StackFit.expand,
            children: [
              // Base hex grid
              HexagonFreeGrid(
                items: items,
                hexSize: r,
                orientation: HexOrientation.pointy,
                buildItem: (id) {
                  final node = used.firstWhere((n) => n.id == id);
                  final isOnPath = pathIdsSet.contains(id);
                  final isUnlocked = node.unlocked;

                  // Enhanced gradient based on state
                  final gradient = LinearGradient(
                    colors: [
                      baseColor.withOpacity(isOnPath ? 0.45 : (isUnlocked ? 0.30 : 0.20)),
                      baseColor.withOpacity(isOnPath ? 0.25 : (isUnlocked ? 0.15 : 0.10)),
                    ],
                  );

                  return HexNavButton(
                    radius: r,
                    size: HexButtonSize.tiny,
                    orientation: HexOrientation.pointy,
                    icon: null, // Numbers will be added as text overlay
                    gradient: gradient,
                    borderColor: Colors.white.withOpacity(isOnPath ? 0.85 : 0.55),
                    borderWidth: isOnPath ? 2.0 : 1.2,
                    glowColor: isOnPath ? baseColor.withOpacity(0.3) : null,
                  );
                },
                // Text overlay function - this will be called for each item to render text on top
                buildItemChild: (id) {
                  final idx = orderMap[id] ?? 0;
                  if (idx <= 0) return const SizedBox.shrink();

                  return Center(
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),

              // Path overlay (if highlighting is enabled and we have a path)
              if (highlightPath && (effectivePathIds?.isNotEmpty ?? false))
                CustomPaint(
                  painter: AutoPathOverlayPainter(
                    centers: centersMap,
                    pathIds: effectivePathIds!,
                    currentIndex: 0, // Start at beginning for mini preview
                    showFullPath: true,
                    fullPathWidth: 1.5,
                    stepPathWidth: 1.5,
                    fullPathColor: Colors.white54,
                    stepPathColor: Colors.white,
                    dimMaskColor: const Color(0x00000000), // No dim mask for mini preview
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}