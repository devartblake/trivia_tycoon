import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../game/controllers/onboarding_controller.dart';
import '../../game/models/onboarding_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final OnboardingController _controller;
  final Map<String, dynamic> _userData = {}; // Store form values across steps

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(context);
  }

  /// Called when a step (form, avatar picker, etc.) submits data
  void _onUserDataChanged(Map<String, dynamic> newData) {
    setState(() {
      _userData.addAll(newData); // merge new values into existing map
    });
  }

  /// Called by the final onboarding step to save and navigate
  Future<void> _onFinalStepComplete() async {
    final serviceManager = ProviderScope.containerOf(context, listen: false).read(serviceManagerProvider);
    final profileService = serviceManager.playerProfileService;
    final onboardingService = serviceManager.onboardingSettingsService;

    // Save onboarding flag
    await onboardingService.setOnboardingCompleted();

    // Save to persistent storage
    await onboardingService.setHasCompletedOnboarding(true);
    await profileService.savePlayerName(_userData['username'] ?? 'player');
    await profileService.setPremiumStatus(_userData['isPremiumUser'] == true);
    await profileService.saveUserRole("player");
    await profileService.saveUserRoles(["player"]);
    await profileService.saveCountry(_userData['country']);
    await profileService.saveAgeGroup(_userData['ageGroup']);
    await profileService.saveAvatar(_userData['avatar']);

    final bool wantsPremium = _userData['isPremiumUser'] == true;

    if (context.mounted) {
      if (wantsPremium) {
        if (!mounted) return;
        context.go('/store');
      } else {
        if (!mounted) return;
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate steps and inject callbacks
    final steps = OnboardingStep.defaultSteps(
      controller: _controller, // ✅ inject controller
      onUserDataChanged: _onUserDataChanged,
      onFinalStepComplete: _onFinalStepComplete,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _controller.getBackgroundColor(),
        elevation: 0,
        actions: [
          if (_controller.currentIndex < steps.length - 1)
            TextButton(
              onPressed: () async {
                final onboardingService = ref.read(onboardingSettingsServiceProvider);
                await onboardingService.setHasCompletedOnboarding(true);
                if (context.mounted) context.go('/');
              },
              child: const Text("Skip", style: TextStyle(color: Colors.blue),),
            )
        ],
      ),
      body: PageView.builder(
        controller: _controller.pageController,
        itemCount: steps.length,
        onPageChanged: _controller.onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => steps[index].widget,
      ),
    );
  }
}
