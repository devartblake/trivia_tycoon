import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage/secure_storage.dart';
import '../providers/riverpod_providers.dart';
import 'onboarding_providers.dart';

/// Main auth provider - initialized by AppInit, used by router
final isLoggedInSyncProvider = StateProvider<bool>((ref) => false);

/// Auth operations provider for login/logout
final authOperationsProvider = Provider<AuthOperations>((ref) {
  return AuthOperations(ref);
});

class AuthOperations {
  final Ref ref;

  AuthOperations(this.ref);

  /// Login user and update state
  Future<void> login(String email) async {
    final authService = ref.read(authServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);

    // Perform login through services
    await authService.login(email);
    await secureStorage.setLoggedIn(true);

    // Update River-pod state immediately
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  }

  /// Login user with password via backend API
  Future<Map<String, dynamic>> loginWithPassword(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.login(email: email, password: password);
    final roles = _extractRoles(response);
    final isPremium = response['isPremium'] == true;
    final userId = response['userId']?.toString() ?? 'guest';

    await authService.login(
      email,
      userId: userId,
      isPremiumUser: isPremium,
      roles: roles,
    );
    await secureStorage.setLoggedIn(true);
    await _persistAuthTokenIfPresent(response, secureStorage);

    ref.read(isLoggedInSyncProvider.notifier).state = true;
    return response;
  }

  /// Signup user via backend API
  Future<Map<String, dynamic>> signup(
      String email,
      String password, {
        Map<String, dynamic>? extra,
      }) async {
    final authService = ref.read(authServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.signup(
      email: email,
      password: password,
      extra: extra,
    );
    final roles = _extractRoles(response);
    final isPremium = response['isPremium'] == true;
    final userId = response['userId']?.toString() ?? 'guest';

    await authService.login(
      email,
      userId: userId,
      isPremiumUser: isPremium,
      roles: roles,
    );
    await secureStorage.setLoggedIn(true);
    await _persistAuthTokenIfPresent(response, secureStorage);

    ref.read(isLoggedInSyncProvider.notifier).state = true;
    return response;
  }

  List<String> _extractRoles(Map<String, dynamic> response) {
    final roles = response['roles'];
    if (roles is List) {
      return roles.map((role) => role.toString()).toList();
    }
    final role = response['role'];
    if (role != null) {
      return [role.toString()];
    }
    return const ['player'];
  }

  Future<void> _persistAuthTokenIfPresent(
      Map<String, dynamic> response,
      SecureStorage secureStorage,
      ) async {
    final token = response['token'];
    if (token is String && token.isNotEmpty) {
      await secureStorage.setSecret('auth_token', token);
    }
  }

  /// Logout user and clear state
  Future<void> logout([BuildContext? context]) async {
    final authService = ref.read(authServiceProvider);

    try {
      // Your AuthService.logout requires BuildContext and handles navigation internally
      if (context != null) {
        await authService.logout(context);
      } else {
        // If no context provided, manually clear the storage without navigation
        await authService.generalKey.setBool('isLoggedIn', false);
        await authService.secureStorage.removeSecret('user_email');
        await authService.playerProfileService.clearProfile();
      }
    } catch (e) {
      debugPrint('Logout failed: $e');
      // Continue with cleanup even if logout service call fails
    }

    // Update River-pod state immediately
    ref.read(isLoggedInSyncProvider.notifier).state = false;

    // Also clear onboarding state
    ref.read(hasSeenIntroProvider.notifier).state = false;
    ref.read(hasCompletedProfileProvider.notifier).state = false;
  }
}

/// Legacy providers for backward compatibility if needed
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final String? userEmail;
  final String? userRole;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userEmail,
    this.userRole,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? userRole,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
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

  Future<void> signup(String email, String password, Map<String, dynamic> additionalData) async {
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
}
