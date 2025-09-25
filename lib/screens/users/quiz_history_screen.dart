import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Quiz History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Quizzes Taken', '12', Icons.quiz),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem('Avg Score', '78%', Icons.trending_up),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem('Total XP', '2,450', Icons.star),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Quizzes Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Quizzes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quiz History List
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Show recent 5 quizzes
                itemBuilder: (context, index) {
                  return _buildHistoryItem(
                    classLevel: ['3', 'kindergarten', '5', '2', '4'][index],
                    category: ['Science', 'Language Arts', 'Mathematics', 'Science', 'Social Studies'][index],
                    score: [8, 12, 15, 6, 11][index],
                    total: [10, 15, 20, 10, 15][index],
                    date: [
                      'Today',
                      'Yesterday',
                      '2 days ago',
                      '3 days ago',
                      '1 week ago'
                    ][index],
                    xpGained: [120, 180, 225, 90, 165][index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String classLevel,
    required String category,
    required int score,
    required int total,
    required String date,
    required int xpGained,
  }) {
    final percentage = ((score / total) * 100).round();
    final color = _getClassColor(classLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Class indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getClassIcon(classLevel),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Quiz info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Grade $classLevel',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $category',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Score and XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score/$total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 80 ? Colors.green :
                  percentage >= 60 ? Colors.orange : Colors.red,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '+$xpGained XP',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String classLevel) {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Colors.pink;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      case '4':
        return Colors.purple;
      case '5':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getClassIcon(String classLevel) {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Icons.child_care;
      case '1':
        return Icons.looks_one;
      case '2':
        return Icons.looks_two;
      case '3':
        return Icons.looks_3;
      case '4':
        return Icons.looks_4;
      case '5':
        return Icons.looks_5;
      default:
        return Icons.school;
    }
  }
}
