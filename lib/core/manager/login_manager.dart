import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/ui_components/login/models/signup_data.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import '../../ui_components/login/providers/auth.dart';

/// LoginManager handles login, logout, onboarding, and resume state.
class LoginManager {
  final AuthService authService;
  final OnboardingSettingsService onboardingService;
  final SecureStorage secureStorage;
  final PlayerProfileService profileService;

  LoginManager({
    required this.authService,
    required this.onboardingService,
    required this.secureStorage,
    required this.profileService,
  });

  Future<void> login(String email, String password) async {
    await authService.login(email);
    await secureStorage.setLoggedIn(true);
  }

  Future<void> signup(SignupData data) async {
    final email = data.name;
    final username = data.additionalSignupData?["Username"] ?? 'Player';
    await authService.secureStorage.setUserEmail(email!);
    await profileService.savePlayerName(username);
    await profileService.saveUserRole("player");
    await profileService.saveUserRoles(["player"]);
    await secureStorage.setLoggedIn(true);
    await onboardingService.setHasCompletedOnboarding(false);
  }

  /// Logout the user and clear profile data
  Future<void> logout(BuildContext context) async {
    await authService.logout(context);
    await profileService.clearProfile();
  }

  /// Determine the next route user should see after splash
  Future<bool> isLoggedIn() async => await authService.isLoggedIn();
  Future<bool> hasCompletedOnboarding() async => await onboardingService.hasCompletedOnboarding();

  Future<String> _restorePreviousSession() async {
    final lastScreen = await secureStorage.getSecret('last_screen');
    final lastQuiz = await secureStorage.getSecret('resume_quiz_id');

    if (lastScreen != null && lastScreen.isNotEmpty) return lastScreen;
    if (lastQuiz != null && lastQuiz.isNotEmpty) {
      return '/quiz/resume?id=$lastQuiz';
    }
    return '/menu';
  }

  Future<String> getNextRoute() async {
    final loggedIn = await isLoggedIn();
    final onboarded = await hasCompletedOnboarding();

    if (!loggedIn) return '/auth';
    if (!onboarded) return '/onboarding';
    return await _restorePreviousSession();
  }
}