import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/providers/question_providers.dart' as question_data;
import '../../../game/services/quiz_category.dart';
// import '../services/adapted_question_loader_service.dart';
// import '../models/question.dart';

class ClassQuizScreen extends ConsumerStatefulWidget {
  final String classLevel;

  const ClassQuizScreen({
    super.key,
    required this.classLevel,
  });

  @override
  ConsumerState<ClassQuizScreen> createState() => _ClassQuizScreenState();
}

class _ClassQuizScreenState extends ConsumerState<ClassQuizScreen> {
  // final AdaptedQuestionLoaderService _questionService = AdaptedQuestionLoaderService();

  bool isLoading = true;
  List<Map<String, dynamic>> availableSubjects = [];
  Map<String, int> questionCounts = {};
  String? selectedSubject;
  String selectedDifficulty = 'easy';
  int selectedQuestionCount = 10;

  @override
  void initState() {
    super.initState();
    _loadClassContent();
  }

  Future<void> _loadClassContent() async {
    setState(() => isLoading = true);

    try {
      final classStats =
          await ref.read(question_data.classStatsProvider(widget.classLevel).future);
      final categories = (classStats['availableCategories'] as List?)
              ?.whereType<QuizCategory>()
              .toList() ??
          <QuizCategory>[];

      final subjects = categories.isNotEmpty
          ? categories.map(_buildSubjectFromCategory).toList()
          : _getSubjectsForClass(widget.classLevel);

      final counts = <String, int>{};

      for (final subject in subjects) {
        final parsed = QuizCategoryManager.fromString(subject['id'].toString());
        if (parsed != null) {
          final categoryStats =
              await ref.read(question_data.categoryStatsProvider(parsed).future);
          counts[subject['id'].toString()] =
              (categoryStats['questionCount'] as num?)?.toInt() ?? 0;
        } else {
          counts[subject['id'].toString()] =
              (classStats['questionCount'] as num?)?.toInt() ?? 0;
        }
      }

      setState(() {
        availableSubjects = subjects;
        questionCounts = counts;
        if (selectedSubject != null && !questionCounts.containsKey(selectedSubject)) {
          selectedSubject = null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _buildSubjectFromCategory(QuizCategory category) {
    return {
      'id': category.name,
      'name': category.displayName,
      'icon': category.icon,
      'color': category.primaryColor,
    };
  }

  List<Map<String, dynamic>> _getSubjectsForClass(String classLevel) {
    // Age-appropriate subjects based on class level
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return [
          {'id': 'colors_shapes', 'name': 'Colors & Shapes', 'icon': Icons.palette, 'color': Colors.red},
          {'id': 'numbers', 'name': 'Numbers 1-10', 'icon': Icons.looks_one, 'color': Colors.blue},
          {'id': 'alphabet', 'name': 'Letters & Sounds', 'icon': Icons.abc, 'color': Colors.green},
          {'id': 'animals', 'name': 'Animal Friends', 'icon': Icons.pets, 'color': Colors.orange},
        ];
      case '1':
      case 'grade 1':
        return [
          {'id': 'math_basic', 'name': 'Addition & Subtraction', 'icon': Icons.calculate, 'color': Colors.blue},
          {'id': 'reading', 'name': 'Reading Comprehension', 'icon': Icons.book, 'color': Colors.green},
          {'id': 'science_nature', 'name': 'Plants & Animals', 'icon': Icons.eco, 'color': Colors.teal},
          {'id': 'social_studies', 'name': 'Community Helpers', 'icon': Icons.group, 'color': Colors.purple},
        ];
      case '2':
      case 'grade 2':
        return [
          {'id': 'math_intermediate', 'name': 'Multiplication Tables', 'icon': Icons.grid_view, 'color': Colors.blue},
          {'id': 'language_arts', 'name': 'Grammar & Writing', 'icon': Icons.edit, 'color': Colors.green},
          {'id': 'science_earth', 'name': 'Weather & Seasons', 'icon': Icons.wb_sunny, 'color': Colors.orange},
          {'id': 'geography', 'name': 'Maps & Places', 'icon': Icons.map, 'color': Colors.red},
        ];
      case '3':
      case 'grade 3':
        return [
          {'id': 'math_fractions', 'name': 'Fractions & Decimals', 'icon': Icons.pie_chart, 'color': Colors.blue},
          {'id': 'science_body', 'name': 'Human Body', 'icon': Icons.accessibility, 'color': Colors.pink},
          {'id': 'history', 'name': 'Local History', 'icon': Icons.account_balance, 'color': Colors.brown},
          {'id': 'art_music', 'name': 'Arts & Music', 'icon': Icons.music_note, 'color': Colors.purple},
        ];
      default:
        return [
          {'id': 'mathematics', 'name': 'Mathematics', 'icon': Icons.calculate, 'color': Colors.blue},
          {'id': 'science', 'name': 'Science', 'icon': Icons.science, 'color': Colors.green},
          {'id': 'english', 'name': 'English', 'icon': Icons.book, 'color': Colors.red},
          {'id': 'social_studies', 'name': 'Social Studies', 'icon': Icons.public, 'color': Colors.orange},
        ];
    }
  }

  List<String> _getDifficultyOptionsForClass(String classLevel) {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
      case '1':
        return ['easy'];
      case '2':
      case '3':
        return ['easy', 'medium'];
      default:
        return ['easy', 'medium', 'hard'];
    }
  }

  void _startQuiz() {
    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    // Navigate to quiz playing screen with parameters
    context.push('/quiz/play', extra: {
      'classLevel': widget.classLevel,
      'subject': selectedSubject,
      'difficulty': selectedDifficulty,
      'questionCount': selectedQuestionCount,
      'isClassBased': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class ${widget.classLevel} Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading class content...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassHeader(),
          const SizedBox(height: 24),
          _buildSubjectSelection(),
          if (selectedSubject != null) ...[
            const SizedBox(height: 24),
            _buildQuizOptions(),
            const SizedBox(height: 24),
            _buildStartButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildClassHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Class ${widget.classLevel}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a subject to start learning!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Subject',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: availableSubjects.length,
          itemBuilder: (context, index) {
            final subject = availableSubjects[index];
            final isSelected = selectedSubject == subject['id'];
            final questionCount = questionCounts[subject['id']] ?? 0;

            return GestureDetector(
              onTap: () => setState(() => selectedSubject = subject['id']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? subject['color'].withValues(alpha: 0.1) : Colors.grey.shade50,
                  border: Border.all(
                    color: isSelected ? subject['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      subject['icon'],
                      size: 32,
                      color: isSelected ? subject['color'] : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subject['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? subject['color'] : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$questionCount questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuizOptions() {
    final difficultyOptions = _getDifficultyOptionsForClass(widget.classLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz Options',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Difficulty Selection (if applicable)
        if (difficultyOptions.length > 1) ...[
          const Text(
            'Difficulty Level',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: difficultyOptions.map((difficulty) {
              final isSelected = selectedDifficulty == difficulty;
              return ChoiceChip(
                label: Text(difficulty.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => selectedDifficulty = difficulty);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Question Count Selection
        const Text(
          'Number of Questions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [5, 10, 15, 20].map((count) {
            final isSelected = selectedQuestionCount == count;
            final maxQuestions = questionCounts[selectedSubject] ?? 0;
            final isDisabled = count > maxQuestions;

            return ChoiceChip(
              label: Text('$count'),
              selected: isSelected && !isDisabled,
              onSelected: isDisabled ? null : (selected) {
                if (selected) setState(() => selectedQuestionCount = count);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Available: ${questionCounts[selectedSubject] ?? 0} questions',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final selectedSubjectData = availableSubjects.firstWhere(
          (s) => s['id'] == selectedSubject,
      orElse: () => {'name': 'Unknown'},
    );

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Start ${selectedSubjectData['name']} Quiz',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
