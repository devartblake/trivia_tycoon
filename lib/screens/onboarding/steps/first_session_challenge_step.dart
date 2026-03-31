import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

/// A lightweight 3-question challenge embedded in onboarding.
///
/// Uses local questions (no network dependency) to give the user an
/// "experience moment" before they reach the Hub. Stores score and
/// completion flag in the onboarding controller.
class FirstSessionChallengeStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const FirstSessionChallengeStep({super.key, required this.controller});

  @override
  State<FirstSessionChallengeStep> createState() =>
      _FirstSessionChallengeStepState();
}

class _FirstSessionChallengeStepState extends State<FirstSessionChallengeStep>
    with SingleTickerProviderStateMixin {
  int _currentQ = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _revealed = false;
  late final AnimationController _feedbackController;
  late final Animation<double> _feedbackAnimation;

  static const _questions = [
    {
      'question': 'Which planet is known as the Red Planet?',
      'answers': ['Earth', 'Mars', 'Venus', 'Jupiter'],
      'correctIndex': 1,
    },
    {
      'question': 'How many sides does a hexagon have?',
      'answers': ['5', '6', '7', '8'],
      'correctIndex': 1,
    },
    {
      'question': 'Which element has the chemical symbol "O"?',
      'answers': ['Gold', 'Iron', 'Oxygen', 'Silver'],
      'correctIndex': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_revealed) return;
    setState(() {
      _selectedAnswer = index;
      _revealed = true;
      if (index == (_questions[_currentQ]['correctIndex'] as int)) {
        _score++;
      }
    });
    _feedbackController.forward(from: 0);

    // Auto-advance after short delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQ < _questions.length - 1) {
        setState(() {
          _currentQ++;
          _selectedAnswer = null;
          _revealed = false;
        });
      } else {
        // Challenge complete — save results and advance
        widget.controller.updateUserData({
          'firstChallengeScore': _score,
          'firstChallengeTotal': _questions.length,
          'firstChallengeCompleted': true,
        });
        widget.controller.nextStep();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[_currentQ];
    final answers = q['answers'] as List<String>;
    final correctIndex = q['correctIndex'] as int;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Progress chips
          Row(
            children: List.generate(_questions.length, (i) {
              Color chipColor;
              if (i < _currentQ) {
                chipColor = theme.colorScheme.primary;
              } else if (i == _currentQ) {
                chipColor = theme.colorScheme.primary.withValues(alpha: 0.5);
              } else {
                chipColor = theme.colorScheme.surfaceContainerHighest;
              }
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < _questions.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Header
          Text(
            'Quick Challenge',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Question ${_currentQ + 1} of ${_questions.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Question
          Text(
            q['question'] as String,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 32),

          // Answers
          Expanded(
            child: ListView.separated(
              itemCount: answers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final isCorrect = index == correctIndex;
                final isSelected = index == _selectedAnswer;

                Color bgColor;
                Color borderColor;
                if (_revealed && isCorrect) {
                  bgColor = Colors.green.withValues(alpha: 0.1);
                  borderColor = Colors.green;
                } else if (_revealed && isSelected && !isCorrect) {
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  borderColor = Colors.red;
                } else if (isSelected) {
                  bgColor = theme.colorScheme.primaryContainer;
                  borderColor = theme.colorScheme.primary;
                } else {
                  bgColor = theme.colorScheme.surfaceContainerHighest;
                  borderColor = Colors.transparent;
                }

                return GestureDetector(
                  onTap: () => _selectAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: borderColor != Colors.transparent
                                ? borderColor.withValues(alpha: 0.2)
                                : theme.colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _revealed && isCorrect
                                ? const Icon(Icons.check, color: Colors.green, size: 20)
                                : _revealed && isSelected && !isCorrect
                                    ? const Icon(Icons.close, color: Colors.red, size: 20)
                                    : Text(
                                        String.fromCharCode(65 + index),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            answers[index],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Score indicator
          if (_revealed)
            FadeTransition(
              opacity: _feedbackAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(
                  _selectedAnswer == correctIndex
                      ? 'Correct! 🎉'
                      : 'Not quite — the answer is ${answers[correctIndex]}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _selectedAnswer == correctIndex
                        ? Colors.green
                        : Colors.red,
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
}
