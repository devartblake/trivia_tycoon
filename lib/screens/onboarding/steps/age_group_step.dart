import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

class AgeGroupStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const AgeGroupStep({
    super.key,
    required this.controller,
  });

  @override
  State<AgeGroupStep> createState() => _AgeGroupStepState();
}

class _AgeGroupStepState extends State<AgeGroupStep> {
  String? _selectedAgeGroup;

  final List<AgeGroupOption> _ageGroups = [
    AgeGroupOption(
      id: 'kids',
      label: 'Under 13',
      emoji: '🧒',
      description: 'Fun & educational quizzes',
      color: Colors.pink,
    ),
    AgeGroupOption(
      id: 'teens',
      label: '13-17',
      emoji: '🎓',
      description: 'Challenging teen questions',
      color: Colors.purple,
    ),
    AgeGroupOption(
      id: 'adults',
      label: '18-24',
      emoji: '🎯',
      description: 'Young adult knowledge',
      color: Colors.blue,
    ),
    AgeGroupOption(
      id: 'general',
      label: '25+',
      emoji: '🏆',
      description: 'Expert-level trivia',
      color: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select if data exists
    if (widget.controller.userData['ageGroup'] != null) {
      _selectedAgeGroup = widget.controller.userData['ageGroup'];
    }
  }

  void _selectAgeGroup(String id) {
    setState(() {
      _selectedAgeGroup = id;
    });
  }

  void _continue() {
    if (_selectedAgeGroup != null) {
      widget.controller.updateUserData({
        'ageGroup': _selectedAgeGroup,
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
                '🎂',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Select your age group',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'We\'ll tailor content to match your level',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Age group cards
          Expanded(
            child: ListView.separated(
              itemCount: _ageGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _ageGroups[index];
                final isSelected = _selectedAgeGroup == option.id;

                return _buildAgeGroupCard(
                  context,
                  option: option,
                  isSelected: isSelected,
                  onTap: () => _selectAgeGroup(option.id),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedAgeGroup != null ? _continue : null,
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

  Widget _buildAgeGroupCard(
      BuildContext context, {
        required AgeGroupOption option,
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withValues(alpha: 0.2)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? option.color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: option.color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

class AgeGroupOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const AgeGroupOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}