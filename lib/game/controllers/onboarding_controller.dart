import 'package:flutter/material.dart';

/// Modern onboarding controller for step-by-step flow
class OnboardingController extends ChangeNotifier {
  int _currentStep = 0;
  final int totalSteps;
  final Map<String, dynamic> userData = {};

  OnboardingController({required this.totalSteps});

  int get currentStep => _currentStep;
  double get progress => (_currentStep + 1) / totalSteps;
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void updateUserData(Map<String, dynamic> data) {
    userData.addAll(data);
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    userData.clear();
    notifyListeners();
  }
}