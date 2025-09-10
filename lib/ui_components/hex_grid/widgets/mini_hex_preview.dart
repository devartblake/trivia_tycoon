import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../screens/skills_tree/skill_tree_nav_screen.dart';
import '../../../ui_components/hex_grid/math/hex_orientation.dart';
import '../../../ui_components/hex_grid/widgets/hex_nav_button.dart';
import '../model/hex_free_item.dart';
import 'hex_free_grid.dart';

class MiniHexBranchPreview extends ConsumerWidget {
  final String branchId;
  final Color baseColor;
  final Color textColor;

  const MiniHexBranchPreview({
    super.key,
    required this.branchId,
    required this.baseColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(skillTreeProvider).graph;
    final order = computeRecommendedOrderForBranch(graph, branchId);

    return SizedBox(
      height: 90, // compact space inside the card
      child: LayoutBuilder(
        builder: (context, c) {
          final cx = c.maxWidth / 2;
          final cy = 42.0; // vertically centered within 90
          final r = 14.0;  // mini hex radius
          final spacing = r * 1.6;

          // honeycomb (center + 6 around)
          final centers = <Offset>[
            Offset(cx, cy),
            Offset(cx + spacing, cy),
            Offset(cx + spacing/2, cy + spacing * 0.866),
            Offset(cx - spacing/2, cy + spacing * 0.866),
            Offset(cx - spacing, cy),
            Offset(cx - spacing/2, cy - spacing * 0.866),
            Offset(cx + spacing/2, cy - spacing * 0.866),
          ];

          // match at most 7 items to our centers
          final ids = [for (final n in order) n.id];
          final used = ids.take(centers.length).toList();

          final items = <HexFreeItem>[
            for (int i = 0; i < used.length; i++)
              HexFreeItem(id: used[i], center: centers[i]),
          ];

          // Number map for overlay
          //final indexMap = <String, int>{ for (int i=0;i<used.length;i++) used[i] = used[i], indexMap[used[i]] = i+1 }.keys; // unused but keeps analyzer happy

          final ord = <String, int>{};
          for (int i = 0; i < used.length; i++) {
            ord[used[i]] = i + 1;
          }

          return HexagonFreeGrid(
            items: items,
            hexSize: r,
            orientation: HexOrientation.pointy,
            buildItem: (id) {
              final idx = ord[id] ?? 0;
              final g = LinearGradient(
                colors: [
                  baseColor.withOpacity(0.95),
                  baseColor.withOpacity(0.70),
                ],
              );
              return HexNavButton(
                radius: r,
                orientation: HexOrientation.pointy,
                icon: idx > 0
                    ? Text('$idx', style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold))
                    : const SizedBox.shrink(),
                gradient: g,
                borderColor: Colors.white.withOpacity(0.65),
                borderWidth: 1.5,
                // no badge here (mini)
              );
            },
          );
        },
      ),
    );
  }
}
