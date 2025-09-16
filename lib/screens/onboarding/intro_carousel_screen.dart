import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_router.dart';
import '../../game/providers/onboarding_providers.dart';

/// Create this file: lib/screens/onboarding/intro_carousel_screen.dart
/// Intro carousel screen with smooth page transitions
class IntroCarouselScreen extends ConsumerStatefulWidget {
  const IntroCarouselScreen({super.key});

  @override
  ConsumerState<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends ConsumerState<IntroCarouselScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _buttonAnimationController;
  int _currentPage = 0;

  final List<IntroPage> _pages = [
    IntroPage(
      icon: Icons.quiz,
      title: 'Welcome to Trivia Tycoon',
      description: 'Test your knowledge with challenging questions and climb the ranks to become the ultimate trivia champion.',
      color: Colors.deepPurple,
    ),
    IntroPage(
      icon: Icons.psychology,
      title: 'Skill Trees & Growth',
      description: 'Develop your expertise across different categories. Unlock new abilities and power-ups as you progress.',
      color: Colors.indigo,
    ),
    IntroPage(
      icon: Icons.leaderboard,
      title: 'Compete & Conquer',
      description: 'Join seasonal competitions, earn rewards, and see how you stack up against players worldwide.',
      color: Colors.blue,
    ),
    IntroPage(
      icon: Icons.emoji_events,
      title: 'Ready to Begin?',
      description: 'Your journey to trivia mastery starts now. Let\'s set up your profile and dive in!',
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  void _completeIntro() {
    debugPrint('Completing intro...');

    // Update the provider state
    ref.read(hasSeenIntroProvider.notifier).state = true;

    debugPrint('Updated hasSeenIntro: ${ref.read(hasSeenIntroProvider)}');
    debugPrint('Current onboarding phase: ${ref.read(onboardingPhaseProvider)}');

    // Use pushReplacement to bypass redirect logic entirely
    context.pushReplacement('/profile-setup');
  }

  void _skipIntro() {
    debugPrint('Skipping intro...');

    // Update the provider state
    ref.read(hasSeenIntroProvider.notifier).state = true;

    debugPrint('Updated hasSeenIntro: ${ref.read(hasSeenIntroProvider)}');

    // Use pushReplacement to bypass redirect logic entirely
    context.pushReplacement('/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _pages[_currentPage].color.withOpacity(0.1),
              _pages[_currentPage].color.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipIntro,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _pages[_currentPage].color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });

                    if (index == _pages.length - 1) {
                      _buttonAnimationController.forward();
                    } else {
                      _buttonAnimationController.reverse();
                    }
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicators
              _buildPageIndicators(),

              const SizedBox(height: 32),

              // Navigation buttons
              _buildNavigationButtons(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(IntroPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animation
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: page.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    page.icon,
                    size: 60,
                    color: page.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _pages[_currentPage].color
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous/Back button
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox(width: 80),

          // Next/Get Started button
          AnimatedBuilder(
            animation: _buttonAnimationController,
            builder: (context, child) {
              final isLastPage = _currentPage == _pages.length - 1;
              return ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages[_currentPage].color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Model for intro page data
class IntroPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const IntroPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
