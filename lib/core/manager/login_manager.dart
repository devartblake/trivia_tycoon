import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/auth_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/ui_components/login/models/signup_data.dart';
import '../services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// LoginManager handles login, logout, onboarding, and resume state.
///
/// ENHANCED with role and premium status handling:
/// - Properly extracts user roles from backend response
/// - Differentiates between regular and premium players
/// - Stores role information for access control
class LoginManager {
  final BackendAuthService authService;
  final AuthTokenStore tokenStore;
  final DeviceIdService deviceIdService;
  final OnboardingSettingsService onboardingService;
  final SecureStorage secureStorage;
  final PlayerProfileService profileService;

  LoginManager({
    required this.authService,
    required this.tokenStore,
    required this.deviceIdService,
    required this.onboardingService,
    required this.secureStorage,
    required this.profileService,
  });

  Future<void> login(String email, String password) async {
    if (ConfigService.useBackendAuth) {
      // Use core AuthService which properly stores tokens
      final session = await authService.login(
        email: email,
        password: password,
      );

      // Tokens are already saved in AuthTokenStore by authService.login()
      // Extract and apply user metadata (role, premium status, etc.)
      await _applyBackendSession(email, session);
      return;
    }

    // Legacy local-only login (when backend is disabled)
    await _legacyLogin(email);
  }

  Future<void> signup(SignupData data) async {
    final email = data.name!;
    final username = data.additionalSignupData?["Username"] ??
        data.additionalSignupData?["username"] ??
        email.split('@').first;
    final country = data.additionalSignupData?["Country"] ??
        data.additionalSignupData?["country"];

    if (ConfigService.useBackendAuth) {
      // Use core AuthService which properly stores tokens
      final session = await authService.signup(
        email: email,
        password: data.password ?? '',
        username: username,
        country: country,
      );

      // Tokens are already saved in AuthTokenStore by authService.signup()
      // Extract and apply user metadata
      await _applyBackendSession(email, session);
      await onboardingService.setHasCompletedOnboarding(false);
      return;
    }

    // Legacy local-only signup (when backend is disabled)
    await _legacySignup(email, username);
  }

  /// Logout the user and clear all profile data
  Future<void> logout(BuildContext context) async {
    if (ConfigService.useBackendAuth) {
      // Backend logout - revokes refresh token and clears local storage
      await authService.logout();
    } else {
      // Legacy local logout
      await secureStorage.setLoggedIn(false);
      await secureStorage.removeSecret('user_email');
    }

    // Clear role and premium data
    await secureStorage.removeSecret('user_role');
    await secureStorage.removeSecret('is_premium');

    // Always clear profile regardless of backend mode
    await profileService.clearProfile();

    // Navigate to login if context is still mounted
    if (context.mounted) {
      context.go('/login');
    }
  }

  /// Apply backend session to local state
  /// This extracts role, premium status, and other user metadata from the session
  Future<void> _applyBackendSession(
    String email,
    AuthSession session,
  ) async {
    // Mark as logged in
    await secureStorage.setLoggedIn(true);

    // Save email for profile
    await secureStorage.setSecret('user_email', email);

    // Extract username from email if not provided
    final username = email.split('@')[0];
    await profileService.savePlayerName(username);
    await profileService.saveUsername(username.toLowerCase());

    // Save user ID if available
    if (session.userId != null && session.userId!.isNotEmpty) {
      await secureStorage.setSecret('user_id', session.userId!);
      await profileService.saveUserId(session.userId!);
    }

    // Extract and store user role from session metadata
    await _extractAndStoreRole(session);

    // Extract and store premium status
    await _extractAndStorePremiumStatus(session);
  }

  /// Extract role from session metadata and store it
  /// Supports multiple role formats from backend
  Future<void> _extractAndStoreRole(AuthSession session) async {
    String role = 'player'; // Default role

    // Check if session has metadata with role information
    if (session.metadata != null) {
      final metadata = session.metadata!;

      // Check for 'role' field (single role)
      if (metadata.containsKey('role') && metadata['role'] != null) {
        role = metadata['role'].toString();
      }

      // Check for 'roles' field (multiple roles - take first)
      else if (metadata.containsKey('roles') && metadata['roles'] is List) {
        final roles = metadata['roles'] as List;
        if (roles.isNotEmpty) {
          role = roles.first.toString();
        }
      }

      // Check for 'tier' field (tier-based roles)
      else if (metadata.containsKey('tier') && metadata['tier'] != null) {
        final tier = metadata['tier'].toString().toLowerCase();
        // Map tier to role
        role = _mapTierToRole(tier);
      }

      // Store all roles if multiple exist
      if (metadata.containsKey('roles') && metadata['roles'] is List) {
        final roles =
            (metadata['roles'] as List).map((r) => r.toString()).toList();
        await profileService.saveUserRoles(roles);
      }
    }

    // Save primary role
    await profileService.saveUserRole(role);
    await secureStorage.setSecret('user_role', role);

    LogManager.debug('[LoginManager] User role set to: $role');
  }

