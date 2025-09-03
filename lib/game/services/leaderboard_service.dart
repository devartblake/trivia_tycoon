import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../game/models/leaderboard_entry.dart';

class LeaderboardService {
  final ApiService apiService;

  LeaderboardService({required this.apiService});

  /// Fetches the leaderboard from the API
  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    try {
      final List<Map<String, dynamic>> response = await apiService.fetchLeaderboard();
      return response.map((data) => LeaderboardEntry.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch leaderboard: $e');
      }
      return [];
    }
  }

  /// Submits a player's score to the leaderboard
  Future<void> submitScore(String playerName, int score) async {
    try {
      await apiService.submitScore(playerName, score);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to submit score: $e');
      }
    }
  }
}
