import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/providers/favorites_providers.dart';
import '../../../core/delegates/sliver_appbar_delegate.dart';
import '../../../game/models/favorite_category_models.dart';
import '../../../game/models/favorite_question_models.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class FavoritesQuizScreen extends ConsumerStatefulWidget {
  const FavoritesQuizScreen({super.key});

  @override
  ConsumerState<FavoritesQuizScreen> createState() =>
      _FavoritesQuizScreenEnhancedState();
}

class _FavoritesQuizScreenEnhancedState
    extends ConsumerState<FavoritesQuizScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // Load mock data - replace with actual data loading
    ref
        .read(favoriteCategoriesProvider.notifier)
        .loadCategories(_getMockCategories());
    ref
        .read(favoriteQuestionsProvider.notifier)
        .loadQuestions(_getMockQuestions());
  }

  @override
  Widget build(BuildContext context) {
    final categoriesCount =
        ref.watch(favoriteCategoriesProvider).where((c) => c.isFavorite).length;
    final questionsCount =
        ref.watch(favoriteQuestionsProvider).where((q) => q.isFavorite).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(categoriesCount, questionsCount),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoriesTabContent(),
            _buildQuestionsTabContent(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(int categoriesCount, int questionsCount) {
    return SliverAppBar(
      expandedHeight: 220, // Increased height slightly for better spacing
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1), // Fallback color when collapsed
      // Use a dedicated leading widget for the back button.
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      // Use the actions property for buttons on the right.
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showSortOptions,
              icon: const Icon(
                Icons.sort,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // This Column now only contains the title and search bar.
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Push content to the bottom
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Favorites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$categoriesCount categories • $questionsCount questions',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 16), // Add padding below search bar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search favorites...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6366F1),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        Container(
          color: Colors.white,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorColor: const Color(0xFF6366F1),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, size: 18),
                        SizedBox(width: 8),
                        Text('Categories'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 18),
                        SizedBox(width: 8),
                        Text('Questions'),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTabContent() {
    final categories = ref.watch(filteredCategoriesProvider(_searchQuery));

    if (categories.isEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: Icons.category_outlined,
          title: _searchQuery.isEmpty
              ? 'No favorite categories yet'
              : 'No categories found',
          subtitle: _searchQuery.isEmpty
              ? 'Start adding categories to your favorites!'
              : 'Try a different search term',
          actionText: _searchQuery.isEmpty ? 'Browse Categories' : null,
          onAction: _searchQuery.isEmpty ? () {} : null,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildQuestionsTabContent() {
    final questions = ref.watch(filteredQuestionsProvider(_searchQuery));

    if (questions.isEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: Icons.quiz_outlined,
          title: _searchQuery.isEmpty
              ? 'No favorite questions yet'
              : 'No questions found',
          subtitle: _searchQuery.isEmpty
              ? 'Mark questions as favorites while playing!'
              : 'Try a different search term',
          actionText: _searchQuery.isEmpty ? 'Start Quiz' : null,
          onAction: _searchQuery.isEmpty ? () {} : null,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildCategoryCard(FavoriteCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategoryTap(category),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Category Icon with gradient
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color,
                        category.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Category Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 16,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.questionCount} questions',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(category.progress, category.color),
                    ],
                  ),
                ),

                // Favorite Button
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: () => _toggleCategoryFavorite(category.id),
                    icon: Icon(
                      category.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: category.isFavorite
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(FavoriteQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onQuestionTap(question),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              // <-- This is the parent Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Row(
                  children: [
                    // ... (rest of the header row is correct)
                    _buildDifficultyBadge(question.difficulty),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _toggleQuestionFavorite(question.id),
                      icon: Icon(
                        question.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: question.isFavorite
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Question Text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildStatChip(
                        Icons.check_circle,
                        question.correctCount.toString(),
                        const Color(0xFF10B981),
                        'Correct',
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        Icons.cancel,
                        question.incorrectCount.toString(),
                        const Color(0xFFEF4444),
                        'Wrong',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(question.addedDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // MOVED FROM HERE
                    ],
                  ),
                ),
                // AND MOVED TO HERE, inside the Column
                const SizedBox(height: 12),
                _buildAccuracyIndicator(question.accuracy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyIndicator(double accuracy) {
    Color color;
    String label;

    if (accuracy >= 0.8) {
      color = const Color(0xFF10B981);
      label = 'Excellent';
    } else if (accuracy >= 0.6) {
      color = const Color(0xFF3B82F6);
      label = 'Good';
    } else if (accuracy >= 0.4) {
      color = const Color(0xFFF59E0B);
      label = 'Fair';
    } else {
      color = const Color(0xFFEF4444);
      label = 'Needs Practice';
    }

    return Row(
      children: [
        // Give the progress bar a specific width
        Expanded(
          flex: 3, // Takes 3/5 of available space
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: accuracy,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Labels take remaining space
        Expanded(
          flex: 2, // Takes 2/5 of available space
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(accuracy * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    IconData icon;

    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        icon = Icons.sentiment_satisfied;
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        icon = Icons.sentiment_neutral;
        break;
      case 'hard':
        color = const Color(0xFFEF4444);
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        color = const Color(0xFF6B7280);
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            difficulty,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle,
      String? actionText,
      VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showFilterOptions,
      backgroundColor: const Color(0xFF6366F1),
      elevation: 4,
      icon: const Icon(Icons.filter_list, size: 22),
      label: const Text(
        'Filter',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            _buildSortOption('Most Recent', Icons.access_time),
            _buildSortOption('Name (A-Z)', Icons.sort_by_alpha),
            _buildSortOption('Most Questions', Icons.numbers),
            _buildSortOption('Highest Progress', Icons.trending_up),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        // Implement sort logic
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Difficulty',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('Easy', const Color(0xFF10B981)),
                      _buildFilterChip('Medium', const Color(0xFFF59E0B)),
                      _buildFilterChip('Hard', const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Science', const Color(0xFF10B981)),
                      _buildFilterChip('History', const Color(0xFF8B5CF6)),
                      _buildFilterChip('Sports', const Color(0xFFF59E0B)),
                      _buildFilterChip(
                          'Entertainment', const Color(0xFFEC4899)),
                      _buildFilterChip('Geography', const Color(0xFF3B82F6)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('0-25%', const Color(0xFFEF4444)),
                      _buildFilterChip('26-50%', const Color(0xFFF59E0B)),
                      _buildFilterChip('51-75%', const Color(0xFF3B82F6)),
                      _buildFilterChip('76-100%', const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Apply filters
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (bool selected) {
        // Handle filter selection
      },
      backgroundColor: Colors.white,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _onCategoryTap(FavoriteCategory category) {
    // Navigate to category quiz
    LogManager.debug('Category tapped: ${category.name}');
  }

  void _onQuestionTap(FavoriteQuestion question) {
    // Show question detail
    _showQuestionDetail(question);
  }

  void _showQuestionDetail(FavoriteQuestion question) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                question.categoryColor,
                                question.categoryColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            question.categoryIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: question.categoryColor,
                                ),
                              ),
                              Text(
                                'Question Detail',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailStats(question),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Start quiz with this question
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Practice This Question',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStats(FavoriteQuestion question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailStatItem(
                  'Correct',
                  question.correctCount.toString(),
                  Icons.check_circle,
                  const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildDetailStatItem(
                  'Wrong',
                  question.incorrectCount.toString(),
                  Icons.cancel,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailStatItem(
                  'Accuracy',
                  '${(question.accuracy * 100).toInt()}%',
                  Icons.trending_up,
                  const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildDetailStatItem(
                  'Difficulty',
                  question.difficulty,
                  Icons.speed,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  void _toggleCategoryFavorite(String categoryId) {
    ref.read(favoriteCategoriesProvider.notifier).toggleFavorite(categoryId);
  }

  void _toggleQuestionFavorite(String questionId) {
    ref.read(favoriteQuestionsProvider.notifier).toggleFavorite(questionId);
  }

  // Mock data methods (same as before)
  List<FavoriteCategory> _getMockCategories() {
    return [
      FavoriteCategory(
        id: '1',
        name: 'Science & Nature',
        icon: Icons.science,
        color: const Color(0xFF10B981),
        questionCount: 45,
        progress: 0.65,
        isFavorite: true,
      ),
      FavoriteCategory(
        id: '2',
        name: 'History',
        icon: Icons.history_edu,
        color: const Color(0xFF8B5CF6),
        questionCount: 32,
        progress: 0.42,
        isFavorite: true,
      ),
      FavoriteCategory(
        id: '3',
        name: 'Sports',
        icon: Icons.sports_soccer,
        color: const Color(0xFFF59E0B),
        questionCount: 28,
        progress: 0.78,
        isFavorite: true,
      ),
      FavoriteCategory(
        id: '4',
        name: 'Entertainment',
        icon: Icons.movie,
        color: const Color(0xFFEC4899),
        questionCount: 51,
        progress: 0.55,
        isFavorite: true,
      ),
    ];
  }

  List<FavoriteQuestion> _getMockQuestions() {
    return [
      FavoriteQuestion(
        id: '1',
        questionText: 'What is the largest planet in our solar system?',
        category: 'Science',
        categoryIcon: Icons.science,
        categoryColor: const Color(0xFF10B981),
        difficulty: 'Easy',
        correctCount: 8,
        incorrectCount: 2,
        addedDate: DateTime.now().subtract(const Duration(days: 2)),
        isFavorite: true,
      ),
      FavoriteQuestion(
        id: '2',
        questionText: 'In which year did World War II end?',
        category: 'History',
        categoryIcon: Icons.history_edu,
        categoryColor: const Color(0xFF8B5CF6),
        difficulty: 'Medium',
        correctCount: 12,
        incorrectCount: 3,
        addedDate: DateTime.now().subtract(const Duration(days: 5)),
        isFavorite: true,
      ),
      FavoriteQuestion(
        id: '3',
        questionText:
            'How many players are there in a basketball team on the court?',
        category: 'Sports',
        categoryIcon: Icons.sports_basketball,
        categoryColor: const Color(0xFFF59E0B),
        difficulty: 'Easy',
        correctCount: 15,
        incorrectCount: 1,
        addedDate: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
      ),
    ];
  }
}
