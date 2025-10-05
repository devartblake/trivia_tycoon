import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

import '../states/admin_filter_state.dart';

/// Manages the state for the AdminLeaderboardFilterScreen and handles
/// saving/loading the filter settings to local storage.
class AdminFilterController extends StateNotifier<AdminFilterState> {
  final Ref _ref;
  late final GeneralKeyValueStorageService _storageService;

  // Constants for storage keys to avoid magic strings and ensure consistency.
  // Storing each value separately is more robust than a single JSON blob.
  static const _keyVerified = 'admin_filter_verified';
  static const _keyPremium = 'admin_filter_premium';
  static const _keyBots = 'admin_filter_bots';
  static const _keyPowerUsers = 'admin_filter_power_users';
  static const _keyDeviceTypes = 'admin_filter_device_types';
  static const _keyNotification = 'admin_filter_notification';

  AdminFilterController(this._ref) : super(AdminFilterState()) {
    _storageService = _ref.read(generalKeyValueStorageProvider);
    // Automatically load settings when the controller is initialized.
    _loadFromStorage();
  }

  /// Asynchronously loads the saved filter settings from storage.
  Future<void> _loadFromStorage() async {
    // Read each value from storage individually.
    final showVerified = await _storageService.getBool(_keyVerified) ?? false;
    final showPremium = await _storageService.getBool(_keyPremium) ?? false;
    final showBots = await _storageService.getBool(_keyBots) ?? false;
    final showPowerUsers =
        await _storageService.getBool(_keyPowerUsers) ?? false;
    final deviceTypes =
    await _storageService.getStringList(_keyDeviceTypes);
    final notificationMethod =
        await _storageService.getString(_keyNotification) ?? 'all';

    // Update the state with the loaded values and set isLoading to false.
    state = state.copyWith(
      showVerified: showVerified,
      showPremium: showPremium,
      showBots: showBots,
      showPowerUsers: showPowerUsers,
      deviceTypes: deviceTypes?.toSet() ?? {},
      notificationMethod: notificationMethod,
      isLoading: false,
    );
  }

  /// Saves the current filter state to persistent storage.
  Future<void> saveToStorage() async {
    // Save each value to storage individually for robustness.
    await _storageService.setBool(_keyVerified, state.showVerified);
    await _storageService.setBool(_keyPremium, state.showPremium);
    await _storageService.setBool(_keyBots, state.showBots);
    await _storageService.setBool(_keyPowerUsers, state.showPowerUsers);
    await _storageService.setStringList(
        _keyDeviceTypes, state.deviceTypes.toList());
    await _storageService.setString(
        _keyNotification, state.notificationMethod);
  }

  // --- State Update Methods ---

  void setVerified(bool value) => state = state.copyWith(showVerified: value);
  void setPremium(bool value) => state = state.copyWith(showPremium: value);
  void setBots(bool value) => state = state.copyWith(showBots: value);
  void setPowerUsers(bool value) =>
      state = state.copyWith(showPowerUsers: value);

  void toggleDeviceType(String type) {
    final newTypes = Set<String>.from(state.deviceTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    state = state.copyWith(deviceTypes: newTypes);
  }

  void setNotificationMethod(String? value) {
    if (value != null) {
      state = state.copyWith(notificationMethod: value);
    }
  }
}
