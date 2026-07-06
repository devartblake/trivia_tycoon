import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_error_messages.dart';
import '../../core/services/game_platform_auth_service.dart';
import '../../core/services/settings/profile_sync_service.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../ui_components/login/models/signup_data.dart';
import 'core_providers.dart';
import 'game_providers.dart';
import 'multi_profile_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Main auth provider - initialized by AppInit, used by router
final isLoggedInSyncProvider = StateProvider<bool>((ref) => false);

/// Whether the user has selected a profile for this session.
/// Startup sets this to true for guests and single-profile users; returning
/// full-account users with multiple profiles are routed to profile selection.
final profileSelectedProvider = StateProvider<bool>((ref) => false);

enum PlayerIdentityKind {
  unresolved,
  anonymousDevice,
  platformLinked,
  fullAccount,
}

class PlayerIdentityState {
  final bool isReady;
  final PlayerIdentityKind kind;
  final String? deviceId;
  final String? deviceType;
  final GamePlatformIdentity? platformIdentity;
  final String? error;

  const PlayerIdentityState({
    this.isReady = false,
    this.kind = PlayerIdentityKind.unresolved,
    this.deviceId,
    this.deviceType,
    this.platformIdentity,
    this.error,
  });

  bool get hasPlayableIdentity =>
      isReady && kind != PlayerIdentityKind.unresolved;

  PlayerIdentityState copyWith({
    bool? isReady,
    PlayerIdentityKind? kind,
    String? deviceId,
    String? deviceType,
    GamePlatformIdentity? platformIdentity,
    String? error,
  }) {
    return PlayerIdentityState(
      isReady: isReady ?? this.isReady,
      kind: kind ?? this.kind,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      platformIdentity: platformIdentity ?? this.platformIdentity,
      error: error,
    );
  }
}

final playerIdentityProvider =
    StateNotifierProvider<PlayerIdentityNotifier, PlayerIdentityState>((ref) {
  return PlayerIdentityNotifier(ref);
});

class PlayerIdentityNotifier extends StateNotifier<PlayerIdentityState> {
  final Ref ref;
  Future<void>? _initializing;

  PlayerIdentityNotifier(this.ref) : super(const PlayerIdentityState());

  Future<void> initialize() {
    final activeInitialization = _initializing;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initialize();
    _initializing = initialization;
    return initialization.whenComplete(() {
      if (identical(_initializing, initialization)) {
        _initializing = null;
      }
    });
  }

  Future<void> _initialize() async {
    final deviceIdService = ref.read(deviceIdServiceProvider);
    final deviceId = await deviceIdService.getOrCreate();
    final deviceType = deviceIdService.getDeviceType();
    final tokenStore = ref.read(authTokenStoreProvider);

    if (tokenStore.hasTokens()) {
      await _ensureSecureSessionForAuthRefresh(ref);
      ref.read(isLoggedInSyncProvider.notifier).state = true;
      state = PlayerIdentityState(
        isReady: true,
        kind: PlayerIdentityKind.fullAccount,
        deviceId: deviceId,
        deviceType: deviceType,
      );
      return;
    }

    final gamePlatformService = ref.read(gamePlatformAuthServiceProvider);
    final platformIdentity = await gamePlatformService.signInSilently();
    if (platformIdentity != null) {
      try {
        final session = await ref.read(authApiClientProvider).bootstrapDevice(
              platform: platformIdentity.platform,
              platformPlayerId: platformIdentity.playerId,
              displayName: platformIdentity.displayName,
            );
        if (session.hasTokens) {
          await tokenStore.save(session);
          await _ensureSecureSessionForAuthRefresh(ref);
          ref.read(isLoggedInSyncProvider.notifier).state = true;
        }
        state = PlayerIdentityState(
          isReady: true,
          kind: PlayerIdentityKind.platformLinked,
          deviceId: deviceId,
          deviceType: deviceType,
          platformIdentity: platformIdentity,
        );
        return;
      } catch (e) {
        LogManager.debug('[PlayerIdentity] Platform bootstrap skipped: $e');
      }
    }

    try {
      final session = await ref.read(authApiClientProvider).bootstrapDevice();
      if (session.hasTokens) {
        await tokenStore.save(session);
        await _ensureSecureSessionForAuthRefresh(ref);
        ref.read(isLoggedInSyncProvider.notifier).state = true;
      }
    } catch (e) {
      LogManager.debug('[PlayerIdentity] Device bootstrap skipped: $e');
    }

    state = PlayerIdentityState(
      isReady: true,
      kind: PlayerIdentityKind.anonymousDevice,
      deviceId: deviceId,
      deviceType: deviceType,
    );
  }

  void markFullAccount() {
    state = state.copyWith(
      isReady: true,
      kind: PlayerIdentityKind.fullAccount,
    );
  }
}

/// Auth operations provider for login/logout
final authOperationsProvider = Provider<AuthOperations>((ref) {
  return AuthOperations(ref);
});

