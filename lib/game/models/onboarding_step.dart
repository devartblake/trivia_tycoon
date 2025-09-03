import 'package:flutter/material.dart';
import '../../screens/onboarding/widget/onboarding_avatar_step.dart';
import '../../screens/onboarding/widget/onboarding_card.dart';
import '../../screens/onboarding/widget/onboarding_form_step.dart';
import '../controllers/onboarding_controller.dart';

enum OnboardingCardColor { red, yellow, blue, green }

/// Defines a single step in the onboarding process.
/// Each step renders a widget and may have logic for data handling.
class OnboardingStep {
  final Widget widget;

  const OnboardingStep({required this.widget});

  /// Returns the list of onboarding steps.
  ///
  /// Pass in callbacks to track form data and finalize onboarding.
  static List<OnboardingStep> defaultSteps({
    required OnboardingController controller,
    required ValueChanged<Map<String, dynamic>> onUserDataChanged,
    required VoidCallback onFinalStepComplete,
    bool enableAvatarSelection = true,
    bool enableIntroCard = true,
  }) {
    final steps = <OnboardingStep>[];

    if (enableIntroCard) {
      steps.add(OnboardingStep(
        widget: OnboardingCard(
          color: OnboardingCardColor.red,
          buttonColor: Colors.deepOrange.shade100,
          title: "Welcome to Trivia Tycoon!",
          subtitle: "Get ready for the most fun trivia experience ever.",
          buttonText: "Let's Go",
          onButtonPressed: controller.nextPage,
        ),
      ));
    }

    steps.add(OnboardingStep(
      widget: OnboardingFormStep(
        onUserDataChanged: onUserDataChanged,
        onNext: controller.nextPage,
      ),
    ));

    if (enableAvatarSelection) {
      steps.add(OnboardingStep(
        widget: OnboardingAvatarStep(
          onUserDataChanged: onUserDataChanged,
          onComplete: onFinalStepComplete,
        ),
      ));
    } else {
      // If no avatar selection, call completion directly from the form step
      steps.last = OnboardingStep(
        widget: OnboardingFormStep(
          onUserDataChanged: onUserDataChanged,
          onNext: () {
            onFinalStepComplete();
          },
        ),
      );
    }

    return steps;
  }
}
