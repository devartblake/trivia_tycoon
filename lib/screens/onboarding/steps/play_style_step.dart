import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../widgets/onboarding_step_shell.dart';

/// Collects the user's play-style signal for personalisation.
///
/// Stores `playStyle: fast|strategic|explorer` in the onboarding controller.
class PlayStyleStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const PlayStyleStep({super.key, required this.controller});

  @override
  State<PlayStyleStep> createState() => _PlayStyleStepState();
}

class _PlayStyleStepState extends State<PlayStyleStep> {
  String? _selected;

  static const _options = [
    _StyleOption(
      id: 'fast',
      label: 'Fast Thinker',
      emoji: '⚡',
      description: 'Quick answers, tight timers',
      color: Colors.amber,
    ),
    _StyleOption(
      id: 'strategic',
      label: 'Strategic Mind',
      emoji: '♟️',
      description: 'Careful analysis, higher stakes',
      color: Colors.indigo,
    ),
    _StyleOption(
      id: 'explorer',
      label: 'Explorer',
      emoji: '🌍',
      description: 'Wide variety, learn as you go',
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.playStyle;
  }

  void _select(String id) {
    setState(() => _selected = id);
  }

  void _continue() {
    if (_selected == null) return;
    widget.controller.updateUserData({'playStyle': _selected});
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
          child: Text('🎲', style: TextStyle(fontSize: 40)),
        ),
      ),
      title: 'How do you play?',
      subtitle: 'Pick the style that matches you best',
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

class _StyleOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const _StyleOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}
