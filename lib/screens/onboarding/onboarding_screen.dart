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
import '../../game/providers/riverpod_providers.dart';
import 'dart:math' as math;

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
  final List<Confetti> _confetti = [];
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = ModernOnboardingController(totalSteps: 7); // Updated to 7 steps
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

    // Trigger confetti on completion step
    if (_controller.currentStep == 6 && !_showConfetti) {
      _triggerConfetti();
    }
  }

  void _triggerConfetti() {
    setState(() {
      _showConfetti = true;
      _confetti.clear();
      // Generate confetti particles
      for (int i = 0; i < 50; i++) {
        _confetti.add(Confetti(
          x: math.Random().nextDouble(),
          y: -0.1,
          color: _getRandomColor(),
          rotation: math.Random().nextDouble() * 2 * math.pi,
        ));
      }
    });

    // Auto-hide confetti after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[math.Random().nextInt(colors.length)];
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
      await profileService.savePreferredCategories(_controller.userData['categories']);
    }
    if (_controller.userData['avatar'] != null) {
      await profileService.saveAvatar(_controller.userData['avatar']);
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
        child: Stack(
          children: [
            Column(
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
                      AvatarStep(controller: _controller),
                      CompletionStep(
                        controller: _controller,
                        onComplete: _handleCompletion,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Confetti overlay
            if (_showConfetti)
              IgnorePointer(
                child: CustomPaint(
                  painter: ConfettiPainter(_confetti),
                  size: Size.infinite,
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