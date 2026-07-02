import 'package:flutter/material.dart';
import '../../game/models/skill_progression_model.dart';
import 'skill_node_card.dart';

/// Displays all skills in a single tier with responsive layout
class SkillTierSection extends StatefulWidget {
  final int tierNumber;
  final String tierTitle;
  final List<SkillNode> skills;
  final void Function(SkillNode) onSkillTap;

  const SkillTierSection({
    super.key,
    required this.tierNumber,
    required this.tierTitle,
    required this.skills,
    required this.onSkillTap,
  });

  @override
  State<SkillTierSection> createState() => _SkillTierSectionState();
}

class _SkillTierSectionState extends State<SkillTierSection> {
  SkillNode? selectedSkill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier title with progress
        _buildTierHeader(context),
        const SizedBox(height: 12),

        // Skill grid
        _buildSkillGrid(context),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Build tier header with title and progress
  Widget _buildTierHeader(BuildContext context) {
    final totalSkills = widget.skills.length;
    final unlockedCount =
        widget.skills.where((s) => s.level > 0).length;
    final masteredCount =
        widget.skills.where((s) => s.isMastered).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.tierTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '$unlockedCount unlocked · $masteredCount mastered · $totalSkills total',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  /// Build responsive grid of skill cards
  Widget _buildSkillGrid(BuildContext context) {
    final columnCount = _getColumnCount(context);

    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: widget.skills
          .map(
            (skill) => SkillNodeCard(
              skill: skill,
              onTap: () => _handleSkillTap(skill),
              isSelected: selectedSkill?.skillId == skill.skillId,
            ),
          )
          .toList(),
    );
  }

  /// Get number of columns based on screen width
  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 6; // Desktop
    if (width > 600) return 4; // Tablet
    return 3; // Mobile
  }

  /// Handle skill card tap
  void _handleSkillTap(SkillNode skill) {
    setState(() {
      selectedSkill = selectedSkill?.skillId == skill.skillId ? null : skill;
    });
    widget.onSkillTap(skill);
  }
}
