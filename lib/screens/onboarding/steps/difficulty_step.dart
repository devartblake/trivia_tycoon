import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

/// Optional step for selecting difficulty level
/// Add this to onboarding flow if you want difficulty selection
class DifficultyStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const DifficultyStep({
    super.key,
    required this.controller,
  });

  @override
  State<DifficultyStep> createState() => _DifficultyStepState();
}

class _DifficultyStepState extends State<DifficultyStep> {
  String? _selectedDifficulty;

  final List<DifficultyOption> _difficulties = [
    DifficultyOption(
      id: 'easy',
      label: 'Easy',
      emoji: '🌱',
      description: 'Relaxed pace, simpler questions',
      color: Colors.green,
      timePerQuestion: '30 seconds',
      questionDifficulty: 'Beginner friendly',
    ),
    DifficultyOption(
      id: 'medium',
      label: 'Medium',
      emoji: '⚡',
      description: 'Balanced challenge',
      color: Colors.blue,
      timePerQuestion: '20 seconds',
      questionDifficulty: 'Mixed difficulty',
    ),
    DifficultyOption(
      id: 'hard',
      label: 'Hard',
      emoji: '🔥',
      description: 'Fast-paced, expert level',
      color: Colors.orange,
      timePerQuestion: '15 seconds',
      questionDifficulty: 'Advanced',
    ),
    DifficultyOption(
      id: 'expert',
      label: 'Expert',
      emoji: '💎',
      description: 'Ultimate challenge',
      color: Colors.purple,
      timePerQuestion: '10 seconds',
      questionDifficulty: 'Master level',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select if data exists
    if (widget.controller.userData['difficulty'] != null) {
      _selectedDifficulty = widget.controller.userData['difficulty'];
    } else {
      // Default to medium
      _selectedDifficulty = 'medium';
    }
  }

  void _selectDifficulty(String id) {
    setState(() {
      _selectedDifficulty = id;
    });
  }

  void _continue() {
    if (_selectedDifficulty != null) {
      widget.controller.updateUserData({
        'difficulty': _selectedDifficulty,
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
          const Spacer(),

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
                '🎮',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Choose your difficulty',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Don\'t worry, you can change this later',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Difficulty cards
          Expanded(
            child: ListView.separated(
              itemCount: _difficulties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _difficulties[index];
                final isSelected = _selectedDifficulty == option.id;

                return _buildDifficultyCard(
                  context,
                  option: option,
                  isSelected: isSelected,
                  onTap: () => _selectDifficulty(option.id),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _continue,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue',
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

  Widget _buildDifficultyCard(
    BuildContext context, {
    required DifficultyOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? option.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withValues(alpha: 0.2)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? option.color : null,
                        ),
                      ),
                      if (option.id == 'medium')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        option.timePerQuestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        option.questionDifficulty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: option.color,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}

class DifficultyOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  final String timePerQuestion;
  final String questionDifficulty;

  const DifficultyOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
    required this.timePerQuestion,
    required this.questionDifficulty,
  });
}
