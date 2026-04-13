import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../states/admin_filter_state.dart';

/// Manages the state for admin filters with persistence
class AdminFilterController extends StateNotifier<AdminFilterState> {
  final Ref _ref;
  late final GeneralKeyValueStorageService _storageService;

  // Storage keys
  static const _keyVerified = 'admin_filter_verified';
  static const _keyPremium = 'admin_filter_premium';
  static const _keyBots = 'admin_filter_bots';
  static const _keyPowerUsers = 'admin_filter_power_users';
  static const _keyDeviceTypes = 'admin_filter_device_types';
  static const _keyNotification = 'admin_filter_notification';
  static const _keyDateRange = 'admin_filter_date_range';
  static const _keyMinScore = 'admin_filter_min_score';
  static const _keyMaxScore = 'admin_filter_max_score';

  AdminFilterController(this._ref) : super(AdminFilterState()) {
    _storageService = _ref.read(generalKeyValueStorageProvider);
    _loadFromStorage();
  }

  /// Load saved filter settings from storage
  Future<void> _loadFromStorage() async {
    try {
      final showVerified = await _storageService.getBool(_keyVerified) ?? false;
      final showPremium = await _storageService.getBool(_keyPremium) ?? false;
      final showBots = await _storageService.getBool(_keyBots) ?? false;
      final showPowerUsers = await _storageService.getBool(_keyPowerUsers) ?? false;
      final deviceTypes = await _storageService.getStringList(_keyDeviceTypes);
      final notificationMethod = await _storageService.getString(_keyNotification) ?? 'all';
      final dateRange = await _storageService.getString(_keyDateRange) ?? '7days';
      final minScore = await _storageService.getInt(_keyMinScore);
      final maxScore = await _storageService.getInt(_keyMaxScore);

      state = state.copyWith(
        showVerified: showVerified,
        showPremium: showPremium,
        showBots: showBots,
        showPowerUsers: showPowerUsers,
        deviceTypes: deviceTypes?.toSet() ?? {},
        notificationMethod: notificationMethod,
        dateRange: dateRange,
        minScore: minScore,
        maxScore: maxScore,
        isLoading: false,
      );
    } catch (e) {
      // If loading fails, use default state
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save current filter state to persistent storage
  Future<void> saveToStorage() async {
    try {
      await Future.wait([
        _storageService.setBool(_keyVerified, state.showVerified),
        _storageService.setBool(_keyPremium, state.showPremium),
        _storageService.setBool(_keyBots, state.showBots),
        _storageService.setBool(_keyPowerUsers, state.showPowerUsers),
        _storageService.setStringList(_keyDeviceTypes, state.deviceTypes.toList()),
        _storageService.setString(_keyNotification, state.notificationMethod),
        _storageService.setString(_keyDateRange, state.dateRange ?? '7days'),
        _storageService.setInt(_keyMinScore, state.minScore ?? 0),
        _storageService.setInt(_keyMaxScore, state.maxScore ?? 1000),
      ]);
    } catch (e) {
      // Handle save error silently or log it
      rethrow;
    }
  }

  // --- State Update Methods ---

  void setVerified(bool value) {
    state = state.copyWith(showVerified: value);
    saveToStorage();
  }

  void setPremium(bool value) {
    state = state.copyWith(showPremium: value);
    saveToStorage();
  }

  void setBots(bool value) {
    state = state.copyWith(showBots: value);
    saveToStorage();
  }

  void setPowerUsers(bool value) {
    state = state.copyWith(showPowerUsers: value);
    saveToStorage();
  }

  void toggleDeviceType(String type) {
    final newTypes = Set<String>.from(state.deviceTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    state = state.copyWith(deviceTypes: newTypes);
    saveToStorage();
  }

  void setNotificationMethod(String? value) {
    if (value != null) {
      state = state.copyWith(notificationMethod: value);
      saveToStorage();
    }
  }

  void setDateRange(String? value) {
    if (value != null) {
      state = state.copyWith(dateRange: value);
      saveToStorage();
    }
  }

  void setScoreRange(int? min, int? max) {
    state = state.copyWith(
      minScore: min,
      maxScore: max,
    );
    saveToStorage();
  }

  /// Reset all filters to default values
  void resetFilters() {
    state = AdminFilterState();
    saveToStorage();
  }

  /// Apply filters and return count of active filters
  int getActiveFilterCount() {
    int count = 0;
    if (state.showVerified) count++;
    if (state.showPremium) count++;
    if (state.showBots) count++;
    if (state.showPowerUsers) count++;
    if (state.deviceTypes.isNotEmpty) count++;
    if (state.notificationMethod != 'all') count++;
    if (state.dateRange != '7days') count++;
    return count;
  }
}
