import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/controllers/onboarding_controller.dart';
import 'steps/welcome_step.dart';
import 'steps/username_step.dart';
import 'steps/age_group_step.dart';
import 'steps/country_step.dart';
import 'steps/categories_step.dart';
import 'steps/completion_step.dart';
import '../../game/providers/riverpod_providers.dart';

/// Modern onboarding screen with smooth step transitions
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final ModernOnboardingController _controller;
  late final PageController _pageController;
  late final AnimationController _progressAnimationController;

  @override
  void initState() {
    super.initState();
    _controller = ModernOnboardingController(totalSteps: 6);
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    // Animate to the new page
    _pageController.animateToPage(
      _controller.currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );

    // Animate progress bar
    _progressAnimationController.animateTo(
      _controller.progress,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleCompletion() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final profileService = serviceManager.playerProfileService;
    final onboardingService = serviceManager.onboardingSettingsService;

    // Save all user data
    await onboardingService.setOnboardingCompleted(true);
    await onboardingService.setHasCompletedOnboarding(true);

    if (_controller.userData['username'] != null) {
      await profileService.savePlayerName(_controller.userData['username']);
    }
    if (_controller.userData['ageGroup'] != null) {
      await profileService.saveAgeGroup(_controller.userData['ageGroup']);
    }
    if (_controller.userData['country'] != null) {
      await profileService.saveCountry(_controller.userData['country']);
    }
    if (_controller.userData['categories'] != null) {
      // Save preferred categories
      // await profileService.savePreferredCategories(_controller.userData['categories']);
    }

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _handleSkip() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final onboardingService = serviceManager.onboardingSettingsService;

    await onboardingService.setHasCompletedOnboarding(true);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and skip
            _buildHeader(context),

            // Main content area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WelcomeStep(controller: _controller),
                  UsernameStep(controller: _controller),
                  AgeGroupStep(controller: _controller),
                  CountryStep(controller: _controller),
                  CategoriesStep(controller: _controller),
                  CompletionStep(
                    controller: _controller,
                    onComplete: _handleCompletion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Skip button and progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button (hidden on first step)
              if (!_controller.isFirstStep)
                IconButton(
                  onPressed: _controller.previousStep,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 48),

              // Step indicator
              Text(
                'Step ${_controller.currentStep + 1} of ${_controller.totalSteps}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // Skip button (hidden on last step)
              if (!_controller.isLastStep)
                TextButton(
                  onPressed: _handleSkip,
                  child: const Text('Skip'),
                )
              else
                const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimationController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressAnimationController.value,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}