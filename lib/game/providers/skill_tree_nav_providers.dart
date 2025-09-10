import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/skills_tree/repository/skill_tree_nav_repository.dart';
import '../models/skill_tree_nav_models.dart';

final skillTreeNavRepoProvider = Provider<SkillTreeNavRepository>((ref) {
  return SkillTreeNavRepository(); // default asset path
});

final skillTreeGroupsProvider = FutureProvider<List<SkillTreeGroupVM>>((ref) async {
  final repo = ref.watch(skillTreeNavRepoProvider);
  return repo.load();
});

final selectedGroupProvider = StateProvider<SkillTreeGroupId?>((ref) => null);
