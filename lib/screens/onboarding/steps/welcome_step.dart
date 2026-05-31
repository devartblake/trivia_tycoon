import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../../../screens/menu/layouts/responsive_builder.dart';

class WelcomeStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const WelcomeStep({super.key, required this.controller});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Subtle breathing effect for background (0.85 → 1.0 → 0.85)
    _breatheAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 1),
    ]).animate(CurvedAnimation(
      parent: AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat(),
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileLayout(context);
    return isMobile ? _buildMobile(context) : _buildWide(context);
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background illustration
        _AnimatedBackground(animation: _breatheAnimation),

        // Decorative elements
        Positioned(
          top: 60,
          right: 20,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/welcome_images/Moon-Crescent.png',
              width: 70,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/welcome_images/Sun-Red.png',
              width: 55,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Bottom illustration
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/welcome_images/Illustration-Blue.png',
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Content overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _Logo(),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to\nSynaptix!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Test your knowledge, climb the ranks,\nand become a trivia champion!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 2),
                    _FeatureList(),
                    const Spacer(flex: 1),
                    _GetStartedButton(
                      onTap: widget.controller.nextStep,
                      maxWidth: double.infinity,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = isDesktopLayout(context);

    return Row(
      children: [
        // Left: full-bleed illustration panel
        Expanded(
          flex: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedBackground(animation: _breatheAnimation),
              Positioned(
                top: 40,
                right: 40,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/welcome_images/Moon-Crescent.png',
                    width: 100,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 30,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/welcome_images/Sun-Red.png',
                    width: 70,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/welcome_images/Illustration-Blue.png',
                    height: isDesktop ? 480 : 360,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.emoji_events,
                      size: 160,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right: content
        Expanded(
          flex: 50,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 48.0 : 32.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Logo(),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to\nSynaptix!',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Test your knowledge, climb the ranks, and become a trivia champion!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _FeatureList(),
                    const SizedBox(height: 48),
                    _GetStartedButton(
                      onTap: widget.controller.nextStep,
                      maxWidth: 400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/welcome_images/Bg-Blue.png'),
              fit: BoxFit.cover,
              onError: (_, __) {},
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo/synaptix_logo.png',
      height: 40,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _FeatureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeatureRow(
          icon: Icons.psychology_outlined,
          title: 'Multiple Categories',
          description: 'Choose your favorite topics',
        ),
        const SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.leaderboard_outlined,
          title: 'Compete Globally',
          description: 'Challenge players worldwide',
        ),
        const SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.stars_outlined,
          title: 'Earn Rewards',
          description: 'Unlock achievements & badges',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  final double maxWidth;

  const _GetStartedButton({required this.onTap, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
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
                'Get Started',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
