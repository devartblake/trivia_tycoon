import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

/// Provider for checking if admin mode is enabled
final isAdminModeEnabledProvider = FutureProvider<bool>((ref) async {
  return await AppSettings.isAdminMode();
});

/// Provider for checking if current user is an admin
final isAdminUserProvider = FutureProvider<bool>((ref) async {
  return await AppSettings.isAdminUser();
});

/// Combined provider that checks both admin mode and admin user status
final adminAccessProvider = FutureProvider<bool>((ref) async {
  final isAdminModeEnabled = await ref.watch(isAdminModeEnabledProvider.future);
  final isAdminUser = await ref.watch(isAdminUserProvider.future);

  return isAdminModeEnabled && isAdminUser;
});

/// State notifier for admin-related state management
final adminStateProvider = StateNotifierProvider<AdminStateNotifier, AdminState>((ref) {
  return AdminStateNotifier(ref);
});

/// Admin state model
class AdminState {
  final bool isAdminModeEnabled;
  final bool isAdminUser;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.isAdminModeEnabled = false,
    this.isAdminUser = false,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    bool? isAdminModeEnabled,
    bool? isAdminUser,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      isAdminModeEnabled: isAdminModeEnabled ?? this.isAdminModeEnabled,
      isAdminUser: isAdminUser ?? this.isAdminUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Check if user has admin access (both mode enabled and user is admin)
  bool get hasAdminAccess => isAdminModeEnabled && isAdminUser;
}

/// Admin state notifier for managing admin-related operations
class AdminStateNotifier extends StateNotifier<AdminState> {
  final Ref ref;

  AdminStateNotifier(this.ref) : super(const AdminState()) {
    _initializeAdminState();
  }

  /// Initialize admin state by checking settings
  Future<void> _initializeAdminState() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAdminModeEnabled = await AppSettings.isAdminMode();
      final isAdminUser = await AppSettings.isAdminUser();

      state = state.copyWith(
        isAdminModeEnabled: isAdminModeEnabled,
        isAdminUser: isAdminUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh admin state (useful after settings changes)
  Future<void> refreshAdminState() async {
    await _initializeAdminState();
  }

  /// Enable admin mode (if user has permissions)
  Future<void> enableAdminMode() async {
    try {
      // Implement admin mode enabling logic
      // Note: This should only be available to authorized users
      // You might want to add additional permission checks here
      await AppSettings.setAdminMode(true);
      await refreshAdminState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Disable admin mode
  Future<void> disableAdminMode() async {
    try {
      // Implement admin mode disabling logic
      await AppSettings.setAdminMode(false);
      await refreshAdminState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(error: null);
  }
}