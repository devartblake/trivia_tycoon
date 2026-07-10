import 'package:flutter/material.dart';
import '../../../screens/menu/layouts/responsive_builder.dart';

/// Shared layout shell for onboarding steps.
///
/// Mobile: single-column with hero, title, subtitle, scrollable content, CTA.
/// Tablet/Desktop: split-panel — left panel shows [panelIllustration] (or [hero]
/// as fallback) and the right panel holds the form content.
class OnboardingStepShell extends StatelessWidget {
  final Widget hero;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  /// Optional widget shown in the left panel on tablet/desktop.
  /// Falls back to [hero] when not provided.
  final Widget? panelIllustration;

  /// Optional background color tint for the left panel.
  final Color? panelBackgroundColor;

  const OnboardingStepShell({
    super.key,
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.panelIllustration,
    this.panelBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileLayout(context);

    if (isMobile) {
      return _MobileLayout(
        hero: hero,
        title: title,
        subtitle: subtitle,
        footer: footer,
        child: child,
      );
    }

    final isDesktop = isDesktopLayout(context);
    return _SplitLayout(
      hero: hero,
      title: title,
      subtitle: subtitle,
      footer: footer,
      panelIllustration: panelIllustration,
      panelBackgroundColor: panelBackgroundColor,
      isDesktop: isDesktop,
      child: child,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget hero;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const _MobileLayout({
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hero,
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
          const SizedBox(height: 24),
          if (footer != null) footer!,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SplitLayout extends StatelessWidget {
  final Widget hero;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? panelIllustration;
  final Color? panelBackgroundColor;
  final bool isDesktop;

  const _SplitLayout({
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.panelIllustration,
    this.panelBackgroundColor,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftFlex = isDesktop ? 45 : 40;
    final rightFlex = isDesktop ? 55 : 60;

    return Row(
      children: [
        // Left illustration panel
        Expanded(
          flex: leftFlex,
          child: _LeftPanel(
            illustration: panelIllustration ?? hero,
            backgroundColor: panelBackgroundColor,
          ),
        ),
        // Right form panel
        Expanded(
          flex: rightFlex,
          child: _RightPanel(
            title: title,
            subtitle: subtitle,
            footer: footer,
            isDesktop: isDesktop,
            theme: theme,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final Widget illustration;
  final Color? backgroundColor;

  const _LeftPanel({required this.illustration, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColor != null
              ? [backgroundColor!, backgroundColor!.withValues(alpha: 0.7)]
              : [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle diagonal line overlay
          Positioned.fill(
            child: CustomPaint(painter: _DiagonalLinePainter(theme)),
          ),
          // Illustration content
          Center(child: illustration),
        ],
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  final ThemeData theme;

  _DiagonalLinePainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.05)
      ..strokeWidth = 1.5;

    const spacing = 32.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter oldDelegate) => false;
}

class _RightPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool isDesktop;
  final ThemeData theme;

  const _RightPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    required this.isDesktop,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final padding =
        isDesktop ? const EdgeInsets.all(32) : const EdgeInsets.all(24);

    final titleStyle = isDesktop
        ? theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
          const SizedBox(height: 16),
          if (footer != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: footer!,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