  /// Extract premium status from session metadata
  Future<void> _extractAndStorePremiumStatus(AuthSession session) async {
    bool isPremium = false;

    if (session.metadata != null) {
      final metadata = session.metadata!;

      // Check various possible premium status fields
      if (metadata.containsKey('isPremium')) {
        isPremium = metadata['isPremium'] == true;
      } else if (metadata.containsKey('is_premium')) {
        isPremium = metadata['is_premium'] == true;
      } else if (metadata.containsKey('premium')) {
        isPremium = metadata['premium'] == true;
      } else if (metadata.containsKey('subscriptionStatus')) {
        final status = metadata['subscriptionStatus'].toString().toLowerCase();
        isPremium = status == 'active' || status == 'premium';
      } else if (metadata.containsKey('tier')) {
        // Check if tier indicates premium
        final tier = metadata['tier'].toString().toLowerCase();
        isPremium = _isPremiumTier(tier);
      }
    }

    // Save premium status
    await profileService.setPremiumStatus(isPremium);
    await secureStorage.setSecret('is_premium', isPremium.toString());

    LogManager.debug('[LoginManager] Premium status set to: $isPremium');
  }

  /// Map backend tier to role
  String _mapTierToRole(String tier) {
    switch (tier.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return 'admin';
      case 'moderator':
      case 'mod':
        return 'moderator';
      case 'premium':
      case 'pro':
      case 'vip':
        return 'player'; // Premium is a status, not a role
      case 'free':
      case 'basic':
      case 'player':
      default:
        return 'player';
    }
  }

  /// Check if a tier indicates premium status
  bool _isPremiumTier(String tier) {
    final premiumTiers = ['premium', 'pro', 'vip', 'gold', 'platinum'];
    return premiumTiers.contains(tier.toLowerCase());
  }

  /// Legacy local-only login (no backend)
  Future<void> _legacyLogin(String email) async {
    await secureStorage.setSecret('user_email', email);
    await secureStorage.setLoggedIn(true);
  }

  /// Legacy local-only signup (no backend)
  Future<void> _legacySignup(String email, String username) async {
    await secureStorage.setSecret('user_email', email);
    await profileService.savePlayerName(username);
    await profileService.saveUsername(username.toLowerCase());
    await profileService.saveUserRole("player");
    await profileService.saveUserRoles(["player"]);
    await secureStorage.setLoggedIn(true);
    await onboardingService.setHasCompletedOnboarding(false);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    if (ConfigService.useBackendAuth) {
      // Check if we have valid tokens in storage
      final session = tokenStore.load();
      return session.hasTokens;
    }

    // Legacy check
    return await secureStorage.isLoggedIn();
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return await onboardingService.hasCompletedOnboarding();
  }

  /// Restore the user's previous session (last screen they were on)
  Future<String> _restorePreviousSession() async {
    final lastScreen = await secureStorage.getSecret('last_screen');
    final lastQuiz = await secureStorage.getSecret('resume_quiz_id');

    if (lastScreen != null && lastScreen.isNotEmpty) return lastScreen;
    if (lastQuiz != null && lastQuiz.isNotEmpty) {
      return '/quiz/resume?id=$lastQuiz';
    }
    return '/home';
  }

  /// Determine the next route user should see after splash
  Future<String> getNextRoute() async {
    final loggedIn = await isLoggedIn();
    final onboarded = await hasCompletedOnboarding();

    if (!loggedIn) return '/login';
    if (!onboarded) return '/onboarding';
    return await _restorePreviousSession();
  }

  /// Check if current user is premium
  Future<bool> isPremiumUser() async {
    if (ConfigService.useBackendAuth) {
      return await profileService.isPremiumUser();
    }

    final premiumStr = await secureStorage.getSecret('is_premium');
    return premiumStr == 'true';
  }

  /// Check if current user has admin role
  Future<bool> isAdminUser() async {
    final role = await profileService.getUserRole();
    return role == 'admin';
  }

  /// Get current user's role
  Future<String?> getUserRole() async {
    return await profileService.getUserRole();
  }
}
