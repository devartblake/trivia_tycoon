import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/bottom_nav/question_screen_bottom_nav.dart';
import 'package:trivia_tycoon/screens/question/widgets/categories/featured_categories_loading.dart';
import 'package:trivia_tycoon/screens/question/widgets/categories/featured_categories_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/create_quiz/create_quiz_bottom_sheet.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/carousel_challenge_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/main_sections/grid_category_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/quick_access/quick_access_section.dart';
import 'package:trivia_tycoon/screens/question/widgets/stats/stats_loading_card.dart';
import 'package:trivia_tycoon/screens/question/widgets/stats/stats_overview_card.dart';
import '../../game/providers/question_providers.dart';
import '../question/widgets/main_sections/top_menu_section.dart';
import '../question/widgets/main_sections/grid_menu_section.dart';
import '../question/widgets/main_sections/cta_widget.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-load some data
    _preloadData();
  }

  void _preloadData() async {
    try {
<<<<<<< codex/fix-error-in-user-flow-implementation-ze69j1
      final repository = ref.read(questionRepositoryProvider);
      await repository.getDailyQuestions();
      await repository.getAvailableCategories();
=======
      final hubService = ref.read(questionHubServiceProvider);
      await hubService.getDailyQuiz(questionCount: 5);
      await hubService.getAvailableCategories();
>>>>>>> main
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
      builder: (context) => CreateQuizBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(questionStatsProvider);
    final categoriesAsync = ref.watch(quizCategoriesProvider);

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

              _buildPrimaryQuizLaunchPanel(context),

              const SizedBox(height: 20),

              // Quick Access Section with QuizCategory integration
              QuickAccessSection(),

              const SizedBox(height: 24),

              // Grid Menu Section for classes and categories
              const GridMenuSection(),

              const SizedBox(height: 24),

              // Stats Overview Card
              Consumer(
                builder: (context, ref, child) {
                  return statsAsync.when(
                    data: (stats) => StatsOverviewCard(stats: stats),
                    loading: () => const StatsLoadingCard(),
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
                    data: (categories) => FeaturedCategoriesSection(categories: categories),
                    loading: () => const FeaturedCategoriesLoadingSection(),
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
      bottomNavigationBar: QuestionScreenBottomNav(
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

<<<<<<< codex/fix-error-in-user-flow-implementation-ze69j1

=======
>>>>>>> main
  Widget _buildPrimaryQuizLaunchPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Play Quiz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this hub to start single-player, multiplayer, or category quizzes.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLaunchChip(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Single Player',
                  route: '/quiz/play',
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLaunchChip(
                  context: context,
                  icon: Icons.groups_outlined,
                  label: 'Multiplayer',
                  route: '/multiplayer',
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLaunchChip(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  label: 'Categories',
                  route: '/all-categories',
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

