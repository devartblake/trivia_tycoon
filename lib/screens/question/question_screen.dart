import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/carousel_challenge_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/grid_category_section.dart';
import '../question/widgets/main_sections/top_menu_section.dart';
import '../question/widgets/main_sections/grid_menu_section.dart';
import '../question/widgets/main_sections/cta_widget.dart';
import '../../game/services/question_loader_service.dart';
import '../../game/services/quiz_category.dart'; // Import QuizCategory

// Provider for the question loader service with QuizCategory support
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAllDatasetStats();
});

// Provider for available QuizCategories
final quizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAvailableQuizCategories();
});

// Provider for dataset info with QuizCategory integration
final datasetInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return loader.getDatasetInfo();
});

// Provider for category stats
final categoryStatsProvider = FutureProvider.family<Map<String, dynamic>, QuizCategory>((ref, category) async {
  final loader = AdaptedQuestionLoaderService();
  final questionCount = await loader.getQuizCategoryQuestionCount(category);
  final difficulty = await loader.getQuizCategoryDifficulty(category);

  return {
    'questionCount': questionCount,
    'difficulty': difficulty,
    'category': category,
  };
});

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  int _currentBottomNavIndex = 0;
  final AdaptedQuestionLoaderService _questionLoader = AdaptedQuestionLoaderService();

  @override
  void initState() {
    super.initState();
    // Pre-load some data
    _preloadData();
  }

  void _preloadData() async {
    try {
      // Pre-load daily quiz questions for faster access
      await _questionLoader.getDailyQuiz();

      // Pre-load QuizCategory data
      await _questionLoader.getAvailableQuizCategories();

      // Run comprehensive test for debugging
      await _questionLoader.runComprehensiveTest();
    } catch (e) {
      // Handle silently for now
      debugPrint('Preload warning: $e');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Home - already here
        context.push('/main');
        break;
      case 1: // History
        context.push('/history');
        break;
      case 2: // Create Quiz (center button)
        _showCreateQuizBottomSheet();
        break;
      case 3: // Leaderboard
        context.push('/leaderboard');
        break;
      case 4: // Profile
        context.push('/profile');
        break;
    }
  }

  void _showCreateQuizBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateQuizBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(questionStatsProvider);
    final categoriesAsync = ref.watch(quizCategoriesProvider);
    final datasetInfoAsync = ref.watch(datasetInfoProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Menu Section with user info and main actions
              const TopMenuSection(),

              const SizedBox(height: 24),

              // Carousel Challenge Quiz prominent section
              const CarouselSection(),

              const SizedBox(height: 24),

              // Quick Access Section with QuizCategory integration
              _QuickAccessSection(),

              const SizedBox(height: 24),

              // Grid Menu Section for classes and categories
              const GridMenuSection(),

              const SizedBox(height: 24),

              // Stats Overview Card
              Consumer(
                builder: (context, ref, child) {
                  return statsAsync.when(
                    data: (stats) => _StatsOverviewCard(stats: stats),
                    loading: () => const _StatsLoadingCard(),
                    error: (error, stack) => const SizedBox(),
                  );
                },
              ),

              const SizedBox(height: 24),

              GridCategorySection(),

              const SizedBox(height: 24),

              // CTA Banner
              CTAWidget(
                title: "Premium Unlock!",
                subtitle: "Get unlimited quizzes & remove ads",
                buttonText: "Upgrade Now",
                backgroundImage: 'assets/images/avatars/default-avatar.png',
                onPressed: () {
                  _showPremiumDialog();
                },
              ),

              const SizedBox(height: 24),

              // Featured Categories Section with QuizCategory
              Consumer(
                builder: (context, ref, child) {
                  return categoriesAsync.when(
                    data: (categories) => _FeaturedCategoriesSection(categories: categories),
                    loading: () => const _FeaturedCategoriesLoadingSection(),
                    error: (error, stack) => const SizedBox(),
                  );
                },
              ),

              // Bottom padding for navigation
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _QuestionScreenBottomNav(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateQuizBottomSheet(),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Features'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock premium features:'),
            SizedBox(height: 8),
            Text('• Unlimited quizzes'),
            Text('• No advertisements'),
            Text('• Advanced analytics'),
            Text('• Custom quiz creation'),
            Text('• Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle premium upgrade
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _StatsOverviewCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsOverviewCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final summary = stats['summary'] as Map<String, dynamic>? ?? {};
    final totalQuestions = summary['totalQuestions'] ?? 0;
    final totalDatasets = summary['totalDatasets'] ?? 0;
    final categoryCounts = summary['categoryCounts'] as Map<String, int>? ?? {};
    final categories = categoryCounts.length;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Database',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  title: 'Total Questions',
                  value: _formatNumber(totalQuestions),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  title: 'Categories',
                  value: categories.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  title: 'Datasets',
                  value: totalDatasets.toString(),
                  icon: Icons.library_books,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatsLoadingCard extends StatelessWidget {
  const _StatsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Database',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatLoadingItem()),
              const SizedBox(width: 12),
              Expanded(child: _StatLoadingItem()),
              const SizedBox(width: 12),
              Expanded(child: _StatLoadingItem()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatLoadingItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                title: 'Random Quiz',
                subtitle: 'Mixed questions',
                icon: Icons.shuffle,
                color: Colors.indigo,
                onTap: () {
                  context.push('/quiz/random');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                title: 'Daily Challenge',
                subtitle: 'New every day',
                icon: Icons.calendar_today,
                color: Colors.teal,
                onTap: () {
                  context.push('/quiz/daily');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Category Grid using QuizCategory enum

class _FeaturedCategoriesSection extends StatelessWidget {
  final List<QuizCategory> categories;

  const _FeaturedCategoriesSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

    // Show a horizontal list of featured categories
    final featuredCategories = categories.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore More',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < featuredCategories.length - 1 ? 12 : 0,
                ),
                child: _FeaturedCategoryChip(category: category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCategoryChip extends ConsumerWidget {
  final QuizCategory category;

  const _FeaturedCategoryChip({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStatsAsync = ref.watch(categoryStatsProvider(category));

    return GestureDetector(
      onTap: () {
        context.push('/quiz/category/${category.name}');
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: category.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: category.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            categoryStatsAsync.when(
              data: (stats) => Text(
                '${stats['questionCount']}q',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              loading: () => const SizedBox(height: 10),
              error: (error, stack) => const SizedBox(height: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCategoriesLoadingSection extends StatelessWidget {
  const _FeaturedCategoriesLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore More',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Bottom Navigation for QuestionScreen (unchanged)
class _QuestionScreenBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _QuestionScreenBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(height: 32), // Space for floating action button
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Enhanced Create Quiz Bottom Sheet with QuizCategory support
class _CreateQuizBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateQuizBottomSheet> createState() => _CreateQuizBottomSheetState();
}

class _CreateQuizBottomSheetState extends ConsumerState<_CreateQuizBottomSheet> {
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
                                      : category.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: category.primaryColor.withOpacity(0.3),
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
                      _QuickTemplate(
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
                      _QuickTemplate(
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
                      _QuickTemplate(
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
                      _QuickTemplate(
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

class _QuickTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
