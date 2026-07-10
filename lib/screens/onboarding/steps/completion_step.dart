import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../../../screens/menu/layouts/responsive_builder.dart';

class CompletionStep extends StatefulWidget {
  final ModernOnboardingController controller;
  final VoidCallback onComplete;

  const CompletionStep({
    super.key,
    required this.controller,
    required this.onComplete,
  });

  @override
  State<CompletionStep> createState() => _CompletionStepState();
}

class _CompletionStepState extends State<CompletionStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeroIcon(BuildContext context, {double size = 120}) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.celebration_outlined,
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWide(
    BuildContext context,
    ThemeData theme,
    String username,
    List<dynamic> categories,
  ) {
    return Row(
      children: [
        // Left panel — celebration hero
        Expanded(
          flex: 45,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeroIcon(context, size: 180),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      '🎉',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right panel — summary + CTA
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Set, $username!',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re ready to start your trivia journey',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child:
                      _buildSummaryCard(context, theme, username, categories),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildStartButton(context, theme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    String username,
    List<dynamic> categories,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(context,
              icon: Icons.person_outline, label: 'Username', value: username),
          if (widget.controller.userData['ageGroup'] != null) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(context,
                icon: Icons.cake_outlined,
                label: 'Age Group',
                value: widget.controller.userData['ageGroup']),
          ],
          if (widget.controller.userData['country'] != null) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(context,
                icon: Icons.public_outlined,
                label: 'Country',
                value: widget.controller.userData['country']),
          ],
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCategoriesRow(context, theme, categories),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(
      BuildContext context, ThemeData theme, List<dynamic> categories) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.category_outlined,
            size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interests',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.take(5).map((cat) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatCategoryName(cat.toString()),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  );
                }).toList(),
              ),
              if (categories.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+${categories.length - 5} more',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onComplete,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start Playing!',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.rocket_launch, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = widget.controller.userData['username'] ?? 'Player';
    final categories =
        widget.controller.userData['categories'] as List<dynamic>? ?? [];
    final isMobile = isMobileLayout(context);

    if (!isMobile) {
      return _buildWide(context, theme, username, categories);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          _buildHeroIcon(context),

          const SizedBox(height: 32),

          // Success message
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Text(
                    'All Set, $username!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'re ready to start your trivia journey',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Summary card
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  _buildSummaryRow(
                    context,
                    icon: Icons.person_outline,
                    label: 'Username',
                    value: username,
                  ),

                  const SizedBox(height: 12),

                  // Age group
                  if (widget.controller.userData['ageGroup'] != null)
                    _buildSummaryRow(
                      context,
                      icon: Icons.cake_outlined,
                      label: 'Age Group',
                      value: widget.controller.userData['ageGroup'],
                    ),

                  const SizedBox(height: 12),

                  // Country
                  if (widget.controller.userData['country'] != null)
                    _buildSummaryRow(
                      context,
                      icon: Icons.public_outlined,
                      label: 'Country',
                      value: widget.controller.userData['country'],
                    ),

                  const SizedBox(height: 12),

                  // Categories
                  if (categories.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interests',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: categories.take(5).map((cat) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatCategoryName(cat.toString()),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (categories.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '+${categories.length - 5} more',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Start button
          FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onComplete,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Playing!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.rocket_launch, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCategoryName(String id) {
    return id
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
