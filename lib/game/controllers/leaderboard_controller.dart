import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/game/utils/tier_assigner.dart';
import '../../admin/leaderboard/leaderboard_filter_screen.dart';
import '../../core/services/leaderboard_data_service.dart';
import '../../game/models/leaderboard_entry.dart';
import '../models/leaderboard_filter_settings.dart';

enum LeaderboardCategory { topXP, mostWins, daily, weekly, global }

class LeaderboardController extends ChangeNotifier {
  final LeaderboardDataService _dataService;
  final GeneralKeyValueStorageService _storage;
  final Ref _ref;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LeaderboardFilterSettings filterSettings = LeaderboardFilterSettings();

  List<LeaderboardEntry> _allEntries = [];
  List<LeaderboardEntry> filteredEntries = [];

  LeaderboardCategory _selectedCategory = LeaderboardCategory.topXP;
  LeaderboardCategory get selectedCategory => _selectedCategory;

  String _sortBy = 'score'; // Default sort field
  String get sortBy => _sortBy;

  LeaderboardController({
    required LeaderboardDataService dataService,
    required GeneralKeyValueStorageService storage,
    required Ref ref,
  }) : _dataService = dataService,
        _storage = storage,
       _ref = ref;

  /// Loads leaderboard data from API
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cachedJson = await _storage.getString('leaderboard_cache');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final localData = jsonDecode(cachedJson) as List<dynamic>;
        _allEntries = TierAssigner.assignTiers(localData.map((e) => LeaderboardEntry.fromJson(e)).toList());
        _applyFilters();
      }

      // Always try to update from server too
      final remote = await _dataService.loadLeaderboard();
      _allEntries = TierAssigner.assignTiers(remote);
      _applyFilters();

      // Save latest data to Hive
      await _storage.setString('leaderboard_cache', jsonEncode(remote.map((e) => e.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) print("⚠️ Error fetching leaderboard: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCategory(LeaderboardCategory category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void applySorting(String value) {
    _sortBy = value;
    _applyFilters();
    notifyListeners();
  }

  Future<void> _applyFilters() async {
    List<LeaderboardEntry> filtered = _allEntries;

    // Category filtering
    switch (_selectedCategory) {
      case LeaderboardCategory.topXP:
        // No extra filtering needed
        break;
      case LeaderboardCategory.daily:
        filtered = filtered.where((e) => e.timeframe == 'daily').toList();
        break;
      case LeaderboardCategory.weekly:
        filtered = filtered.where((e) => e.timeframe == 'weekly').toList();
        break;
      case LeaderboardCategory.global:
        filtered = filtered.where((e) => e.timeframe == 'global').toList();
        break;
      case LeaderboardCategory.mostWins:
        // Simulated logic - if you don’t have real "wins" data
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
    }

    // Advanced filters
    final filterState = _ref.read(adminFilterProvider);

    if (filterState.showVerified) {
      filtered = filtered.where((e) => e.emailVerified == true).toList();
    }
    if (filterState.showPremium) {
      filtered = filtered.where((e) => e.subscriptionStatus == 'premium').toList();
    }
    if (filterState.showBots) {
      filtered = filtered.where((e) => e.isBot == true).toList();
    }
    if (filterState.showPowerUsers) {
      filtered = filtered.where((e) => (e.powerUps?.isNotEmpty ?? false)).toList();
    }
    if (filterState.deviceTypes.isNotEmpty) {
      filtered = filtered.where((e) => filterState.deviceTypes.contains(e.lastDeviceType)).toList();
    }
    if (filterState.notificationMethod != 'all') {
      filtered = filtered.where((e) => e.preferredNotificationMethod == filterState.notificationMethod).toList();
    }

    // Sorting logic
    switch (_sortBy) {
      case 'score':
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
      case 'rank':
        filtered.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case 'last_active':
        filtered.sort((a, b) => b.lastActive.compareTo(a.lastActive),
        );
        break;
      default:
        break;
    }

    // 🧠 Tier restriction logic: Only show entries from same tier
    try {
      final userId = await _storage.getInt("currentUserId");
      final currentUser = _allEntries.firstWhere((e) => e.userId == userId);
      filtered = filtered.where((e) => e.tier == currentUser.tier).toList();
    } catch (e) {
      if (kDebugMode) print("⚠️ Tier restriction skipped (no matching user): $e");
    }

    filteredEntries = filtered;
  }

  /// Submits a score and refreshes leaderboard
  Future<void> submitScore(String playerName, int score) async {
    await _dataService.submitScore(playerName, score);
    await loadLeaderboard();
  }

  bool get isFilterActive {
    final filters = _ref.read(adminFilterProvider);
    return filters.showBots || filters.showPremium || filters.showVerified || filters.showPowerUsers ||
        filters.deviceTypes.isNotEmpty || filters.notificationMethod != 'all';
  }

  Future<void> refreshFilters({bool reloadFromStorage = false}) async {
    if (reloadFromStorage) {
      final json = await _storage.getString('leaderboard_filters');
      if (json != null) {
        final newFilter = LeaderboardFilterSettings.fromJson(jsonDecode(json));
        filterSettings = newFilter;
      }
    }

    _applyFilters();
    notifyListeners();
  }

  /// Promotes a user (example: increase level by 1)
  void promoteUser(LeaderboardEntry entry) {
    final index = _allEntries.indexOf(entry);
    if (index != -1) {
      _allEntries[index] = entry.copyWith(level: entry.level + 1);
      _applyFilters();
      notifyListeners();
    }
  }

  /// Bans a user (removes from leaderboard)
  void banUser(LeaderboardEntry entry) {
    _allEntries.remove(entry);
    _applyFilters();
    notifyListeners();
  }
}
