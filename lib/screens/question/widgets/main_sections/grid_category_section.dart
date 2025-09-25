import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../game/services/question_loader_service.dart';
import '../../../../game/services/quiz_category.dart';

// Providers for grid section data
final gridClassStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = AdaptedQuestionLoaderService();
  final classLevels = ['kindergarten', '1', '2', '3'];
  final stats = <String, int>{};

  for (final level in classLevels) {
    try {
      stats[level] = await service.getClassQuestionCount(level);
    } catch (e) {
      stats[level] = 0;
    }
  }

  return {'classStats': stats};
});

final gridCategoryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = AdaptedQuestionLoaderService();
  final coreCategories = QuizCategoryManager.coreCategories.take(6).toList();
  final stats = <String, int>{};

  for (final category in coreCategories) {
    try {
      stats[category.name] = await service.getQuizCategoryQuestionCount(category);
    } catch (e) {
      stats[category.name] = 0;
    }
  }

  return {'categoryStats': stats, 'categories': coreCategories};
});

class GridCategorySection extends ConsumerStatefulWidget {
  const GridCategorySection({super.key});

  @override
  ConsumerState<GridCategorySection> createState() => _GridCategorySectionState();
}

class _GridCategorySectionState extends ConsumerState<GridCategorySection> {
  List<Map<String, dynamic>> _getEducationalClassLevels() {
    return [
      // Elementary (show first 4 in grid view)
      {
        'id': 'kindergarten',
        'title': 'Kindergarten',
        'subtitle': 'Ages 4-5',
        'description': 'Basic learning & fun',
        'color': Colors.pink.shade300,
        'icon': Icons.child_care,
        'ageRange': '4-5 years',
      },
      {
        'id': '1',
        'title': 'Grade 1',
        'subtitle': 'Ages 5-6',
        'description': 'Foundation skills',
        'color': Colors.orange.shade300,
        'icon': Icons.looks_one,
        'ageRange': '5-6 years',
      },
      {
        'id': '2',
        'title': 'Grade 2',
        'subtitle': 'Ages 6-7',
        'description': 'Building blocks',
        'color': Colors.blue.shade300,
        'icon': Icons.looks_two,
        'ageRange': '6-7 years',
      },
      {
        'id': '3',
        'title': 'Grade 3',
        'subtitle': 'Ages 7-8',
        'description': 'Growing knowledge',
        'color': Colors.green.shade300,
        'icon': Icons.looks_3,
        'ageRange': '7-8 years',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final classLevels = _getEducationalClassLevels();
    final classStatsAsync = ref.watch(gridClassStatsProvider);
    final categoryStatsAsync = ref.watch(gridCategoryStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explore Classes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Explore Classes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push('/all-classes');
              },
              child: Row(
                children: [
                  Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Age-appropriate learning paths",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        classStatsAsync.when(
          data: (data) {
            final classStats = data['classStats'] as Map<String, int>;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: classLevels.map((classLevel) {
                final questionCount = classStats[classLevel['id']] ?? 0;
                return _EducationalClassCard(
                  title: classLevel['title'],
                  subtitle: classLevel['subtitle'],
                  description: classLevel['description'],
                  questionCount: questionCount,
                  color: classLevel['color'],
                  icon: classLevel['icon'],
                  onTap: () {
                    context.push('/class-quiz/${classLevel['id']}');
                  },
                );
              }).toList(),
            );
          },
          loading: () => _buildLoadingClassGrid(),
          error: (error, stack) => _buildLoadingClassGrid(),
        ),

        const SizedBox(height: 32),

        // Categories Section with QuizCategory integration
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Learning Categories",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push('/all-categories');
              },
              child: Row(
                children: [
                  Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Subject-based learning adventures",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        categoryStatsAsync.when(
          data: (data) {
            final categoryStats = data['categoryStats'] as Map<String, int>;
            final categories = data['categories'] as List<QuizCategory>;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: categories.map((category) {
                final questionCount = categoryStats[category.name] ?? 0;
                return _EnhancedEducationalCategoryCard(
                  category: category,
                  questionCount: questionCount,
                  onTap: () {
                    context.push('/category-quiz/${category.name}');
                  },
                );
              }).toList(),
            );
          },
          loading: () => _buildLoadingCategoryGrid(),
          error: (error, stack) => _buildLoadingCategoryGrid(),
        ),
      ],
    );
  }

  Widget _buildLoadingClassGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: List.generate(4, (index) => _LoadingClassCard()),
    );
  }

  Widget _buildLoadingCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: List.generate(6, (index) => _LoadingCategoryCard()),
    );
  }
}

class _EducationalClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final int questionCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _EducationalClassCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.questionCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$questionCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced category card using QuizCategory enum
class _EnhancedEducationalCategoryCard extends StatelessWidget {
  final QuizCategory category;
  final int questionCount;
  final VoidCallback onTap;

  const _EnhancedEducationalCategoryCard({
    required this.category,
    required this.questionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: category.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.displayName,
              style: TextStyle(
                color: category.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: category.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$questionCount questions",
                style: TextStyle(
                  color: category.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingClassCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 25,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingCategoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 70,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
