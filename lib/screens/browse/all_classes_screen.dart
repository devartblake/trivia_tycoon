import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/services/question_loader_service.dart';
import '../../game/services/quiz_category.dart';

// Providers for class data
final classStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, classId) async {
  final service = AdaptedQuestionLoaderService();
  final questionCount = await service.getClassQuestionCount(classId);
  final subjectCount = await service.getClassSubjectCount(classId);
  final categories = QuizCategoryManager.getCategoriesForClass(classId);

  return {
    'questionCount': questionCount,
    'subjectCount': subjectCount,
    'availableCategories': categories,
  };
});

final allClassesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = AdaptedQuestionLoaderService();
  await service.runComprehensiveTest();

  final classes = ['kindergarten', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  final stats = <String, Map<String, dynamic>>{};

  for (final classId in classes) {
    try {
      final questionCount = await service.getClassQuestionCount(classId);
      final subjectCount = await service.getClassSubjectCount(classId);
      final categories = QuizCategoryManager.getCategoriesForClass(classId);

      stats[classId] = {
        'questionCount': questionCount,
        'subjectCount': subjectCount,
        'availableCategories': categories,
      };
    } catch (e) {
      stats[classId] = {
        'questionCount': 0,
        'subjectCount': 0,
        'availableCategories': <QuizCategory>[],
        'error': e.toString(),
      };
    }
  }

  return {'classStats': stats};
});

class AllClassesScreen extends ConsumerStatefulWidget {
  const AllClassesScreen({super.key});

  @override
  ConsumerState<AllClassesScreen> createState() => _AllClassesScreenState();
}

class _AllClassesScreenState extends ConsumerState<AllClassesScreen> {
  String searchQuery = '';
  String selectedAgeGroup = 'all';

