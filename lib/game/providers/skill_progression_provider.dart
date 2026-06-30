import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/skill_progression_service.dart';
import '../models/skill_progression_model.dart';

/// Provides the skill progression service instance
final skillProgressionServiceProvider = Provider((ref) {
  final service = SkillProgressionService();
  service.initializeDefaultSkills();
  return service;
});

/// Provides overall skill progress overview
final skillProgressOverviewProvider = Provider((ref) {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getProgressOverview();
});

/// Provides all skills
final allSkillsProvider = Provider((ref) {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getAllSkills();
});

/// Provides skills for a specific category (requires category parameter)
final skillsByCategoryProvider =
    FutureProvider.family<List<SkillNode>, String>((ref, category) async {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getSkillsForCategory(category);
});

/// Provides category mastery stats for a specific category
final categoryMasteryProvider =
    FutureProvider.family<SkillCategoryMastery?, String>((ref, category) async {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getCategoryMastery(category);
});

/// Provides all category mastery stats
final allCategoryMasteryProvider = Provider((ref) {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getAllCategoryMastery();
});

/// Provides a single skill by ID
final skillByIdProvider =
    FutureProvider.family<SkillNode?, String>((ref, skillId) async {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return skillService.getSkill(skillId);
});

/// Provides overall rank based on skill progression
final overallRankProvider = Provider((ref) {
  final overview = ref.watch(skillProgressOverviewProvider);
  return overview.overallRank;
});

/// Notifier for unlocking skills
class SkillUnlockerNotifier extends StateNotifier<bool> {
  final SkillProgressionService skillService;

  SkillUnlockerNotifier(this.skillService) : super(false);

  Future<bool> unlockSkill(String skillId) async {
    state = true;
    try {
      return skillService.unlockSkill(skillId);
    } finally {
      state = false;
    }
  }
}

/// Provides the skill unlocker
final skillUnlockerProvider =
    StateNotifierProvider<SkillUnlockerNotifier, bool>((ref) {
  final skillService = ref.watch(skillProgressionServiceProvider);
  return SkillUnlockerNotifier(skillService);
});
