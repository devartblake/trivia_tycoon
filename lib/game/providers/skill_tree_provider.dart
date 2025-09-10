import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/skill_tree_loader.dart';
import '../models/skill_tree_graph.dart';
import '../controllers/skill_tree_controller.dart';

final skillTreeGraphProvider = FutureProvider<SkillTreeGraph>((ref) async {
  return loadSkillTreeFromAsset('assets/data/skill_tree/skill_tree.json');
});

final skillTreeProvider =
StateNotifierProvider<SkillTreeController, SkillTreeState>((ref) {
  final graphAsync = ref.watch(skillTreeGraphProvider);

  // While loading, start with an empty graph to keep UI alive.
  final graph = graphAsync.maybeWhen(
    data: (g) => g,
    orElse: () => const SkillTreeGraph(nodes: [], edges: []),
  );

  // If your controller already expects (ref, initialGraph: ...)
  return SkillTreeController(
    ref,
    initialGraph: graph,
    // optional persistence hooks can still be passed here
  );
});
