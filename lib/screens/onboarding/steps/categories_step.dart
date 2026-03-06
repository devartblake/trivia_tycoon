import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

class CategoriesStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const CategoriesStep({
    super.key,
    required this.controller,
  });

  @override
  State<CategoriesStep> createState() => _CategoriesStepState();
}

class _CategoriesStepState extends State<CategoriesStep> {
  final Set<String> _selectedCategories = {};

  final List<TriviaCategory> _categories = [
    TriviaCategory(
      id: 'general_knowledge',
      name: 'General Knowledge',
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      emoji: '💡',
    ),
    TriviaCategory(
      id: 'science',
      name: 'Science & Nature',
      icon: Icons.science_outlined,
      color: Colors.green,
      emoji: '🔬',
    ),
    TriviaCategory(
      id: 'history',
      name: 'History',
      icon: Icons.history_edu_outlined,
      color: Colors.brown,
      emoji: '📜',
    ),
    TriviaCategory(
      id: 'geography',
      name: 'Geography',
      icon: Icons.public_outlined,
      color: Colors.blue,
      emoji: '🌍',
    ),
    TriviaCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_outlined,
      color: Colors.purple,
      emoji: '🎬',
    ),
    TriviaCategory(
      id: 'sports',
      name: 'Sports',
      icon: Icons.sports_soccer_outlined,
      color: Colors.orange,
      emoji: '⚽',
    ),
    TriviaCategory(
      id: 'arts_literature',
      name: 'Arts & Literature',
      icon: Icons.palette_outlined,
      color: Colors.pink,
      emoji: '🎨',
    ),
    TriviaCategory(
      id: 'technology',
      name: 'Technology',
      icon: Icons.computer_outlined,
      color: Colors.indigo,
      emoji: '💻',
    ),
    TriviaCategory(
      id: 'music',
      name: 'Music',
      icon: Icons.music_note_outlined,
      color: Colors.deepPurple,
      emoji: '🎵',
    ),
    TriviaCategory(
      id: 'food_drink',
      name: 'Food & Drink',
      icon: Icons.restaurant_outlined,
      color: Colors.red,
      emoji: '🍕',
    ),
    TriviaCategory(
      id: 'mythology',
      name: 'Mythology',
      icon: Icons.auto_awesome_outlined,
      color: Colors.deepOrange,
      emoji: '⚡',
    ),
    TriviaCategory(
      id: 'animals',
      name: 'Animals',
      icon: Icons.pets_outlined,
      color: Colors.teal,
      emoji: '🐾',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select if data exists
    if (widget.controller.userData['categories'] != null) {
      final List<dynamic> savedCategories =
          widget.controller.userData['categories'];
      _selectedCategories.addAll(savedCategories.cast<String>());
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  void _continue() {
    if (_selectedCategories.isNotEmpty) {
      widget.controller.updateUserData({
        'categories': _selectedCategories.toList(),
      });
      widget.controller.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji hero
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '🎯',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Pick your interests',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle with selection count
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose categories you would like to master',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_selectedCategories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedCategories.length} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Categories grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category.id);

                return _buildCategoryCard(
                  context,
                  category: category,
                  isSelected: isSelected,
                  onTap: () => _toggleCategory(category.id),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedCategories.isNotEmpty ? _continue : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedCategories.isEmpty
                    ? 'Select at least one category'
                    : 'Continue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required TriviaCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category.color.withValues(alpha: 0.8),
                    category.color.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  // Category name
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Check mark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: category.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TriviaCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  const TriviaCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}
