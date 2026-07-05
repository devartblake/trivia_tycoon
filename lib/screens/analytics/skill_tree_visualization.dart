import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/skill_progression_model.dart';
import '../../game/providers/core_providers.dart';
import '../../game/providers/game_providers.dart';
import '../../ui_components/skill_tree/skill_tier_section.dart';
import '../../ui_components/skill_tree/skill_detail_popup.dart';

/// Loads the skill catalog (GET /skills/tree) merged with the player's unlock
/// state (GET /skills/state/{playerId}) and maps it onto the visualization's
/// [SkillNode] progression model. When no player is logged in, the catalog is
/// shown with every node locked.
final skillProgressionProvider =
    FutureProvider.autoDispose<List<SkillNode>>((ref) async {
  final api = ref.read(serviceManagerProvider).synaptixApiClient;

  String? playerId;
  try {
    playerId = await ref.read(playerProfileServiceProvider).getUserId();
  } catch (_) {
    playerId = null; // profile service unavailable — show locked catalog
  }

  final catalogFuture = api.getSkillCatalog();
  Set<String> unlockedKeys = const {};
  if (playerId != null && playerId.isNotEmpty) {
    try {
      final state = await api.getPlayerSkillState(playerId: playerId);
      unlockedKeys = state.unlockedKeys.toSet();
    } catch (_) {
      // State fetch failing shouldn't hide the catalog — render all locked.
    }
  }

  final catalog = await catalogFuture;
  return catalog.nodes.map((n) {
    final unlocked = unlockedKeys.contains(n.key);
    return SkillNode(
      skillId: n.key,
      name: n.title,
      category: n.branch.toLowerCase(),
      description: n.description,
      // The server tracks binary unlocks, not per-skill levels: unlocked
      // nodes render as level 1, locked ones as level 0.
      level: unlocked ? 1 : 0,
      totalXpRequired: n.coinCost,
      currentXp: unlocked ? n.coinCost : 0,
      prerequisites: n.prereqKeys,
      tier: n.tier,
    );
  }).toList(growable: false);
});

/// Main skill tree visualization screen
class SkillTreeVisualization extends ConsumerWidget {
  const SkillTreeVisualization({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillProgressionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(skillProgressionProvider),
            tooltip: 'Refresh skills',
          ),
        ],
      ),
      body: skillsAsync.when(
        data: (skills) => _buildTree(context, ref, skills),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading skills: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(skillProgressionProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    WidgetRef ref,
    List<SkillNode> skills,
  ) {
    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No skills yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Answer questions to unlock skills',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // Organize skills by tier
    final tierMap = _groupSkillsByTier(skills);
    final tierNumbers = tierMap.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Skill Tree',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary stats
          _buildSummaryStats(context, skills),
          const SizedBox(height: 24),

          // Tier sections
          ...tierNumbers.map((tier) {
            return SkillTierSection(
              tierNumber: tier,
              tierTitle: _getTierTitle(tier),
              skills: tierMap[tier]!,
              onSkillTap: (skill) => _showSkillDetails(context, skill),
            );
          }),
        ],
      ),
    );
  }

  /// Organize skills into tiers based on cost/progression
  Map<int, List<SkillNode>> _groupSkillsByTier(List<SkillNode> skills) {
    final tierMap = <int, List<SkillNode>>{};

    for (final skill in skills) {
      final tier = _determineTierForSkill(skill);
      (tierMap[tier] ??= []).add(skill);
    }

    return tierMap;
  }

  /// Determine which tier a skill belongs to
  int _determineTierForSkill(SkillNode skill) {
    // Prefer the server-defined catalog tier (0-based) when available.
    if (skill.tier != null) return skill.tier! + 1;

    // Heuristic fallback for locally-sourced skills.
    if (skill.level == 0) {
      // Locked skills - determine by prerequisites
      if (skill.prerequisites.isEmpty) return 1;
      return skill.prerequisites.length + 1;
    }

    // Unlocked skills - based on cost (higher cost = higher tier)
    if (skill.totalXpRequired < 1500) return 1;
    if (skill.totalXpRequired < 4000) return 2;
    return 3;
  }

  /// Get display title for a tier
  String _getTierTitle(int tier) {
    switch (tier) {
      case 1:
        return 'Foundation Skills';
      case 2:
        return 'Intermediate Skills';
      case 3:
        return 'Advanced Skills';
      case 4:
        return 'Elite Skills';
      default:
        return 'Tier $tier';
    }
  }

  /// Show skill detail popup
  void _showSkillDetails(BuildContext context, SkillNode skill) {
    showDialog(
      context: context,
      builder: (dialogContext) => SkillDetailPopup(
        skill: skill,
        onClose: () => Navigator.pop(dialogContext),
      ),
    );
  }

  /// Build summary statistics section
  Widget _buildSummaryStats(BuildContext context, List<SkillNode> skills) {
    final totalSkills = skills.length;
    final masteredCount = skills.where((s) => s.isMastered).length;
    final unlockedCount = skills.where((s) => s.level > 0).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
          context: context,
          label: 'Total Skills',
          value: totalSkills.toString(),
          icon: Icons.psychology,
        ),
        _buildStatCard(
          context: context,
          label: 'Unlocked',
          value: unlockedCount.toString(),
          icon: Icons.check_circle,
        ),
        _buildStatCard(
          context: context,
          label: 'Mastered',
          value: masteredCount.toString(),
          icon: Icons.star,
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

