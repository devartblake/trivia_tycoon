import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/skill_progression_model.dart';
import '../../game/providers/skill_progression_provider.dart';

/// Visualization of player's skill tree progression
class SkillTreeVisualization extends ConsumerWidget {
  const SkillTreeVisualization({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillTree = ref.watch(skillProgressOverviewProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skill Tree'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: 'Mathematics'),
              Tab(icon: Icon(Icons.science), text: 'Science'),
              Tab(icon: Icon(Icons.psychology), text: 'Logic'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SkillCategoryView(
              title: 'Mathematics',
              skills: _getMathSkills(skillTree),
              icon: Icons.calculate,
              color: Colors.blue,
            ),
            _SkillCategoryView(
              title: 'Science',
              skills: _getScienceSkills(skillTree),
              icon: Icons.science,
              color: Colors.green,
            ),
            _SkillCategoryView(
              title: 'Logic',
              skills: _getLogicSkills(skillTree),
              icon: Icons.psychology,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  List<SkillNode> _getMathSkills(dynamic tree) {
    final allSkills = tree.allSkills as List<SkillNode>;
    return allSkills
        .where((s) => s.category.contains('math'))
        .toList();
  }

  List<SkillNode> _getScienceSkills(dynamic tree) {
    final allSkills = tree.allSkills as List<SkillNode>;
    return allSkills
        .where((s) => s.category.contains('science'))
        .toList();
  }

  List<SkillNode> _getLogicSkills(dynamic tree) {
    final allSkills = tree.allSkills as List<SkillNode>;
    return allSkills
        .where((s) => s.category.contains('logic'))
        .toList();
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
                                      padding:
                                          const EdgeInsets.only(right: 8),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.color),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.color),
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
                        children: widget.skill.prerequisites
                            .map((prereq) {
                              return Chip(
                                label: Text(prereq),
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              );
                            })
                            .toList(),
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
