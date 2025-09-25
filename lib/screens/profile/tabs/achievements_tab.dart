import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildProgressOverviewCard(),
            const SizedBox(height: 16),
            _buildRecentAchievementsCard(),
            const SizedBox(height: 16),
            _buildSubjectMasteryCard(),
            const SizedBox(height: 16),
            _buildStreakAchievementsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40E0D0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Achievement Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem('Unlocked', '18', '24'),
              ),
              Expanded(
                child: _buildProgressItem('In Progress', '4', '6'),
              ),
              Expanded(
                child: _buildProgressItem('Next Level', '2', '8'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String current, String total) {
    final percentage = int.parse(current) / int.parse(total);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Text(
              '$current/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentAchievementsCard() {
    final recentAchievements = [
      {
        'title': 'Math Wizard',
        'description': 'Complete 25 math quizzes',
        'icon': Icons.calculate,
        'color': Color(0xFF6A5ACD),
        'date': '2 days ago',
        'isNew': true,
      },
      {
        'title': 'Perfect Week',
        'description': 'Score 90%+ on all quizzes this week',
        'icon': Icons.star,
        'color': Color(0xFFFFD700),
        'date': '5 days ago',
        'isNew': true,
      },
      {
        'title': 'Science Explorer',
        'description': 'Answer 100 science questions correctly',
        'icon': Icons.science,
        'color': Color(0xFF26de81),
        'date': '1 week ago',
        'isNew': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A5ACD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.new_releases, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Achievements',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...recentAchievements.map((achievement) => _buildAchievementItem(
            achievement['title'] as String,
            achievement['description'] as String,
            achievement['icon'] as IconData,
            achievement['color'] as Color,
            achievement['date'] as String,
            achievement['isNew'] as bool,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, Color color, String date, bool isNew) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMasteryCard() {
    final subjects = [
      {'name': 'Mathematics', 'level': 4, 'maxLevel': 5, 'color': Color(0xFF6A5ACD)},
      {'name': 'Science', 'level': 3, 'maxLevel': 5, 'color': Color(0xFF26de81)},
      {'name': 'History', 'level': 3, 'maxLevel': 5, 'color': Color(0xFFFF6B6B)},
      {'name': 'Literature', 'level': 2, 'maxLevel': 5, 'color': Color(0xFFFFA726)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26de81),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Subject Mastery',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...subjects.map((subject) => _buildMasteryItem(
            subject['name'] as String,
            subject['level'] as int,
            subject['maxLevel'] as int,
            subject['color'] as Color,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMasteryItem(String subject, int level, int maxLevel, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(maxLevel, (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index < level ? color : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: index < level ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: index < level ? const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 14,
                  ) : null,
                );
              }),
            ),
          ),
          Text(
            '$level/$maxLevel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAchievementsCard() {
    final streakAchievements = [
      {
        'title': 'Daily Learner',
        'description': 'Complete at least 1 quiz daily',
        'currentStreak': 12,
        'targetStreak': 7,
        'icon': Icons.local_fire_department,
        'color': Color(0xFFFF6B6B),
        'completed': true,
      },
      {
        'title': 'Weekly Warrior',
        'description': 'Maintain streak for 7 days',
        'currentStreak': 12,
        'targetStreak': 7,
        'icon': Icons.emoji_events,
        'color': Color(0xFFFFD700),
        'completed': true,
      },
      {
        'title': 'Monthly Master',
        'description': 'Maintain streak for 30 days',
        'currentStreak': 12,
        'targetStreak': 30,
        'icon': Icons.diamond,
        'color': Color(0xFF6A5ACD),
        'completed': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Streak Achievements',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...streakAchievements.map((achievement) => _buildStreakItem(
            achievement['title'] as String,
            achievement['description'] as String,
            achievement['currentStreak'] as int,
            achievement['targetStreak'] as int,
            achievement['icon'] as IconData,
            achievement['color'] as Color,
            achievement['completed'] as bool,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String title, String description, int currentStreak, int targetStreak, IconData icon, Color color, bool completed) {
    final progress = (currentStreak / targetStreak).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? color.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: completed ? color : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
              boxShadow: completed ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: completed ? color : Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentStreak/$targetStreak days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: completed ? color : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
