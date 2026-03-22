import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../providers/xp_provider.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../providers/xp_provider.dart';
import '../providers/game_bonus_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';

/// ProfileService owns player XP and other profile data.
/// Implements XPService so existing controller code works with the same API.
class ProfileService {
  static const _categoriesKey = 'unlockedCategories';

  final Ref ref;

  // ---- Profile-centric state ----
  String playerId;
  String displayName;
  final Set<String> unlockedCategories;
  final Map<String, dynamic> preferences;

  ProfileService(
      this.ref, {
        required this.playerId,
        required this.displayName,
        Set<String>? unlockedCategories,
        Map<String, dynamic>? preferences,
      })  : unlockedCategories = unlockedCategories ?? <String>{},
        preferences = preferences ?? <String, dynamic>{} {
    _loadFromStorage();
  }

  GeneralKeyValueStorageService get _storage =>
      ref.read(generalKeyValueStorageProvider);

  Future<void> _loadFromStorage() async {
    final stored = await _storage.getStringList(_categoriesKey);
    if (stored != null) unlockedCategories.addAll(stored);
  }

  // ---------- Profile operations ----------
  void setDisplayName(String name) {
    displayName = name;
  }

  // ---- Additional profile data hooks (extend later as needed) ----
  void unlockCategory(String name) {
    unlockedCategories.add(name);
    LogManager.debug('ProfileService: unlockCategory($name)');
    _storage.setStringList(_categoriesKey, unlockedCategories.toList());
  }

  bool isCategoryUnlocked(String name) => unlockedCategories.contains(name);

  void setPreference(String key, dynamic value) {
    preferences[key] = value;
  }

  T? getPreference<T>(String key) => preferences[key] as T?;

  // ---------- Game convenience ops ----------
  //// Posts a timer bonus to [pendingTimerBonusProvider] so the active
  /// QuestionController can pick it up on the next timer tick.
  void increaseTimer(int seconds) {
    LogManager.debug('ProfileService: increaseTimer($seconds)');
    ref.read(pendingTimerBonusProvider.notifier).state += seconds;
  }

  void addScoreBonus(double multiplier) {
    LogManager.debug('ProfileService: addScoreBonus($multiplier)');
    final current = ref.read(scoreBonusMultiplierProvider);
    ref.read(scoreBonusMultiplierProvider.notifier).state = current * multiplier;
  }

  // ---------- XP convenience (delegates to XPService via composition) ----------
  int getPlayerXP() => ref.read(xpServiceProvider).playerXP;

  bool hasEnoughXP(int xpCost) => ref.read(xpServiceProvider).hasEnoughXP(xpCost);

  void deductXP(int xpCost) => ref.read(xpServiceProvider).deductXP(xpCost);

  void addXP(int amount, {bool applyMultiplier = true}) =>
      ref.read(xpServiceProvider).addXP(amount, applyMultiplier: applyMultiplier);

  void setXPBonusMultiplier(double multiplier) =>
      ref.read(xpServiceProvider).setBonusMultiplier(multiplier);

  void applyTemporaryXPBoost(double multiplier, {Duration duration = const Duration(minutes: 10)}) =>
      ref.read(xpServiceProvider).applyTemporaryXPBoost(multiplier, duration: duration);

  @override
  String toString() => 'ProfileService(player=$playerId, name=$displayName, '
      'cats=$unlockedCategories, prefs=$preferences)';
}

// River-pod provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  // In a real app, pull from storage/auth
  return ProfileService(ref, playerId: 'player-1', displayName: 'Player One');
});
