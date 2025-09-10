import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/index.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_category_colors.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/providers/skill_cooldown_service_provider.dart';
import '../../../ui_components/hex_grid/hex_interactive.dart';
import '../widgets/skill_node_widget.dart';


class HexSpiderSkillTreeView extends ConsumerWidget {
  const HexSpiderSkillTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skillTreeProvider);
    final ctrl = ref.read(skillTreeProvider.notifier);

    // axial positions per node (tiered rows centered on q-axis)
    final Map<String, Coordinates> hexOf = {};
    final tiers = <int, List<SkillNode>>{};
    for (final n in state.graph.nodes) { (tiers[n.tier] ??= []).add(n); }
    tiers.forEach((tier, list) {
      list.sort((a, b) => a.title.compareTo(b.title));
      final offset = -((list.length - 1) / 2.0).floor();
      for (var i = 0; i < list.length; i++) {
        hexOf[list[i].id] = Coordinates.axial(offset + i, tier);
      }
    });

    // Increased hex size for better text fitting
    const double hexSize = 80; // Increased from previous size
    const double hexSpacing = 20; // Add some spacing between hexes

    return Stack(children: [
      // Background
      Positioned.fill(
        child: CustomPaint(
          painter: HexSpiderBackgroundPainter(
            ringCount: 8,
            ringSpacing: 120,
            rayCount: 20,
            hexRadius: hexSize,
            orientation: HexOrientation.pointy,
            gridColor: const Color(0x11FFFFFF),
          ),
        ),
      ),

      // Grid + tiles
      Positioned.fill(
        child: HexInteractive(
          child: HexagonFreeGrid(
            coords: hexOf.values.toSet(),
            hexSize: hexSize,
            spacing: hexSpacing,
            orientation: HexOrientation.pointy,
            buildChild: (axial) {
              final entry = hexOf.entries.firstWhere((e) => e.value == axial, orElse: () => const MapEntry('', Coordinates.axial(0,0)));
              final id = entry.key; if (id.isEmpty) return const SizedBox.shrink();
              final node = state.graph.byId[id]!;
              final cooldownService = ref.read(skillCooldownServiceProvider);

              return GestureDetector(
                onTap: () => ctrl.select(node.id),
                onDoubleTap: () => ctrl.unlockSkill(node.id),
                child: SkillNodeWidget(
                  node: node,
                  isUnlocked: node.unlocked,
                  isSelected: state.selectedId == node.id,
                  radius: hexSize, // <- use your hex radius, e.g. 52.0
                  categoryColor: SkillTreeCategoryColors.categoryColors[node.category] ?? Colors.grey,
                  cooldownService: cooldownService,
                  onTap: () {
                    // single tap: select or trigger UI focus/tooltip
                    ctrl.select(node.id);
                    // if you want to “use” skill on single tap instead:
                    // ctrl.useSkill(node);
                  },
                ),
              );
            },
          ),
        ),
      ),

      // Edges overlay
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: HexEdgePainter(
              graph: state.graph,
              hexOf: hexOf,
              hexSize: hexSize,
              orientation: HexOrientation.pointy,
              color: Colors.white24,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    ]);
  }
}