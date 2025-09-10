import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/xp_provider.dart';

/// ProfileService owns player XP and other profile data.
/// Implements XPService so existing controller code works with the same API.
class ProfileService {
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
        preferences = preferences ?? <String, dynamic>{};

  // ---------- Profile operations ----------
  void setDisplayName(String name) {
    displayName = name;
  }

  // ---- Additional profile data hooks (extend later as needed) ----
  void unlockCategory(String name) {
    unlockedCategories.add(name);
    debugPrint('ProfileService: unlockCategory($name)');
    // TODO: persist
  }

  bool isCategoryUnlocked(String name) => unlockedCategories.contains(name);

  void setPreference(String key, dynamic value) {
    preferences[key] = value;
  }

  T? getPreference<T>(String key) => preferences[key] as T?;

  // ---------- Game convenience ops ----------
  /// In some games timer belongs to GameSession instead;
  /// kept here as a convenience hook so existing effect code compiles.
  void increaseTimer(int seconds) {
    debugPrint('ProfileService: increaseTimer($seconds) [route to GameSession if needed]');
    // TODO: route to session if needed
  }

  void addScoreBonus(double multiplier) {
    debugPrint('ProfileService: addScoreBonus($multiplier) [route to scoring system]');
    // TODO
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