  List<Map<String, dynamic>> _getEducationalClasses() {
    return [
      // Elementary Classes
      {
        'id': 'kindergarten',
        'title': 'Kindergarten',
        'subtitle': 'Ages 4-5',
        'description': 'Basic learning through play and exploration',
        'color': Colors.pink.shade400,
        'icon': Icons.child_care,
        'ageRange': '4-5 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Colors & Shapes', 'Basic Numbers', 'Letter Recognition', 'Social Skills'],
      },
      {
        'id': '1',
        'title': 'Grade 1',
        'subtitle': 'Ages 5-6',
        'description': 'Foundation skills and early literacy',
        'color': Colors.orange.shade400,
        'icon': Icons.looks_one,
        'ageRange': '5-6 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Reading Basics', 'Simple Math', 'Science Wonder', 'Community'],
      },
      {
        'id': '2',
        'title': 'Grade 2',
        'subtitle': 'Ages 6-7',
        'description': 'Building blocks for advanced learning',
        'color': Colors.blue.shade400,
        'icon': Icons.looks_two,
        'ageRange': '6-7 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Reading Fluency', 'Addition/Subtraction', 'Nature Study', 'Geography'],
      },
      {
        'id': '3',
        'title': 'Grade 3',
        'subtitle': 'Ages 7-8',
        'description': 'Growing knowledge and critical thinking',
        'color': Colors.green.shade400,
        'icon': Icons.looks_3,
        'ageRange': '7-8 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Complex Reading', 'Multiplication', 'Human Body', 'History'],
      },
      {
        'id': '4',
        'title': 'Grade 4',
        'subtitle': 'Ages 8-9',
        'description': 'Advanced elementary concepts',
        'color': Colors.purple.shade400,
        'icon': Icons.looks_4,
        'ageRange': '8-9 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Literature', 'Fractions', 'Earth Science', 'Government'],
      },
      {
        'id': '5',
        'title': 'Grade 5',
        'subtitle': 'Ages 9-10',
        'description': 'Pre-middle school preparation',
        'color': Colors.teal.shade400,
        'icon': Icons.looks_5,
        'ageRange': '9-10 years',
        'ageGroup': 'elementary',
        'focusAreas': ['Writing Skills', 'Decimals', 'Physical Science', 'World Cultures'],
      },
      // Middle School Classes
      {
        'id': '6',
        'title': 'Grade 6',
        'subtitle': 'Ages 10-11',
        'description': 'Transition to middle school concepts',
        'color': Colors.indigo.shade400,
        'icon': Icons.looks_6,
        'ageRange': '10-11 years',
        'ageGroup': 'middle',
        'focusAreas': ['Pre-Algebra', 'Research Skills', 'Ancient History', 'Life Science'],
      },
      {
        'id': '7',
        'title': 'Grade 7',
        'subtitle': 'Ages 11-12',
        'description': 'Developing analytical thinking',
        'color': Colors.red.shade400,
        'icon': Icons.school,
        'ageRange': '11-12 years',
        'ageGroup': 'middle',
        'focusAreas': ['Algebra Basics', 'Essay Writing', 'World Geography', 'Biology'],
      },
      {
        'id': '8',
        'title': 'Grade 8',
        'subtitle': 'Ages 12-13',
        'description': 'Pre-high school preparation',
        'color': Colors.brown.shade400,
        'icon': Icons.grade,
        'ageRange': '12-13 years',
        'ageGroup': 'middle',
        'focusAreas': ['Algebra I', 'Critical Analysis', 'American History', 'Chemistry Intro'],
      },
      // High School Classes
      {
        'id': '9',
        'title': 'Grade 9',
        'subtitle': 'Ages 13-14',
        'description': 'High school foundation',
        'color': Colors.cyan.shade400,
        'icon': Icons.school_outlined,
        'ageRange': '13-14 years',
        'ageGroup': 'high',
        'focusAreas': ['Geometry', 'Literature Analysis', 'World History', 'Physical Science'],
      },
      {
        'id': '10',
        'title': 'Grade 10',
        'subtitle': 'Ages 14-15',
        'description': 'Advanced high school concepts',
        'color': Colors.lime.shade400,
        'icon': Icons.auto_stories,
        'ageRange': '14-15 years',
        'ageGroup': 'high',
        'focusAreas': ['Algebra II', 'World Literature', 'Government', 'Chemistry'],
      },
      {
        'id': '11',
        'title': 'Grade 11',
        'subtitle': 'Ages 15-16',
        'description': 'College preparation focus',
        'color': Colors.amber.shade400,
        'icon': Icons.psychology,
        'ageRange': '15-16 years',
        'ageGroup': 'high',
        'focusAreas': ['Pre-Calculus', 'American Literature', 'Economics', 'Physics'],
      },
      {
        'id': '12',
        'title': 'Grade 12',
        'subtitle': 'Ages 16-18',
        'description': 'College readiness and advanced topics',
        'color': Colors.deepPurple.shade400,
        'icon': Icons.workspace_premium,
        'ageRange': '16-18 years',
        'ageGroup': 'high',
        'focusAreas': ['Calculus', 'College Writing', 'Advanced Sciences', 'Critical Thinking'],
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredClasses() {
    final classes = _getEducationalClasses();
    return classes.where((classLevel) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final title = classLevel['title'].toString().toLowerCase();
        final description = classLevel['description'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Age group filter
      if (selectedAgeGroup != 'all') {
        return classLevel['ageGroup'] == selectedAgeGroup;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _getFilteredClasses();
    final allStatsAsync = ref.watch(allClassesStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Educational Classes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header and Search
          Container(
            color: Theme.of(context).colorScheme.inversePrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age-Appropriate Learning Paths',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Age group filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Grades',
                        isSelected: selectedAgeGroup == 'all',
                        onTap: () => setState(() => selectedAgeGroup = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Elementary',
                        isSelected: selectedAgeGroup == 'elementary',
                        onTap: () => setState(() => selectedAgeGroup = 'elementary'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Middle School',
                        isSelected: selectedAgeGroup == 'middle',
                        onTap: () => setState(() => selectedAgeGroup = 'middle'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'High School',
                        isSelected: selectedAgeGroup == 'high',
                        onTap: () => setState(() => selectedAgeGroup = 'high'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Class List
          Expanded(
            child: allStatsAsync.when(
              data: (allStats) => _buildClassList(filteredClasses, allStats['classStats']),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _LoadingClassCard(),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(allClassesStatsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<Map<String, dynamic>> classes, Map<String, dynamic> classStats) {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No classes found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classLevel = classes[index];
        final classId = classLevel['id'] as String;
        final stats = classStats[classId] ?? {};
        final questionCount = stats['questionCount'] ?? 0;
        final subjectCount = stats['subjectCount'] ?? 0;
        final availableCategories = stats['availableCategories'] as List<QuizCategory>? ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _EnhancedEducationalClassCard(
            classData: classLevel,
            questionCount: questionCount,
            subjectCount: subjectCount,
            availableCategories: availableCategories,
            onTap: () => context.push('/class-quiz/$classId'),
          ),
        );
      },
    );
  }
}

class _EnhancedEducationalClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final int questionCount;
  final int subjectCount;
  final List<QuizCategory> availableCategories;
  final VoidCallback onTap;

  const _EnhancedEducationalClassCard({
    required this.classData,
    required this.questionCount,
    required this.subjectCount,
    required this.availableCategories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [classData['color'], classData['color'].withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      classData['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classData['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classData['subtitle'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.quiz,
                        label: '$questionCount Questions',
                        color: classData['color'],
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.book,
                        label: '$subjectCount Subjects',
                        color: classData['color'],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Available Categories
                  if (availableCategories.isNotEmpty) ...[
                    Text(
                      'Available Categories:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableCategories.take(4).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: category.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: category.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                size: 10,
                                color: category.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: category.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (availableCategories.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${availableCategories.length - 4} more categories',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Focus Areas fallback
                    Text(
                      'Learning Focus:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (classData['focusAreas'] as List<String>).map((area) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: classData['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            area,
                            style: TextStyle(
                              fontSize: 11,
                              color: classData['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingClassCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 70,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
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