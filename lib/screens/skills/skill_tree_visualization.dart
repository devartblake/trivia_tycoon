import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/skill_progression_model.dart';
import '../../game/providers/skill_progression_provider.dart'
    show allSkillsProvider;
import '../../game/models/skill_tree_graph.dart' hide SkillNode;
import '../../core/theme/skill_category_colors.dart';
import '../../core/design_system/synaptix_scaffold.dart';
import '../../core/design_system/glass_app_bar.dart';
import '../../core/design_system/segmented_selection_hub.dart';
import '../../core/design_system/glow_text.dart';

/// Visualization of player's skill tree progression
class SkillTreeVisualization extends ConsumerStatefulWidget {
  const SkillTreeVisualization({super.key});

  @override
  ConsumerState<SkillTreeVisualization> createState() => _SkillTreeVisualizationState();
}

class _SkillTreeVisualizationState extends ConsumerState<SkillTreeVisualization> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<SkillNode> allSkills = ref.watch(allSkillsProvider);

    return Hero(
      tag: 'surface_pathways',
      child: SynaptixScaffold(
        appBar: GlassAppBar(
          title: const GlowText('Skill Tree'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedSelectionHub(
                  items: const ['Math', 'Science', 'Logic'],
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) => setState(() => _selectedIndex = index),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _SkillCategoryView(
                      title: 'Mathematics',
                      skills: _getMathSkills(allSkills),
                      icon: Icons.calculate,
                      color: SkillCategoryColors.backgroundFor(context, SkillCategory.scholar),
                    ),
                    _SkillCategoryView(
                      title: 'Science',
                      skills: _getScienceSkills(allSkills),
                      icon: Icons.science,
                      color: SkillCategoryColors.backgroundFor(context, SkillCategory.xp),
                    ),
                    _SkillCategoryView(
                      title: 'Logic',
                      skills: _getLogicSkills(allSkills),
                      icon: Icons.psychology,
                      color: SkillCategoryColors.backgroundFor(context, SkillCategory.timer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SkillNode> _getMathSkills(List<SkillNode> allSkills) {
    return allSkills.where((s) => s.category.contains('math')).toList();
  }

  List<SkillNode> _getScienceSkills(List<SkillNode> allSkills) {
    return allSkills.where((s) => s.category.contains('science')).toList();
  }

  List<SkillNode> _getLogicSkills(List<SkillNode> allSkills) {
    return allSkills.where((s) => s.category.contains('logic')).toList();
  }
}

/// Displays a category of skills
class _SkillCategoryView extends StatelessWidget {
  final String title;
  final List<SkillNode> skills;
  final IconData icon;
  final Color color;

  const _SkillCategoryView({
    required this.title,
    required this.skills,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...skills.map((skill) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SkillNodeCard(skill: skill, color: color),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Card displaying individual skill node
class _SkillNodeCard extends StatefulWidget {
  final SkillNode skill;
  final Color color;

  const _SkillNodeCard({
    required this.skill,
    required this.color,
  });

  @override
  State<_SkillNodeCard> createState() => _SkillNodeCardState();
}

class _SkillNodeCardState extends State<_SkillNodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.skill.level > 0;
    final progress = widget.skill.level / 10;
    final xpProgress = widget.skill.totalXpRequired > 0
        ? (widget.skill.currentXp / widget.skill.totalXpRequired.toDouble())
        : 0.0;

    return Card(
      elevation: _isExpanded ? 4 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              child: Container(
                color: isUnlocked
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!isUnlocked)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.lock,
                                        size: 20,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  Text(
                                    widget.skill.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isUnlocked
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Level ${widget.skill.level}/10',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: widget.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: _isExpanded ? 2 : 0,
                          child: Icon(
                            Icons.expand_more,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Level progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded details
            SizeTransition(
              sizeFactor:
                  Tween<double>(begin: 0, end: 1).animate(_animationController),
              child: Container(
                color: widget.color.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // XP Progress
                    Text(
                      'XP Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: xpProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.skill.currentXp}/${widget.skill.totalXpRequired} XP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Prerequisites
                    if (widget.skill.prerequisites.isNotEmpty) ...[
                      Text(
                        'Prerequisites',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.skill.prerequisites.map((prereq) {
                          return Chip(
                            label: Text(prereq),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
