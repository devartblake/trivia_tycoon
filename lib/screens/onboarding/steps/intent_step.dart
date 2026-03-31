import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../widgets/onboarding_step_shell.dart';

/// Asks the user why they're here: Train Mind / Compete / Play.
///
/// Stores `intent: train|compete|play` in the onboarding controller,
/// which later maps to a preferred home surface.
class IntentStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const IntentStep({super.key, required this.controller});

  @override
  State<IntentStep> createState() => _IntentStepState();
}

class _IntentStepState extends State<IntentStep> {
  String? _selected;

  static const _options = [
    _IntentOption(
      id: 'train',
      label: 'Train My Mind',
      emoji: '🧠',
      description: 'Build knowledge through guided pathways',
      color: Colors.teal,
    ),
    _IntentOption(
      id: 'compete',
      label: 'Compete',
      emoji: '🏆',
      description: 'Climb the ranks and challenge others',
      color: Colors.purple,
    ),
    _IntentOption(
      id: 'play',
      label: 'Just Play',
      emoji: '🎮',
      description: 'Explore fun quizzes and mini-games',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.intent;
  }

  void _select(String id) {
    setState(() => _selected = id);
  }

  void _continue() {
    if (_selected == null) return;
    widget.controller.updateUserData({'intent': _selected});
    widget.controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingStepShell(
      hero: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('🎯', style: TextStyle(fontSize: 40)),
        ),
      ),
      title: 'What brings you here?',
      subtitle: 'We\'ll tailor your experience to match your goal',
      child: ListView.separated(
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final opt = _options[index];
          final isSelected = _selected == opt.id;

          return GestureDetector(
            onTap: () => _select(opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? opt.color.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? opt.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? opt.color.withValues(alpha: 0.2)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(opt.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? opt.color : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: opt.color, size: 28),
                ],
              ),
            ),
          );
        },
      ),
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _selected != null ? _continue : null,
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
    );
  }
}

class _IntentOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const _IntentOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}
