import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/screens/question/widgets/bottom_nav/question_screen_bottom_nav.dart';
import 'package:synaptix/screens/question/widgets/categories/featured_categories_loading.dart';
import 'package:synaptix/screens/question/widgets/categories/featured_categories_section.dart';
import 'package:synaptix/screens/question/widgets/create_quiz/create_quiz_bottom_sheet.dart';
import 'package:synaptix/screens/question/widgets/main_sections/carousel_challenge_section.dart';
import 'package:synaptix/screens/question/widgets/main_sections/grid_category_section.dart';
import 'package:synaptix/screens/question/widgets/quick_access/quick_access_section.dart';
import 'package:synaptix/screens/question/widgets/stats/stats_loading_card.dart';
import 'package:synaptix/screens/question/widgets/stats/stats_overview_card.dart';
import '../../core/helpers/responsive_layout.dart';
import '../../game/providers/question_providers.dart';
import '../question/widgets/main_sections/top_menu_section.dart';
import '../question/widgets/main_sections/grid_menu_section.dart';
import '../question/widgets/main_sections/cta_widget.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/game/services/quiz_category.dart';

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
      final repository = ref.read(questionRepositoryProvider);
      await Future.wait([
        repository.getDailyQuestions(),
        repository.getAvailableCategories(),
      ]);
    } catch (e) {
      // Handle silently for now
      LogManager.debug('Preload warning: $e');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Home - already here
        context.push(canonicalHomeRoute);
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
    final sourceStatus = ref.watch(serviceStatusProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppBreakpoints.classify(constraints.maxWidth);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: AppResponsiveWidth(
              tabletMaxWidth: 900,
              desktopMaxWidth: 1280,
              child: SingleChildScrollView(
                child: layout.isDesktop
                    ? _buildWideQuizContent(
                        sourceStatus,
                        statsAsync,
                        categoriesAsync,
                      )
                    : _buildMobileQuizContent(
                        sourceStatus,
                        statsAsync,
                        categoriesAsync,
                      ),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildMobileQuizContent(
    Map<String, dynamic> sourceStatus,
    AsyncValue<Map<String, dynamic>> statsAsync,
    AsyncValue<List<QuizCategory>> categoriesAsync,
  ) {
    return Column(
      children: [
        const TopMenuSection(),
        const SizedBox(height: 16),
        _buildQuestionSourceBanner(sourceStatus),
        const SizedBox(height: 24),
        const CarouselSection(),
        const SizedBox(height: 24),
        _buildPrimaryQuizLaunchPanel(context),
        const SizedBox(height: 20),
        const QuickAccessSection(),
        const SizedBox(height: 24),
        const GridMenuSection(),
        const SizedBox(height: 24),
        _buildStatsSection(statsAsync),
        const SizedBox(height: 24),
        GridCategorySection(),
        const SizedBox(height: 24),
        _buildPremiumCta(),
        const SizedBox(height: 24),
        _buildFeaturedCategoriesSection(categoriesAsync),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWideQuizContent(
    Map<String, dynamic> sourceStatus,
    AsyncValue<Map<String, dynamic>> statsAsync,
    AsyncValue<List<QuizCategory>> categoriesAsync,
  ) {
    return Column(
      children: [
        const TopMenuSection(),
        const SizedBox(height: 18),
        _buildQuestionSourceBanner(sourceStatus),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  const CarouselSection(),
                  const SizedBox(height: 24),
                  _buildPrimaryQuizLaunchPanel(context),
                  const SizedBox(height: 24),
                  const GridMenuSection(),
                  const SizedBox(height: 24),
                  GridCategorySection(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  const QuickAccessSection(),
                  const SizedBox(height: 24),
                  _buildStatsSection(statsAsync),
                  const SizedBox(height: 24),
                  _buildPremiumCta(),
                  const SizedBox(height: 24),
                  _buildFeaturedCategoriesSection(categoriesAsync),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => StatsOverviewCard(stats: stats),
      loading: () => const StatsLoadingCard(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildFeaturedCategoriesSection(
    AsyncValue<List<QuizCategory>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      data: (categories) => FeaturedCategoriesSection(categories: categories),
      loading: () => const FeaturedCategoriesLoadingSection(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildPremiumCta() {
    return CTAWidget(
      title: "Premium Unlock!",
      subtitle: "Get unlimited quizzes & remove ads",
      buttonText: "Upgrade Now",
      backgroundImage: 'assets/images/avatars/default-avatar.png',
      onPressed: () {
        _showPremiumDialog();
      },
    );
  }

  Widget _buildQuestionSourceBanner(Map<String, dynamic> status) {
    final source = status['source']?.toString() ?? 'unknown';
    final operation = status['operation']?.toString() ?? 'idle';
    final endpoint = status['endpoint']?.toString();
    final detail = status['detail']?.toString();

    final isBackend = source == 'backend';
    final isFallback = source == 'localFallback';

    final backgroundColor = isBackend
        ? const Color(0xFFECFDF5)
        : isFallback
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF8FAFC);
    final borderColor = isBackend
        ? const Color(0xFF10B981)
        : isFallback
            ? const Color(0xFFF59E0B)
            : const Color(0xFF94A3B8);
    final icon = isBackend
        ? Icons.cloud_done_rounded
        : isFallback
            ? Icons.warning_amber_rounded
            : Icons.sync_problem_rounded;
    final title = isBackend
        ? 'Question API connected'
        : isFallback
            ? 'Using local question fallback'
            : 'Question source not confirmed yet';
    final subtitle = detail ??
        (endpoint != null && endpoint.isNotEmpty
            ? 'Last check: $operation via $endpoint'
            : 'The quiz service has not reported a source yet.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 430;
              final chips = [
                _buildLaunchChip(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Single Player',
                  route: '/quiz/play',
                  color: const Color(0xFF2563EB),
                ),
                _buildLaunchChip(
                  context: context,
                  icon: Icons.groups_outlined,
                  label: 'Multiplayer',
                  route: '/multiplayer',
                  color: const Color(0xFF7C3AED),
                ),
                _buildLaunchChip(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  label: 'Categories',
                  route: '/all-categories',
                  color: const Color(0xFF059669),
                ),
              ];

              if (stack) {
                return Column(
                  children: [
                    for (final chip in chips) ...[
                      chip,
                      if (chip != chips.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final chip in chips) ...[
                    Expanded(child: chip),
                    if (chip != chips.last) const SizedBox(width: 10),
                  ],
                ],
              );
            },
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
