import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/skills_tree/repository/skill_tree_nav_repository.dart';
import '../models/skill_tree_nav_models.dart';

final skillTreeNavRepoProvider = Provider<SkillTreeNavRepository>((ref) {
  return SkillTreeNavRepository(); // default asset path
});

final skillTreeGroupsProvider =
    FutureProvider<List<SkillTreeGroupVM>>((ref) async {
  final repo = ref.watch(skillTreeNavRepoProvider);
  return repo.load();
});

class SkillTreeNavBranchCardMeta {
  final String id;
  final String title;
  final String colorHex;
  final int branchCount;

  const SkillTreeNavBranchCardMeta({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.branchCount,
  });
}

class SkillTreeNavSectionMeta {
  final String id;
  final String title;
  final List<SkillTreeNavBranchCardMeta> branches;

  const SkillTreeNavSectionMeta({
    required this.id,
    required this.title,
    required this.branches,
  });
}

const _fallbackSections = <SkillTreeNavSectionMeta>[
  SkillTreeNavSectionMeta(
    id: 'combat_focused',
    title: 'Combat',
    branches: [
      SkillTreeNavBranchCardMeta(
          id: 'scholar',
          title: 'Scholar',
          colorHex: '#4A90E2',
          branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'strategist',
          title: 'Strategist',
          colorHex: '#9B59B6',
          branchCount: 4),
      SkillTreeNavBranchCardMeta(
          id: 'combat', title: 'Combat', colorHex: '#E74C3C', branchCount: 3),
    ],
  ),
  SkillTreeNavSectionMeta(
    id: 'enhancement_branches',
    title: 'Enhancement',
    branches: [
      SkillTreeNavBranchCardMeta(
          id: 'xp',
          title: 'XP Booster',
          colorHex: '#27AE60',
          branchCount: 4),
      SkillTreeNavBranchCardMeta(
          id: 'timer', title: 'Timer', colorHex: '#3498DB', branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'combo', title: 'Combo', colorHex: '#E67E22', branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'risk', title: 'Risk', colorHex: '#C0392B', branchCount: 3),
    ],
  ),
  SkillTreeNavSectionMeta(
    id: 'utility_branches',
    title: 'Utility',
    branches: [
      SkillTreeNavBranchCardMeta(
          id: 'luck', title: 'Luck', colorHex: '#F1C40F', branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'stealth', title: 'Stealth', colorHex: '#34495E', branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'knowledge',
          title: 'Knowledge',
          colorHex: '#16A085',
          branchCount: 3),
    ],
  ),
  SkillTreeNavSectionMeta(
    id: 'advanced_branches',
    title: 'Advanced',
    branches: [
      SkillTreeNavBranchCardMeta(
          id: 'elite', title: 'Elite', colorHex: '#FFD700', branchCount: 3),
      SkillTreeNavBranchCardMeta(
          id: 'wildcard',
          title: 'Wildcard',
          colorHex: '#8E44AD',
          branchCount: 2),
      SkillTreeNavBranchCardMeta(
          id: 'general', title: 'General', colorHex: '#7F8C8D', branchCount: 2),
    ],
  ),
];

const _sectionOrder = <SkillTreeGroupId, String>{
  SkillTreeGroupId.combat: 'combat_focused',
  SkillTreeGroupId.enhancement: 'enhancement_branches',
  SkillTreeGroupId.utility: 'utility_branches',
  SkillTreeGroupId.advanced: 'advanced_branches',
};

final skillTreeNavSectionsProvider = Provider<List<SkillTreeNavSectionMeta>>(
  (ref) {
    final groupsAsync = ref.watch(skillTreeGroupsProvider);
    return groupsAsync.when(
      loading: () => _fallbackSections,
      error: (_, __) => _fallbackSections,
      data: (groups) {
        if (groups.isEmpty) return _fallbackSections;

        final sectionById = <String, SkillTreeNavSectionMeta>{};
        for (final group in groups) {
          final sectionId = _sectionOrder[group.id];
          if (sectionId == null) continue;

          sectionById[sectionId] = SkillTreeNavSectionMeta(
            id: sectionId,
            title: group.title,
            branches: group.branches
                .map(
                  (branch) => SkillTreeNavBranchCardMeta(
                    id: branch.branchId,
                    title: branch.title,
                    colorHex: branch.colorHex,
                    branchCount: branch.nodeMaps.length,
                  ),
                )
                .toList(),
          );
        }

        return _fallbackSections.map((fallback) {
          return sectionById[fallback.id] ?? fallback;
        }).toList();
      },
    );
  },
);

final selectedGroupProvider = StateProvider<SkillTreeGroupId?>((ref) => null);
