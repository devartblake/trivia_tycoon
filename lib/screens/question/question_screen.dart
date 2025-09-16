import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/carousel_challenge_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/grid_category_section.dart';
import '../question/widgets/main_sections/top_menu_section.dart';
import '../question/widgets/main_sections/grid_menu_section.dart';
import '../question/widgets/main_sections/cta_widget.dart';
import '../../game/data/question_loader_service.dart';

// Provider for the question loader service
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAllDatasetStats();
});

// Provider for available categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAvailableCategories();
});

// Provider for dataset info
final datasetInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return loader.getDatasetInfo();
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

      // Pre-load some category data
      await _questionLoader.getAvailableCategories();
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
        break;
      case 1: // History
      // Navigate to history screen
        break;
      case 2: // Create Quiz (center button)
        _showCreateQuizBottomSheet();
        break;
      case 3: // Leaderboard
      // Navigate to leaderboard
        break;
      case 4: // Profile
      // Navigate to profile
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
    final categoriesAsync = ref.watch(categoriesProvider);
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

              // Quick Access Section
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

              // Grid Menu Section for classes and categories
              const GridCategorySection(),

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

              // Recent Activity Section
              Consumer(
                builder: (context, ref, child) {
                  return categoriesAsync.when(
                    data: (categories) => _RecentActivitySection(categories: categories),
                    loading: () => const _RecentActivityLoadingSection(),
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
    final totalQuestions = stats['totalQuestions'] ?? 0;
    final categories = (stats['categoryCounts'] as Map?)?.length ?? 0;
    final imageQuestions = stats['imageQuestions'] ?? 0;

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
                  value: totalQuestions.toString(),
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
                  title: 'With Images',
                  value: imageQuestions.toString(),
                  icon: Icons.image,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                  // Navigate to random quiz
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessCard(
                title: 'Practice Mode',
                subtitle: 'No time limit',
                icon: Icons.fitness_center,
                color: Colors.teal,
                onTap: () {
                  // Navigate to practice mode
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

class _RecentActivitySection extends StatelessWidget {
  final List<String> categories;

  const _RecentActivitySection({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

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
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.take(6).length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < categories.length - 1 ? 12 : 0,
                ),
                child: _CategoryChip(category: category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final color = colors[category.hashCode % colors.length];

    return GestureDetector(
      onTap: () {
        // Navigate to category quiz
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'sports':
        return Icons.sports_soccer;
      case 'geography':
        return Icons.public;
      case 'technology':
        return Icons.computer;
      case 'literature':
        return Icons.menu_book;
      case 'math':
        return Icons.calculate;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.quiz;
    }
  }
}

class _RecentActivityLoadingSection extends StatelessWidget {
  const _RecentActivityLoadingSection();

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
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                child: Container(
                  width: 80,
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
                        width: 50,
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

// Bottom Navigation for QuestionScreen
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

// Create Quiz Bottom Sheet
class _CreateQuizBottomSheet extends StatefulWidget {
  @override
  State<_CreateQuizBottomSheet> createState() => _CreateQuizBottomSheetState();
}

class _CreateQuizBottomSheetState extends State<_CreateQuizBottomSheet> {
  String selectedDifficulty = 'Mixed';
  String selectedCategory = 'All Categories';
  int questionCount = 10;

  final List<String> difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];
  final List<String> categories = [
    'All Categories',
    'Science',
    'History',
    'Geography',
    'Entertainment',
    'Entertainment',
    'Sports',
    'Technology',
    'Literature',
    'Mathematics'
  ];

  @override
  Widget build(BuildContext context) {
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

                  // Category Selection
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
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

                  const SizedBox(height: 32),

                  // Quick Templates
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
                          // Navigate to quick quiz
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickTemplate(
                        title: 'Study Session',
                        subtitle: '20 questions, progressive difficulty',
                        icon: Icons.school,
                        color: Colors.blue,
                        onTap: () {
                          // Navigate to study session
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickTemplate(
                        title: 'Expert Challenge',
                        subtitle: '15 hard questions',
                        icon: Icons.psychology,
                        color: Colors.red,
                        onTap: () {
                          // Navigate to expert challenge
                          Navigator.pop(context);
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
