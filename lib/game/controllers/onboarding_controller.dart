import 'package:flutter/material.dart';

/// Modern onboarding controller for step-by-step flow
class ModernOnboardingController extends ChangeNotifier {
  int _currentStep = 0;
  final int totalSteps;
  final Map<String, dynamic> userData = {};

  ModernOnboardingController({required this.totalSteps});

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

  /// Set a single field and notify listeners.
  void setField(String key, dynamic value) {
    userData[key] = value;
    notifyListeners();
  }

  // Typed getters for Synaptix onboarding fields
  String? get username =>
      userData['username'] is String ? userData['username'] as String : null;
  String? get ageGroup =>
      userData['ageGroup'] is String ? userData['ageGroup'] as String : null;
  String? get intent =>
      userData['intent'] is String ? userData['intent'] as String : null;
  String? get playStyle =>
      userData['playStyle'] is String ? userData['playStyle'] as String : null;
  String? get synaptixMode => userData['synaptixMode'] is String
      ? userData['synaptixMode'] as String
      : null;

  void reset() {
    _currentStep = 0;
    userData.clear();
    notifyListeners();
  }
}