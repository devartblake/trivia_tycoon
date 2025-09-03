import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../models/leaderboard_filter_settings.dart';

class LeaderboardFilterNotifier extends StateNotifier<LeaderboardFilterSettings> {
  LeaderboardFilterNotifier() : super(LeaderboardFilterSettings()) {
    _loadFromStorage();
  }

  void update(LeaderboardFilterSettings newSettings) {
    state = newSettings;
    _saveToStorage(newSettings.toJson());
  }

  Future<void> _saveToStorage(Map<String, dynamic> filters) async {
    await AppSettings.setString('leaderboard_filters', jsonEncode(filters));
  }

  Future<void> _loadFromStorage() async {
    final saved = await AppSettings.getString('leaderboard_filters');
    if (saved != null) {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      state = LeaderboardFilterSettings.fromJson(json);
    }
  }

  void reset() {
    final defaultSettings = LeaderboardFilterSettings();
    update(defaultSettings);
  }
}

final leaderboardFilterProvider =
StateNotifierProvider<LeaderboardFilterNotifier, LeaderboardFilterSettings>(
      (ref) => LeaderboardFilterNotifier(),
);
