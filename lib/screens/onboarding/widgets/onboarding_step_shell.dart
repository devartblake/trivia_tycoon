import 'package:flutter/material.dart';

/// Shared layout shell for onboarding steps.
///
/// Provides consistent padding, hero area, title/subtitle, scrollable
/// content zone, and a bottom CTA button.
class OnboardingStepShell extends StatelessWidget {
  final Widget hero;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const OnboardingStepShell({
    super.key,
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),

          // Hero area
          hero,

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Main content
          Expanded(flex: 3, child: child),

          const SizedBox(height: 24),

          // Footer / CTA
          if (footer != null) footer!,

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
