import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_branch_path_planner.dart'; // Use centralized planner
import '../../../ui_components/hex_grid/math/hex_orientation.dart';
import '../../../ui_components/hex_grid/widgets/hex_nav_button.dart';
import '../model/hex_free_item.dart';
import 'hex_free_grid.dart';

class MiniHexBranchPreview extends ConsumerWidget {
  final String branchId;
  final Color baseColor;
  final Color textColor;
  final bool highlightPath;

  const MiniHexBranchPreview({
    super.key,
    required this.branchId,
    required this.baseColor,
    required this.textColor,
    this.highlightPath = false,
  });

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

          // Get path IDs if highlighting is enabled
          final pathIds = highlightPath
              ? used.map((n) => n.id).toSet()
              : <String>{};

          return HexagonFreeGrid(
            items: items,
            hexSize: r,
            orientation: HexOrientation.pointy,
            buildItem: (id) {
              final node = used.firstWhere((n) => n.id == id);
              final isOnPath = pathIds.contains(id);
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
          );
        },
      ),
    );
  }
}