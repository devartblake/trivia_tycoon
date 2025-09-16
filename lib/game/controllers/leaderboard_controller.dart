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

  // Enhanced state tracking
  DateTime? _lastRefreshTime;
  DateTime? _lastCacheTime;
  bool _isPaused = false;
  Map<String, dynamic> _leaderboardStats = {};

  LeaderboardController({
    required LeaderboardDataService dataService,
    required GeneralKeyValueStorageService storage,
    required Ref ref,
  }) : _dataService = dataService,
        _storage = storage,
        _ref = ref {
    _loadLeaderboardState();
  }

  /// Load saved leaderboard state
  Future<void> _loadLeaderboardState() async {
    try {
      final lastRefreshStr = await _storage.getString('last_leaderboard_refresh');
      if (lastRefreshStr != null && lastRefreshStr.isNotEmpty) {
        _lastRefreshTime = DateTime.parse(lastRefreshStr);
      }

      final statsStr = await _storage.getString('leaderboard_stats');
      if (statsStr != null && statsStr.isNotEmpty) {
        _leaderboardStats = Map<String, dynamic>.from(jsonDecode(statsStr));
      }
    } catch (e) {
      debugPrint('Failed to load leaderboard state: $e');
    }
  }

  /// Loads leaderboard data from API
  Future<void> loadLeaderboard() async {
    if (_isPaused) return;

    _isLoading = true;
    notifyListeners();

    try {
      final cachedJson = await _storage.getString('leaderboard_cache');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final localData = jsonDecode(cachedJson) as List<dynamic>;
        _allEntries = TierAssigner.assignTiers(localData.map((e) => LeaderboardEntry.fromJson(e)).toList());
        _applyFilters();
        _lastCacheTime = DateTime.now();
      }

      // Always try to update from server too
      final remote = await _dataService.loadLeaderboard();
      _allEntries = TierAssigner.assignTiers(remote);
      _applyFilters();

      // Save latest data to Hive
      await _storage.setString('leaderboard_cache', jsonEncode(remote.map((e) => e.toJson()).toList()));

      // Update statistics
      await _updateLeaderboardStats();

      _lastRefreshTime = DateTime.now();
      await _storage.setString('last_leaderboard_refresh', _lastRefreshTime!.toIso8601String());

    } catch (e) {
      if (kDebugMode) debugPrint("⚠️ Error fetching leaderboard: $e");
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
      // Simulated logic - if you don't have real "wins" data
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
      if (kDebugMode) debugPrint("⚠️ Tier restriction skipped (no matching user): $e");
    }

    filteredEntries = filtered;
  }

  /// Submits a score and refreshes leaderboard
  Future<void> submitScore(String playerName, int score) async {
    if (_isPaused) return;

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

  /// Update leaderboard statistics
  Future<void> _updateLeaderboardStats() async {
    try {
      _leaderboardStats = {
        'totalEntries': _allEntries.length,
        'filteredEntries': filteredEntries.length,
        'lastRefresh': _lastRefreshTime?.toIso8601String(),
        'lastCache': _lastCacheTime?.toIso8601String(),
        'selectedCategory': _selectedCategory.name,
        'sortBy': _sortBy,
        'isFilterActive': isFilterActive,
      };

      await _storage.setString('leaderboard_stats', jsonEncode(_leaderboardStats));
    } catch (e) {
      debugPrint('Failed to update leaderboard stats: $e');
    }
  }

  /// LIFECYCLE METHOD: Save leaderboard state when app backgrounded
  /// Called by AppLifecycleObserver when app goes to background
  Future<void> saveLeaderboardState() async {
    try {
      // Stop any loading operations
      _isLoading = false;

      // Save current filter settings
      await _storage.setString('leaderboard_filters', jsonEncode(filterSettings.toJson()));

      // Save current state
      final stateSnapshot = {
        'selectedCategory': _selectedCategory.name,
        'sortBy': _sortBy,
        'lastRefresh': _lastRefreshTime?.toIso8601String(),
        'totalEntries': _allEntries.length,
        'filteredEntries': filteredEntries.length,
        'stats': _leaderboardStats,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _storage.setString('leaderboard_state_snapshot', jsonEncode(stateSnapshot));

      debugPrint('Leaderboard state saved successfully');
    } catch (e) {
      debugPrint('Failed to save leaderboard state: $e');
    }
  }

  /// LIFECYCLE METHOD: Refresh leaderboard data when app resumes
  /// Called by AppLifecycleObserver when app resumes from background
  Future<void> refreshLeaderboardData() async {
    try {
      // Reset loading state
      _isLoading = false;

      // Validate state integrity
      await _validateLeaderboardIntegrity();

      // Check if refresh is needed
      if (await _needsRefresh()) {
        await loadLeaderboard();
      }

      // Resume normal operations
      _isPaused = false;

      debugPrint('Leaderboard data refresh completed');
    } catch (e) {
      debugPrint('Leaderboard data refresh failed: $e');
      await _resetLeaderboardState();
    }
  }

  /// Check if leaderboard needs refresh
  Future<bool> _needsRefresh() async {
    if (_lastRefreshTime == null) return true;

    final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceRefresh > const Duration(minutes: 15);
  }

  /// Validate leaderboard integrity
  Future<void> _validateLeaderboardIntegrity() async {
    try {
      bool needsRepair = false;

      // Validate entries list
      if (_allEntries.isEmpty) {
        // Try to load from cache
        final cachedJson = await _storage.getString('leaderboard_cache');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final localData = jsonDecode(cachedJson) as List<dynamic>;
          _allEntries = TierAssigner.assignTiers(localData.map((e) => LeaderboardEntry.fromJson(e)).toList());
          needsRepair = true;
        }
      }

      // Validate filter settings
      if (_selectedCategory == null) {
        _selectedCategory = LeaderboardCategory.topXP;
        needsRepair = true;
      }

      // Validate sort field
      if (_sortBy.isEmpty) {
        _sortBy = 'score';
        needsRepair = true;
      }

      if (needsRepair) {
        await _applyFilters();
        await _updateLeaderboardStats();
        debugPrint('Leaderboard integrity restored');
      }
    } catch (e) {
      debugPrint('Failed to validate leaderboard integrity: $e');
    }
  }

  /// Reset leaderboard state
  Future<void> _resetLeaderboardState() async {
    try {
      _allEntries.clear();
      filteredEntries.clear();
      _selectedCategory = LeaderboardCategory.topXP;
      _sortBy = 'score';
      _isLoading = false;
      _lastRefreshTime = null;
      _lastCacheTime = null;
      _leaderboardStats.clear();

      await _storage.remove('leaderboard_cache');
      await _storage.remove('leaderboard_filters');
      await _storage.remove('leaderboard_stats');
      await _storage.remove('last_leaderboard_refresh');

      debugPrint('Leaderboard state reset to defaults');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset leaderboard state: $e');
    }
  }

  /// Pause leaderboard operations
  void pauseLeaderboard() {
    _isPaused = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Resume leaderboard operations
  void resumeLeaderboard() {
    _isPaused = false;
  }

  /// Get leaderboard statistics
  Map<String, dynamic> getLeaderboardStats() {
    return {
      ..._leaderboardStats,
      'isPaused': _isPaused,
      'isLoading': _isLoading,
    };
  }

  /// Export leaderboard data for backup
  Map<String, dynamic> exportLeaderboardData() {
    return {
      'allEntries': _allEntries.map((e) => e.toJson()).toList(),
      'filterSettings': filterSettings.toJson(),
      'selectedCategory': _selectedCategory.name,
      'sortBy': _sortBy,
      'stats': _leaderboardStats,
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import leaderboard data from backup
  Future<void> importLeaderboardData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('allEntries')) {
        _allEntries = (data['allEntries'] as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList();
      }

      if (data.containsKey('filterSettings')) {
        filterSettings = LeaderboardFilterSettings.fromJson(data['filterSettings']);
      }

      if (data.containsKey('selectedCategory')) {
        _selectedCategory = LeaderboardCategory.values.firstWhere(
              (cat) => cat.name == data['selectedCategory'],
          orElse: () => LeaderboardCategory.topXP,
        );
      }

      if (data.containsKey('sortBy')) {
        _sortBy = data['sortBy'];
      }

      await _applyFilters();
      await _updateLeaderboardStats();
      notifyListeners();

      debugPrint('Leaderboard data imported successfully');
    } catch (e) {
      debugPrint('Failed to import leaderboard data: $e');
      rethrow;
    }
  }

  /// Force refresh leaderboard
  Future<void> forceRefresh() async {
    await loadLeaderboard();
  }

  /// Clear all leaderboard data
  Future<void> clearAllLeaderboardData() async {
    await _resetLeaderboardState();
  }
}
