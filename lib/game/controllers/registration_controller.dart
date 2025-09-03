import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import '../../ui_components/login/providers/auth.dart';
import '../providers/riverpod_providers.dart';

// Updated registration logic with support for player name, role, and premium flag
final registrationControllerProvider = Provider((ref) {
  final profileService = ref.read(playerProfileServiceProvider);
  final authService = ref.read(authServiceProvider);
  return RegistrationController(
    profileService: profileService,
    authService: authService,
  );
});

class RegistrationController {
  final PlayerProfileService profileService;
  final AuthService authService;

  RegistrationController({
    required this.profileService,
    required this.authService,
  });

  /// Handles full registration logic including profile setup
  Future<void> registerUser({
    required String email,
    required String name,
    String role = 'user',
    bool isPremium = false,
  }) async {
    // Save auth state
    await authService.setLoggedIn(true);
    await authService.secureStorage.setSecret('user_email', email);

    // Save profile info
    await profileService.savePlayerName(name);
    await profileService.saveUserRole(role);
    await profileService.setPremiumStatus(isPremium);
  }
}