/// Provides the singleton GamePlatformAuthService (Game Center / Play Games).
final gamePlatformAuthServiceProvider =
    Provider<GamePlatformAuthService>((ref) {
  return GamePlatformAuthService();
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
    ref.read(playerIdentityProvider.notifier).markFullAccount();
    await _refreshProfileSelectionGate();
  }

  /// Login user with password via backend (uses LoginManager)
  Future<void> loginWithPassword(String email, String password) async {
    try {
      final loginManager = ref.read(loginManagerProvider);
      final secureStorage = ref.read(secureStorageProvider);

      // LoginManager handles everything: tokens, device ID, profile
      await loginManager.login(email, password);
      await _ensureSecureSessionForAuthRefresh(ref);
      await _hydrateProfileFromBackend();

      // Extract and store role/premium info from response if needed
      await _updateRoleAndPremiumStatus(secureStorage);

      // Update Riverpod state
      ref.read(isLoggedInSyncProvider.notifier).state = true;
      ref.read(playerIdentityProvider.notifier).markFullAccount();
      await _refreshProfileSelectionGate();
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
      await _ensureSecureSessionForAuthRefresh(ref);
      await _hydrateProfileFromBackend();

      // Extract and store role/premium info from response if needed
      await _updateRoleAndPremiumStatus(secureStorage);

      // Update Riverpod state
      ref.read(isLoggedInSyncProvider.notifier).state = true;
      ref.read(playerIdentityProvider.notifier).markFullAccount();
      await _refreshProfileSelectionGate();
    } catch (e) {
      // Rethrow with user-friendly message
      final message = AuthErrorMessages.getSignupErrorMessage(e);
      throw Exception(message);
    }
  }

  /// Convert Map<&ltString, dynamic&gt>? to Map<&ltString, String&gt>? for SignupData
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

  Future<void> _refreshProfileSelectionGate() async {
    try {
      final profiles =
          await ref.read(multiProfileServiceProvider).getAllProfiles();
      ref.read(profileSelectedProvider.notifier).state = profiles.length <= 1;
    } catch (_) {
      ref.read(profileSelectedProvider.notifier).state = true;
    }
  }

  // -------------------------------------------------------------------------
  // Mobile game platform auth
  // -------------------------------------------------------------------------

  /// Silently attempt to sign in using the native game platform.
  ///
  /// Call this early in the app lifecycle (e.g. from the root widget or a
  /// splash screen) so the user skips the login form when Game Center /
  /// Play Games is already active on the device.
  ///
  /// Returns `true` if silent login succeeded and the user is now logged in.
  Future<bool> trySilentGameLogin() async {
    final gamePlatformService = ref.read(gamePlatformAuthServiceProvider);
    final identity = await gamePlatformService.signInSilently();
    if (identity == null) return false;

    try {
      await loginWithGamePlatform(identity);
      return true;
    } catch (e) {
      LogManager.debug('[AuthOperations] silent game login failed: $e');
      return false;
    }
  }

  /// Authenticate via a native game platform identity.
  Future<void> loginWithGamePlatform(GamePlatformIdentity identity) async {
    try {
      final backendAuthService = ref.read(coreAuthServiceProvider);
      final secureStorage = ref.read(secureStorageProvider);

      await backendAuthService.loginWithGamePlatform(identity);
      await _ensureSecureSessionForAuthRefresh(ref);
      await _hydrateProfileFromBackend();
      await _updateRoleAndPremiumStatus(secureStorage);

      ref.read(isLoggedInSyncProvider.notifier).state = true;
      ref.read(playerIdentityProvider.notifier).markFullAccount();
      await _refreshProfileSelectionGate();
    } catch (e) {
      final message = AuthErrorMessages.getLoginErrorMessage(e);
      throw Exception(message);
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

    try {
      await ref
          .read(serviceManagerProvider)
          .secureChannelService
          .clearSession();
    } catch (e) {
      LogManager.debug('[AuthOperations] Secure session clear skipped: $e');
    }

    // Update Riverpod state immediately
    ref.read(isLoggedInSyncProvider.notifier).state = false;
    ref.read(profileSelectedProvider.notifier).state = false;

    await ref.read(playerIdentityProvider.notifier).initialize();
  }
}

Future<void> _ensureSecureSessionForAuthRefresh(Ref ref) async {
  try {
    final session = ref.read(authTokenStoreProvider).load();
    if (session.accessToken.isEmpty) return;

    final secureChannel = ref.read(serviceManagerProvider).secureChannelService;
    final existing = await secureChannel.loadSession();
    if (existing != null &&
        !existing.isExpired &&
        existing.sessionId.isNotEmpty) {
      return;
    }

    await secureChannel.startSession(accessToken: session.accessToken);
  } catch (e) {
    LogManager.debug('[AuthOperations] Secure session bootstrap skipped: $e');
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
