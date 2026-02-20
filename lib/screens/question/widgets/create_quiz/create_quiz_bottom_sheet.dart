import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/create_quiz/quick_template_card.dart';

import '../../../../game/providers/question_providers.dart';
import '../../../../game/services/quiz_category.dart';

class CreateQuizBottomSheet extends ConsumerStatefulWidget {
  const CreateQuizBottomSheet({super.key});

  @override
  ConsumerState<CreateQuizBottomSheet> createState() => CreateQuizBottomSheetState();
}

class CreateQuizBottomSheetState extends ConsumerState<CreateQuizBottomSheet> {
  String selectedDifficulty = 'Mixed';
  QuizCategory? selectedCategory;
  int questionCount = 10;

  final List<String> difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(quizCategoriesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Create Custom Quiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Count
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
                          value: questionCount.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: questionCount.toString(),
                          onChanged: (value) {
                            setState(() {
                              questionCount = value.round();
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          questionCount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Difficulty Selection
                  const Text(
                    'Difficulty Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: difficulties.map((difficulty) {
                      final isSelected = selectedDifficulty == difficulty;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDifficulty = difficulty;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Category Selection with QuizCategory
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (categories) => Column(
                      children: [
                        // All Categories option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = null;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selectedCategory == null
                                  ? Colors.green
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.apps,
                                  color: selectedCategory == null
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'All Categories (Mixed)',
                                  style: TextStyle(
                                    color: selectedCategory == null
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Core categories
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: QuizCategoryManager.coreCategories.map((category) {
                            final isSelected = selectedCategory == category;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? category.primaryColor
                                      : category.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: category.primaryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : category.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.displayName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : category.primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error loading categories: $error'),
                  ),

                  const SizedBox(height: 32),

                  // Quick Templates with QuizCategory integration
                  const Text(
                    'Quick Templates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      QuickTemplate(
                        title: 'Quick Challenge',
                        subtitle: '5 questions, mixed difficulty',
                        icon: Icons.flash_on,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/quiz/quick-challenge');
                        },
                      ),
                      const SizedBox(height: 8),
                      QuickTemplate(
                        title: 'Study Session',
                        subtitle: '20 questions, progressive difficulty',
                        icon: Icons.school,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/quiz/study-session');
                        },
                      ),
                      const SizedBox(height: 8),
                      QuickTemplate(
                        title: 'Expert Challenge',
                        subtitle: '15 hard questions',
                        icon: Icons.psychology,
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/quiz/expert-challenge');
                        },
                      ),
                      const SizedBox(height: 8),
                      QuickTemplate(
                        title: 'Daily Quiz',
                        subtitle: 'Today\'s curated selection',
                        icon: Icons.today,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/quiz/daily');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // Navigate to custom quiz with selected parameters
                      final categoryParam = selectedCategory?.name ?? 'mixed';
                      final difficultyParam = selectedDifficulty.toLowerCase();

                      context.push(
                          '/quiz/custom?category=$categoryParam&difficulty=$difficultyParam&count=$questionCount'
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory?.primaryColor ?? Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selectedCategory != null) ...[
                          Icon(selectedCategory!.icon, size: 18),
                          const SizedBox(width: 8),
                        ],
                        const Text(
                          'Start Quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}