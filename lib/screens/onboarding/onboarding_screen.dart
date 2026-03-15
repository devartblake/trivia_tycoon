import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/controllers/onboarding_controller.dart';
import 'steps/welcome_step.dart';
import 'steps/username_step.dart';
import 'steps/age_group_step.dart';
import 'steps/country_step.dart';
import 'steps/categories_step.dart';
import 'steps/avatar_step.dart';
import 'steps/completion_step.dart';
import '../../game/providers/onboarding_providers.dart';
import '../../game/providers/riverpod_providers.dart';

// Confetti particle class
class Confetti {
  double x;
  double y;
  final Color color;
  double rotation;
  final double speed = 0.02 + math.Random().nextDouble() * 0.02;
  final double drift = (math.Random().nextDouble() - 0.5) * 0.01;

  Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.rotation,
  });

  void update() {
    y += speed;
    x += drift;
    rotation += 0.1;

    if (y > 1.1) {
      y = -0.1;
    }
    if (x < -0.1) {
      x = 1.1;
    } else if (x > 1.1) {
      x = -0.1;
    }
  }
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;

  ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in confetti) {
      particle.update();

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation);

      // Draw confetti as small rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -8, 8, 16),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

/// Modern onboarding screen with smooth step transitions
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final ModernOnboardingController _controller;
  late final PageController _pageController;
  late final AnimationController _progressAnimationController;
  late final AnimationController _confettiAnimationController;
  late final List<Confetti> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = ModernOnboardingController(totalSteps: 7); // Updated to 7 steps (includes avatar)
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _confettiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _confetti = List.generate(80, (_) {
      final random = math.Random();
      final colors = [
        Colors.pinkAccent,
        Colors.amber,
        Colors.cyan,
        Colors.greenAccent,
        Colors.deepPurpleAccent,
      ];
      return Confetti(
        x: random.nextDouble(),
        y: random.nextDouble(),
        color: colors[random.nextInt(colors.length)],
        rotation: random.nextDouble() * math.pi * 2,
      );
    });

    _controller.addListener(_onControllerChanged);
    _restoreProgress();
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

    unawaited(_persistProgressSnapshot());
  }

  Future<void> _restoreProgress() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final onboardingService = serviceManager.onboardingSettingsService;
    final progress = await onboardingService.getOnboardingProgress();

    final restoredStep = progress.currentStep.clamp(0, _controller.totalSteps - 1);
    _controller.updateUserData({
      if (progress.username != null) 'username': progress.username,
      if (progress.ageGroup != null) 'ageGroup': progress.ageGroup,
      if (progress.country != null) 'country': progress.country,
      if (progress.categories.isNotEmpty) 'categories': progress.categories,
    });

    if (restoredStep > 0) {
      _controller.goToStep(restoredStep);
    }
  }

  Future<void> _persistProgressSnapshot({
    bool? completed,
    bool? hasCompletedProfile,
  }) async {
    final serviceManager = ref.read(serviceManagerProvider);
    final onboardingService = serviceManager.onboardingSettingsService;

    await onboardingService.updateOnboardingProgress(
      completed: completed,
      hasSeenIntro: _controller.currentStep > 0,
      hasCompletedProfile: hasCompletedProfile,
      currentStep: _controller.currentStep,
      username: _controller.userData['username'] as String?,
      ageGroup: _controller.userData['ageGroup'] as String?,
      country: _controller.userData['country'] as String?,
      categories: (_controller.userData['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _pageController.dispose();
    _progressAnimationController.dispose();
    _confettiAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleCompletion() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final profileService = serviceManager.playerProfileService;
    final onboardingService = serviceManager.onboardingSettingsService;
    final username = (_controller.userData['username'] as String?)?.trim();
    final ageGroup = _controller.userData['ageGroup'] as String?;
    final country = _controller.userData['country'] as String?;
    final categories =
    (_controller.userData['categories'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final avatar = _controller.userData['avatar'] as String?;

    if (username == null ||
        username.isEmpty ||
        ageGroup == null ||
        country == null ||
        categories == null ||
        categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all required onboarding fields or use Skip.',
            ),
          ),
        );
      }
      return;
    }

    // Save all user data
    if (username.isNotEmpty) {
      await profileService.savePlayerName(username);
    }
    await profileService.saveAgeGroup(ageGroup);
    if (country != null) {
      await profileService.saveCountry(country);
    }
    await profileService.savePreferredCategories(categories);
    if (avatar != null) {
      await profileService.saveAvatar(avatar);
    }

    // Mark onboarding complete in persistence + provider before navigating
    // so the router's redirect sees the new state immediately.
    await onboardingService.setOnboardingCompleted(true);
    await _persistProgressSnapshot(completed: true, hasCompletedProfile: true);
    await ref
        .read(onboardingProgressProvider.notifier)
        .markOnboardingCompleted(true);

    // Apply the selected age group theme for this session
    ref.read(userAgeGroupProvider.notifier).state = ageGroup;

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleSkip() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final onboardingService = serviceManager.onboardingSettingsService;

    // Mark complete so the gate doesn't redirect back on next launch.
    await onboardingService.setOnboardingCompleted(true);
    await _persistProgressSnapshot(completed: true, hasCompletedProfile: true);
    await ref
        .read(onboardingProgressProvider.notifier)
        .markOnboardingCompleted(true);

    if (mounted) {
      context.go('/home');
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
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      WelcomeStep(controller: _controller),
                      UsernameStep(controller: _controller),
                      AgeGroupStep(controller: _controller),
                      CountryStep(controller: _controller),
                      CategoriesStep(controller: _controller),
                      AvatarStep(controller: _controller),
                      CompletionStep(
                        controller: _controller,
                        onComplete: _handleCompletion,
                      ),
                    ],
                  ),

                  // Confetti overlay - only show on last step (completion)
                  if (_controller.isLastStep)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confettiAnimationController,
                          builder: (context, _) => CustomPaint(
                            painter: ConfettiPainter(_confetti),
                          ),
                        ),
                      ),
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

              // Step indicator with tooltip
              Tooltip(
                message: 'Progress through onboarding',
                child: Text(
                  'Step ${_controller.currentStep + 1} of ${_controller.totalSteps}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

          // Progress bar with glow effect
          AnimatedBuilder(
            animation: _progressAnimationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Glow effect
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressAnimationController.value,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}