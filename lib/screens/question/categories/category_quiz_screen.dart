import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/providers/question_providers.dart' as question_data;
import '../../../game/models/question_model.dart';
import '../../../game/services/quiz_category.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

// Provider for category quiz data
final categoryQuizProvider = FutureProvider.family<CategoryQuizData, String>((ref, category) async {
  final repository = ref.watch(question_data.questionRepositoryProvider);

  try {
    final categoryQuestions = await repository.getQuestionsForCategory(
      category: category,
      amount: 200,
    );

    final easyCount = categoryQuestions.where((q) => q.difficulty == 1).length;
    final mediumCount = categoryQuestions.where((q) => q.difficulty == 2).length;
    final hardCount = categoryQuestions.where((q) => q.difficulty == 3).length;

    final audioCount = categoryQuestions.where((q) => q.hasAudio).length;
    final videoCount = categoryQuestions.where((q) => q.hasVideo).length;
    final imageCount = categoryQuestions.where((q) => q.hasImage).length;

    return CategoryQuizData(
      category: category,
      totalQuestions: categoryQuestions.length,
      easyCount: easyCount,
      mediumCount: mediumCount,
      hardCount: hardCount,
      audioCount: audioCount,
      videoCount: videoCount,
      imageCount: imageCount,
      sampleQuestions: categoryQuestions.take(3).toList(),
      averageDifficulty: categoryQuestions.isEmpty
          ? 1.0
          : categoryQuestions.map((q) => q.difficulty).reduce((a, b) => a + b) /
              categoryQuestions.length,
      allQuestions: categoryQuestions,
    );
  } catch (e) {
    LogManager.debug('Error loading category quiz data: $e');
    rethrow;
  }
});

class CategoryQuizScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryQuizScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryQuizScreen> createState() => _CategoryQuizScreenState();
}

class _CategoryQuizScreenState extends ConsumerState<CategoryQuizScreen> {
  int selectedQuestionCount = 5;
  List<String> selectedDifficulties = ['easy', 'medium', 'hard'];
  bool includeAudio = true;
  bool includeVideo = true;
  bool includeImages = true;
  bool isStartingQuiz = false;

  int? _calculateSliderDivisions(int totalQuestions) {
    final maxValue = totalQuestions.clamp(5, 50);
    final divisionCount = ((maxValue - 5) / 5).round();

    // Return null if divisions would be 0 or negative, otherwise return the count
    return divisionCount > 0 ? divisionCount : null;
  }

