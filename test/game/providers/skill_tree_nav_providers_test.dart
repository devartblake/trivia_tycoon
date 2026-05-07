import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/skill_tree_nav_models.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_nav_providers.dart';

void main() {
  group('skillTreeNavSectionsProvider', () {
    test('maps provider-backed titles, colors, and branch counts', () async {
      final container = ProviderContainer(
        overrides: [
          skillTreeGroupsProvider.overrideWith(
            (ref) async => [
              SkillTreeGroupVM(
                id: SkillTreeGroupId.combat,
                title: 'Combat-Focused Branches',
                description: 'Combat branches',
                accent: groupAccent(SkillTreeGroupId.combat),
                colorHex: '#FF4444',
                branches: [
                  SkillBranchVM(
                    branchId: 'scholar',
                    groupId: SkillTreeGroupId.combat,
                    title: 'Scholar Path',
                    description: 'desc',
                    accent: groupAccent(SkillTreeGroupId.combat),
                    colorHex: '#4A90E2',
                    nodeMaps: const [
                      {'id': 'a'},
                      {'id': 'b'},
                      {'id': 'c'},
                      {'id': 'd'},
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(skillTreeGroupsProvider.future);
      final sections = container.read(skillTreeNavSectionsProvider);
      final combat =
          sections.firstWhere((section) => section.id == 'combat_focused');
      final scholar = combat.branches.firstWhere((b) => b.id == 'scholar');

      expect(combat.title, 'Combat-Focused Branches');
      expect(scholar.title, 'Scholar Path');
      expect(scholar.colorHex, '#4A90E2');
      expect(scholar.branchCount, 4);
    });

    test('falls back to static metadata when groups provider errors', () async {
      final container = ProviderContainer(
        overrides: [
          skillTreeGroupsProvider.overrideWith(
            (ref) => Future<List<SkillTreeGroupVM>>.error(Exception('boom')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(skillTreeGroupsProvider.future),
        throwsException,
      );

      final sections = container.read(skillTreeNavSectionsProvider);
      final combat =
          sections.firstWhere((section) => section.id == 'combat_focused');
      final scholar = combat.branches.firstWhere((b) => b.id == 'scholar');

      expect(combat.title, 'Combat');
      expect(scholar.title, 'Scholar');
      expect(scholar.branchCount, 3);
    });

    test('falls back to static metadata when groups are empty', () async {
      final container = ProviderContainer(
        overrides: [
          skillTreeGroupsProvider.overrideWith(
            (ref) async => const <SkillTreeGroupVM>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(skillTreeGroupsProvider.future);
      final sections = container.read(skillTreeNavSectionsProvider);
      final combat =
          sections.firstWhere((section) => section.id == 'combat_focused');
      final scholar = combat.branches.firstWhere((b) => b.id == 'scholar');

      expect(combat.title, 'Combat');
      expect(scholar.title, 'Scholar');
      expect(scholar.branchCount, 3);
    });
  });
}
