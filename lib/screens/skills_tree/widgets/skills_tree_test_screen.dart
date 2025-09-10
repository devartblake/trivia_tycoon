import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/hex_spider_theme.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/models/skill_tree_nav_models.dart';
import '../../../game/providers/hex_theme_providers.dart';
import '../../../game/providers/skill_tree_nav_providers.dart';
import 'skill_tree_view.dart';

class SkillTreeNavTestScreen extends ConsumerWidget {
  const SkillTreeNavTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(skillTreeGroupsProvider);
    final selectedId = ref.watch(selectedGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Trees'),
        actions: const [],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load: $e')),
        data: (groups) {
          final groupTabs = groups.map((g) => Tab(text: g.title)).toList();
          final initialIndex = (() {
            if (selectedId == null) return 0;
            final i = groups.indexWhere((g) => g.id == selectedId);
            return i < 0 ? 0 : i;
          })();

          return DefaultTabController(
            length: groups.length,
            initialIndex: initialIndex,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: groupTabs,
                  onTap: (i) => ref.read(selectedGroupProvider.notifier).state = groups[i].id,
                ),
                Expanded(
                  child: TabBarView(
                    children: groups.map((g) => _GroupBranches(group: g)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupBranches extends ConsumerWidget {
  final SkillTreeGroupVM group;
  const _GroupBranches({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: group.branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final b = group.branches[i];
        return _BranchCard(
          branch: b,
          onOpenHex: () {
            // 1) Choose a theme that matches the group
            final theme = _themeForGroup(group.id);
            ref.read(hexSpiderThemeProvider.notifier).state = theme;

            // 2) Build graph for this branch and load into controller on the destination screen.
            final graph = b.toGraph();

            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => _BranchToHexScreen(graph: graph)),
            );
          },
        );
      },
    );
  }

  HexSpiderTheme _themeForGroup(SkillTreeGroupId id) {
    switch (id) {
      case SkillTreeGroupId.combat: return HexSpiderTheme.brand; // red-leaning palette in your theme map
      case SkillTreeGroupId.enhancement: return HexSpiderTheme.brand; // orange variant if you have one
      case SkillTreeGroupId.utility: return HexSpiderTheme.brand; // purple variant
      case SkillTreeGroupId.advanced: return HexSpiderTheme.brand; // gold variant
    }
  }
}

class _BranchCard extends StatelessWidget {
  final SkillBranchVM branch;
  final VoidCallback onOpenHex;
  const _BranchCard({required this.branch, required this.onOpenHex});

  @override
  Widget build(BuildContext context) {
    final pct = (branch.progress * 100).toStringAsFixed(0);

    return Card(
      color: branch.accent.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: branch.accent.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            // Accent bar
            Container(width: 6, height: 56, decoration: BoxDecoration(color: branch.accent, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 12),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(branch.description, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: branch.progress,
                    color: branch.accent,
                    backgroundColor: branch.accent.withOpacity(0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onOpenHex,
                  child: const Text('Open Hex Graph'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// Small trampoline screen: it injects the branch graph **after** build via button press, avoiding "modify provider during build"
class _BranchToHexScreen extends ConsumerWidget {
  final SkillTreeGraph graph;
  const _BranchToHexScreen({required this.graph});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      child: Builder(
        builder: (_) {
          // Load into controller the first time this page paints
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctrl = ref.read(skillTreeProvider.notifier);
            ctrl.loadGraph(graph, recomputeLayout: true); // safe helper we add below
          });
          return const SkillTreeView();
        },
      ),
    );
  }
}
