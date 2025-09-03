import 'package:flutter/material.dart';
import '../../../game/models/onboarding_step.dart';
import 'onboarding_avatar_step.dart';
import 'onboarding_card.dart';
import 'onboarding_form_step.dart';

class OnboardingStep {
  final Widget Function(BuildContext) builder;

  OnboardingStep({required this.builder});

  static List<OnboardingStep> defaultSteps({
    required ValueChanged<Map<String, dynamic>> onUserDataChanged,
    required VoidCallback onFinalStepComplete,
  }) {
    return [
      OnboardingStep(
        builder: (_) => const OnboardingCard(
          title: "Welcome!",
          subtitle: "Let's get you started with Trivia Tycoon.",
          buttonText: "Next",
          color: OnboardingCardColor.red,
          buttonColor: Colors.orange,
        ),
      ),
      OnboardingStep(
        builder: (_) => OnboardingFormStep(
          onUserDataChanged: onUserDataChanged,
          onNext: () {},
        ),
      ),
      OnboardingStep(
        builder: (_) => OnboardingAvatarStep(
          onUserDataChanged: onUserDataChanged,
          onComplete: onFinalStepComplete,
        ),
      ),
    ];
  }
}
