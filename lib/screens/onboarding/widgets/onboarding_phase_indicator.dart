import 'package:flutter/material.dart';

class OnboardingPhaseIndicator extends StatelessWidget {
  final int currentStep;

  const OnboardingPhaseIndicator({super.key, required this.currentStep});

  static const _phases = [
    _PhaseData(label: 'Set Up', startStep: 0, endStep: 4),
    _PhaseData(label: 'Personalize', startStep: 5, endStep: 7),
    _PhaseData(label: 'Ready', startStep: 8, endStep: 10),
  ];

  int get _currentPhase => _phases.indexWhere(
        (p) => currentStep >= p.startStep && currentStep <= p.endStep,
      );

  int get _stepWithinPhase =>
      currentStep - _phases[_currentPhase].startStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePhase = _currentPhase;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phase pills row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _phases.length; i++) ...[
              _PhasePill(
                label: _phases[i].label,
                isActive: i == activePhase,
                isCompleted: i < activePhase,
              ),
              if (i < _phases.length - 1)
                _PhaseConnector(isCompleted: i < activePhase),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Step dots for active phase
        _StepDots(
          totalDots: _phases[activePhase].stepCount,
          activeDot: _stepWithinPhase,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _PhasePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _PhasePill({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Color bgColor;
    Color fgColor;
    Border? border;

    if (isCompleted) {
      bgColor = primary.withValues(alpha: 0.2);
      fgColor = primary;
      border = null;
    } else if (isActive) {
      bgColor = primary;
      fgColor = theme.colorScheme.onPrimary;
      border = null;
    } else {
      bgColor = Colors.transparent;
      fgColor = theme.colorScheme.onSurfaceVariant;
      border = Border.all(color: theme.colorScheme.outline, width: 1);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: isCompleted
          ? Icon(Icons.check, size: 14, color: fgColor)
          : Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
    );
  }
}

class _PhaseConnector extends StatelessWidget {
  final bool isCompleted;

  const _PhaseConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 2,
      color: color,
    );
  }
}

class _StepDots extends StatelessWidget {
  final int totalDots;
  final int activeDot;
  final Color color;

  const _StepDots({
    required this.totalDots,
    required this.activeDot,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < totalDots; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _buildDot(i),
        ],
      ],
    );
  }

  Widget _buildDot(int index) {
    double size;
    Color dotColor;

    if (index == activeDot) {
      size = 8;
      dotColor = color;
    } else if (index < activeDot) {
      size = 6;
      dotColor = color.withValues(alpha: 0.5);
    } else {
      size = 5;
      dotColor = color.withValues(alpha: 0.2);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PhaseData {
  final String label;
  final int startStep;
  final int endStep;

  const _PhaseData({
    required this.label,
    required this.startStep,
    required this.endStep,
  });

  int get stepCount => endStep - startStep + 1;
}
