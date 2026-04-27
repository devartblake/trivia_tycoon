import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_error_messages.dart';
import '../../core/services/settings/profile_sync_service.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../ui_components/login/models/signup_data.dart';
import 'core_providers.dart';
import 'game_providers.dart';
import 'onboarding_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Main auth provider - initialized by AppInit, used by router
final isLoggedInSyncProvider = StateProvider<bool>((ref) => false);

/// Whether the user has selected a profile this process lifetime.
/// Intentionally NOT persisted — resets to false on every cold start / crash,
/// so the profile-selection gate always appears when the app relaunches.
final profileSelectedProvider = StateProvider<bool>((ref) => false);

/// Auth operations provider for login/logout
final authOperationsProvider = Provider<AuthOperations>((ref) {
  return AuthOperations(ref);
});

class AuthOperations {
  final Ref ref;

  AuthOperations(this.ref);

  /// Login user and update state (legacy local-only mode)
  Future<void> login(String email) async {
    final authService = ref.read(authServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);

    // FIX: legacy AuthService.login takes a single positional String argument,
    // not the named email:/password: params that belong to BackendAuthService.
    await authService.login(email);
    await secureStorage.setLoggedIn(true);

    // Update Riverpod state immediately
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  }

  /// Login user with password via backend (uses LoginManager)
  Future<void> loginWithPassword(String email, String password) async {
    try {
      final loginManager = ref.read(loginManagerProvider);
      final secureStorage = ref.read(secureStorageProvider);

      // LoginManager handles everything: tokens, device ID, profile
      await loginManager.login(email, password);
      await _hydrateProfileFromBackend();

      // Extract and store role/premium info from response if needed
      await _updateRoleAndPremiumStatus(secureStorage);

      // Update Riverpod state
      ref.read(isLoggedInSyncProvider.notifier).state = true;
    } catch (e) {
      // Rethrow with user-friendly message
      final message = AuthErrorMessages.getLoginErrorMessage(e);
      throw Exception(message);
    }
  }

  /// Signup user via backend (uses LoginManager)
  Future<void> signup(
    String email,
    String password, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final loginManager = ref.read(loginManagerProvider);
      final secureStorage = ref.read(secureStorageProvider);

      // Build SignupData using the correct named constructor
      final signupData = SignupData.fromSignupForm(
        name: email,
        password: password,
        additionalSignupData: _convertToStringMap(extra),
      );

      // LoginManager handles everything: tokens, device ID, profile
      await loginManager.signup(signupData);
      await _hydrateProfileFromBackend();

      // Extract and store role/premium info from response if needed
      await _updateRoleAndPremiumStatus(secureStorage);

      // Update Riverpod state
      ref.read(isLoggedInSyncProvider.notifier).state = true;
    } catch (e) {
      // Rethrow with user-friendly message
      final message = AuthErrorMessages.getSignupErrorMessage(e);
      throw Exception(message);
    }
  }

  /// Convert Map<String, dynamic>? to Map<String, String>? for SignupData
  Map<String, String>? _convertToStringMap(Map<String, dynamic>? input) {
    if (input == null) return null;
    return input.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Update role and premium status from stored user data
  /// This reads from the profile service which was updated by LoginManager
  Future<void> _updateRoleAndPremiumStatus(SecureStorage secureStorage) async {
    try {
      final profileService = ref.read(playerProfileServiceProvider);

      // Get role from profile (set by LoginManager)
      final role = await profileService.getUserRole();
      if (role != null && role.isNotEmpty) {
        await secureStorage.setSecret('user_role', role);
      } else {
        // Default to 'player' if no role specified
        await secureStorage.setSecret('user_role', 'player');
      }

      // Get premium status from profile
      final isPremium = await profileService.isPremiumUser();
      await secureStorage.setSecret('is_premium', isPremium.toString());
    } catch (e) {
      LogManager.debug('[AuthOperations] Error updating role/premium: $e');
      // Set defaults on error
      await secureStorage.setSecret('user_role', 'player');
      await secureStorage.setSecret('is_premium', 'false');
    }
  }

  Future<void> _hydrateProfileFromBackend() async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final profileSyncService = ProfileSyncService(
        apiService: serviceManager.apiService,
        trackEvent: serviceManager.analyticsService.trackEvent,
      );

      final remoteProfile = await profileSyncService.fetchRemoteProfile();
      if (remoteProfile != null && remoteProfile.isNotEmpty) {
        await serviceManager.playerProfileService
            .saveProfileBatch(remoteProfile);
      }
    } catch (e) {
      LogManager.debug('[AuthOperations] Remote profile hydrate skipped: $e');
    }
  }

  /// Logout user and clear state
  Future<void> logout([BuildContext? context]) async {
    final loginManager = ref.read(loginManagerProvider);

    try {
      // LoginManager handles backend logout + clearing tokens
      if (context != null) {
        await loginManager.logout(context);
      } else {
        // If no context, still clear storage
        final secureStorage = ref.read(secureStorageProvider);
        await secureStorage.setLoggedIn(false);
        await secureStorage.removeSecret('user_email');
        await secureStorage.removeSecret('user_role');
        await secureStorage.removeSecret('is_premium');

        final profileService = ref.read(playerProfileServiceProvider);
        await profileService.clearProfile();
      }
    } catch (e) {
      LogManager.debug('Logout failed: $e');
    }

    // Update Riverpod state immediately
    ref.read(isLoggedInSyncProvider.notifier).state = false;
    ref.read(profileSelectedProvider.notifier).state = false;

    // Also clear onboarding state
    await ref.read(onboardingProgressProvider.notifier).reset();
  }
}

/// Legacy providers for backward compatibility if needed
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final String? userEmail;
  final String? userRole;
  final bool isPremium;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userEmail,
    this.userRole,
    this.isPremium = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? userRole,
    bool? isPremium,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isLoggedIn: true,
        userEmail: email,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signup(String email, String password,
      Map<String, dynamic> additionalData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isLoggedIn: true,
        userEmail: email,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setRole(String role) {
    state = state.copyWith(userRole: role);
  }

  void setPremiumStatus(bool isPremium) {
    state = state.copyWith(isPremium: isPremium);
  }
}
