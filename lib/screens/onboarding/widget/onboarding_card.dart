import 'package:flutter/material.dart';
import '../../../game/models/onboarding_step.dart';

class OnboardingCard extends StatelessWidget {
  final OnboardingCardColor color;
  final Color buttonColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const OnboardingCard({
    super.key,
    required this.color,
    required this.subtitle,
    required this.buttonColor,
    this.title = "",
    this.buttonText = "Get Started",
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(color),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const Spacer(flex: 2),
          ElevatedButton(
            onPressed: onButtonPressed ?? () => Navigator.of(context).maybePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(OnboardingCardColor color) {
    switch (color) {
      case OnboardingCardColor.red:
        return Colors.redAccent;
      case OnboardingCardColor.yellow:
        return Colors.amber;
      case OnboardingCardColor.blue:
        return Colors.lightBlueAccent;
      case OnboardingCardColor.green:
        return Colors.green;
    }
  }
}
