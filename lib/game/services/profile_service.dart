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
  static const _branchAutoPathProgressKey = 'branchAutoPathProgress';

  final Ref ref;

  // ---- Profile-centric state ----
  String playerId;
  String displayName;
  final Set<String> unlockedCategories;
  final Map<String, dynamic> preferences;
  final Map<String, String> _branchAutoPathProgress = <String, String>{};

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
    final savedProgress = await _storage.getJson(_branchAutoPathProgressKey);
    if (savedProgress != null) {
      for (final entry in savedProgress.entries) {
        final value = entry.value;
        if (value is String &&
            value.isNotEmpty &&
            !_branchAutoPathProgress.containsKey(entry.key)) {
          _branchAutoPathProgress[entry.key] = value;
        }
      }
    }
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

  Future<String?> getBranchAutoPathNodeId(String branchId) async {
    if (branchId.isEmpty) return null;
    final cached = _branchAutoPathProgress[branchId];
    if (cached != null && cached.isNotEmpty) return cached;

    final savedProgress = await _storage.getJson(_branchAutoPathProgressKey);
    final raw = savedProgress?[branchId];
    if (raw is String && raw.isNotEmpty) {
      _branchAutoPathProgress[branchId] = raw;
      return raw;
    }
    return null;
  }

  Future<void> setBranchAutoPathNodeId(String branchId, String nodeId) async {
    if (branchId.isEmpty || nodeId.isEmpty) return;
    _branchAutoPathProgress[branchId] = nodeId;
    await _storage.setJson(
      _branchAutoPathProgressKey,
      <String, dynamic>{..._branchAutoPathProgress},
    );
  }

  Future<void> clearBranchAutoPathNodeId(String branchId) async {
    if (branchId.isEmpty) return;
    _branchAutoPathProgress.remove(branchId);
    await _storage.setJson(
      _branchAutoPathProgressKey,
      <String, dynamic>{..._branchAutoPathProgress},
    );
  }

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
    ref.read(scoreBonusMultiplierProvider.notifier).state =
        current * multiplier;
  }

  // ---------- XP convenience (delegates to XPService via composition) ----------
  int getPlayerXP() => ref.read(xpServiceProvider).playerXP;

  bool hasEnoughXP(int xpCost) =>
      ref.read(xpServiceProvider).hasEnoughXP(xpCost);

  void deductXP(int xpCost) {
    final xp = ref.read(xpServiceProvider);
    xp.deductXP(xpCost);
    ref.read(playerXPProvider.notifier).state = xp.playerXP;
  }

  void addXP(int amount, {bool applyMultiplier = true}) {
    final xp = ref.read(xpServiceProvider);
    xp.addXP(amount, applyMultiplier: applyMultiplier);
    ref.read(playerXPProvider.notifier).state = xp.playerXP;
  }

  void setXPBonusMultiplier(double multiplier) =>
      ref.read(xpServiceProvider).setBonusMultiplier(multiplier);

  void applyTemporaryXPBoost(double multiplier,
          {Duration duration = const Duration(minutes: 10)}) =>
      ref
          .read(xpServiceProvider)
          .applyTemporaryXPBoost(multiplier, duration: duration);

  @override
  String toString() => 'ProfileService(player=$playerId, name=$displayName, '
      'cats=$unlockedCategories, prefs=$preferences)';
}

// profileServiceProvider is defined in lib/game/providers/profile_service_provider.dart
