import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class OnboardingController extends ChangeNotifier {
  final PageController pageController = PageController();
  final BuildContext context;

  int currentIndex = 0;
  bool hasCompletedOnboarding = false;
  late Box settingsBox;

  // Form fields
  String name = '';
  String username = '';
  String country = '';
  String ageGroup = '';
  String selectedAvatar = '';

  OnboardingController(this.context) {
    _init();
  }

  /// Initialize Hive storage and check onboarding state
  Future<void> _init() async {
    settingsBox = await Hive.openBox('settings');
    hasCompletedOnboarding = settingsBox.get('onboarding_seen', defaultValue: false);

    if (hasCompletedOnboarding) {
      _navigateToMainMenu();
    }
  }

  Future<bool> shouldEnableAvatar() async {
    final configBox = await Hive.openBox('config');
    return configBox.get('enableAvatars', defaultValue: true);
  }

  // Update individual user fields
  void updateField(String key, String value) {
    switch (key) {
      case 'name':
        name = value;
        break;
      case 'username':
        username = value;
        break;
      case 'country':
        country = value;
        break;
      case 'ageGroup':
        ageGroup = value;
        break;
      case 'avatar':
        selectedAvatar = value;
        break;
    }
    notifyListeners();
  }

  Map<String, String> getCollectedData() {
    return {
      'name': name,
      'username': username,
      'country': country,
      'ageGroup': ageGroup,
      'avatar': selectedAvatar,
    };
  }

  bool validateStep(int step) {
    switch (step) {
      case 1:
        return username.isNotEmpty && ageGroup.isNotEmpty && country.isNotEmpty;
      case 2:
        return selectedAvatar.isNotEmpty;
      default:
        return true;
    }
  }

  void completeOnboarding() {
    settingsBox.put('onboarding_seen', true);
    hasCompletedOnboarding = true;
    notifyListeners();
    _navigateToMainMenu();
  }

  void nextPage() {
    if (currentIndex < 3) {
      currentIndex++;
      pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      notifyListeners();
    } else {
      completeOnboarding();
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      currentIndex--;
      pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      notifyListeners();
    }
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void skipOnboarding() {
    settingsBox.put('onboarding_seen', true);
    hasCompletedOnboarding = true;
    notifyListeners();
    _navigateToMainMenu();
  }

  void _navigateToMainMenu() {
    context.go('/');
  }

  Color getBackgroundColor() {
    switch (currentIndex) {
      case 0:
        return Colors.redAccent;
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.greenAccent;
      default:
        return Colors.white;
    }
  }
}