  @override
  Widget build(BuildContext context) {
    final categoryDataAsync = ref.watch(categoryQuizProvider(widget.category));

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getCategoryLabel()} Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: categoryDataAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading category data...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error loading category: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(categoryQuizProvider(widget.category)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categoryData) => _buildCategoryContent(categoryData),
      ),
    );
  }

  Widget _buildCategoryContent(CategoryQuizData categoryData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getCategoryColor().withValues(alpha: 0.8), _getCategoryColor()],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${categoryData.totalQuestions} questions available',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getCategoryDescription(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Statistics
          Text(
            'Category Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Easy',
                  value: categoryData.easyCount.toString(),
                  icon: Icons.star_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Medium',
                  value: categoryData.mediumCount.toString(),
                  icon: Icons.star_half,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Hard',
                  value: categoryData.hardCount.toString(),
                  icon: Icons.star,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Audio',
                  value: categoryData.audioCount.toString(),
                  icon: Icons.headphones,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Video',
                  value: categoryData.videoCount.toString(),
                  icon: Icons.videocam,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Images',
                  value: categoryData.imageCount.toString(),
                  icon: Icons.image,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quiz Configuration
          Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Question Count Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: selectedQuestionCount.toDouble(),
                        min: 5,
                        max: categoryData.totalQuestions.toDouble().clamp(5, 50),
                        divisions: _calculateSliderDivisions(categoryData.totalQuestions),
                        label: selectedQuestionCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            selectedQuestionCount = value.round();
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedQuestionCount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Difficulty Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Difficulty Levels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _DifficultyChip(
                      label: 'Easy',
                      count: categoryData.easyCount,
                      isSelected: selectedDifficulties.contains('easy'),
                      color: Colors.green,
                      onTap: () => _toggleDifficulty('easy'),
                    ),
                    _DifficultyChip(
                      label: 'Medium',
                      count: categoryData.mediumCount,
                      isSelected: selectedDifficulties.contains('medium'),
                      color: Colors.orange,
                      onTap: () => _toggleDifficulty('medium'),
                    ),
                    _DifficultyChip(
                      label: 'Hard',
                      count: categoryData.hardCount,
                      isSelected: selectedDifficulties.contains('hard'),
                      color: Colors.red,
                      onTap: () => _toggleDifficulty('hard'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Media Type Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Media Types',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text('Include Audio Questions (${categoryData.audioCount})'),
                  value: includeAudio,
                  onChanged: (value) => setState(() => includeAudio = value ?? true),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text('Include Video Questions (${categoryData.videoCount})'),
                  value: includeVideo,
                  onChanged: (value) => setState(() => includeVideo = value ?? true),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text('Include Image Questions (${categoryData.imageCount})'),
                  value: includeImages,
                  onChanged: (value) => setState(() => includeImages = value ?? true),
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Question Preview
          if (categoryData.sampleQuestions.isNotEmpty) ...[
            Text(
              'Sample Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            ...categoryData.sampleQuestions.map((question) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _QuestionPreviewCard(question: question),
            )),
          ],

          const SizedBox(height: 32),

          // Start Quiz Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedDifficulties.isEmpty || isStartingQuiz
                  ? null
                  : () => _startQuiz(categoryData),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCategoryColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isStartingQuiz
                    ? 'Preparing Quiz...'
                    : 'Start ${_getCategoryLabel()} Quiz',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDifficulty(String difficulty) {
    setState(() {
      if (selectedDifficulties.contains(difficulty)) {
        selectedDifficulties.remove(difficulty);
      } else {
        selectedDifficulties.add(difficulty);
      }
    });
  }

  void _startQuiz(CategoryQuizData categoryData) {
    setState(() => isStartingQuiz = true);
    final allowedDifficulties = selectedDifficulties
        .map(_difficultyToInt)
        .whereType<int>()
        .toSet();
    final filteredQuestions = categoryData.allQuestions.where((question) {
      final difficultyMatch =
          allowedDifficulties.isEmpty || allowedDifficulties.contains(question.difficulty);
      final audioMatch = includeAudio || !question.hasAudio;
      final videoMatch = includeVideo || !question.hasVideo;
      final imageMatch = includeImages || !question.hasImage;
      return difficultyMatch && audioMatch && videoMatch && imageMatch;
    }).toList()
      ..shuffle();

    final selectedQuestions =
        filteredQuestions.take(selectedQuestionCount).toList(growable: false);
    if (selectedQuestions.isEmpty) {
      setState(() => isStartingQuiz = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions match the selected filters.'),
        ),
      );
      return;
    }

    final category = QuizCategoryManager.fromString(widget.category);
    context.push('/quiz/play', extra: {
      'questions': selectedQuestions,
      'questionCount': selectedQuestions.length,
      'category': category?.name ?? widget.category,
      'classLevel': '6',
      'displayTitle': '${_getCategoryLabel()} Quiz',
    });
    setState(() => isStartingQuiz = false);
  }

  int? _difficultyToInt(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return null;
    }
  }

  String _getCategoryLabel() {
    final category = QuizCategoryManager.fromString(widget.category);
    return category?.displayName ?? widget.category.toUpperCase();
  }

  Color _getCategoryColor() {
    final category = QuizCategoryManager.fromString(widget.category);
    return category?.primaryColor ?? Colors.grey;
  }

  IconData _getCategoryIcon() {
    final category = QuizCategoryManager.fromString(widget.category);
    return category?.icon ?? Icons.quiz;
  }

  String _getCategoryDescription() {
    final category = QuizCategoryManager.fromString(widget.category);
    return category?.description ?? 'Test your knowledge in this category';
  }
}

// Data models
class CategoryQuizData {
  final String category;
  final int totalQuestions;
  final int easyCount;
  final int mediumCount;
  final int hardCount;
  final int audioCount;
  final int videoCount;
  final int imageCount;
  final List<QuestionModel> sampleQuestions;
  final double averageDifficulty;
  final List<QuestionModel> allQuestions;

  const CategoryQuizData({
    required this.category,
    required this.totalQuestions,
    required this.easyCount,
    required this.mediumCount,
    required this.hardCount,
    required this.audioCount,
    required this.videoCount,
    required this.imageCount,
    required this.sampleQuestions,
    required this.averageDifficulty,
    required this.allQuestions,
  });
}

// Supporting widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final QuestionModel question;

  const _QuestionPreviewCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getDifficultyColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getDifficultyIcon(),
              color: _getDifficultyColor(),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.question,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (question.difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getDifficultyIcon() {
    switch (question.difficulty) {
      case 1: return Icons.star_outline;
      case 2: return Icons.star_half;
      case 3: return Icons.star;
      default: return Icons.help_outline;
    }
  }
}
