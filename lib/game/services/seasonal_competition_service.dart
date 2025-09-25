import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../models/seasonal_competition_model.dart';

class SeasonalCompetitionService {
  final GeneralKeyValueStorageService _storage;
  final ApiService _apiService;

  static const String _seasonEndKey = 'season_end_time';
  static const String _seasonStartKey = 'season_start_time';
  static const String _currentSeasonKey = 'current_season_id';
  static const String _playerPointsKey = 'season_points';

  SeasonalCompetitionService(this._storage, this._apiService);

  /// Get current season end time
  Future<DateTime> getSeasonEndTime() async {
    final stored = await _storage.getString(_seasonEndKey);
    if (stored != null && stored.isNotEmpty) {
      return DateTime.parse(stored);
    }

    // Default: 7 days from now if no season active
    final defaultEnd = DateTime.now().add(const Duration(days: 7));
    await _storage.setString(_seasonEndKey, defaultEnd.toIso8601String());
    return defaultEnd;
  }

  /// Get time remaining in current season
  Future<Duration> getTimeRemaining() async {
    final endTime = await getSeasonEndTime();
    final now = DateTime.now();
    final remaining = endTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if season is active
  Future<bool> isSeasonActive() async {
    final remaining = await getTimeRemaining();
    return remaining.inSeconds > 0;
  }

  /// Get current season ID
  Future<String> getCurrentSeasonId() async {
    final stored = await _storage.getString(_currentSeasonKey);
    return stored ?? 'season_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Start new season
  Future<void> startNewSeason({Duration duration = const Duration(days: 7)}) async {
    final now = DateTime.now();
    final endTime = now.add(duration);
    final seasonId = 'season_${now.millisecondsSinceEpoch}';

    await _storage.setString(_seasonStartKey, now.toIso8601String());
    await _storage.setString(_seasonEndKey, endTime.toIso8601String());
    await _storage.setString(_currentSeasonKey, seasonId);

    // Reset player points for new season
    await _storage.setInt(_playerPointsKey, 0);

    debugPrint('New season started: $seasonId, ends: $endTime');
  }

  /// End current season and process results
  Future<SeasonEndResult> endSeason() async {
    final seasonId = await getCurrentSeasonId();

    try {
      // Get final leaderboard from server
      final leaderboard = await _apiService.getSeasonLeaderboard(seasonId);

      // Process tier promotions and demotions
      final result = await _processSeasonEnd(leaderboard);

      // Start new season automatically
      await startNewSeason();

      return result;
    } catch (e) {
      debugPrint('Error ending season: $e');
      return SeasonEndResult.error(e.toString());
    }
  }

  /// Process season end logic
  Future<SeasonEndResult> _processSeasonEnd(List<SeasonPlayer> leaderboard) async {
    final promoted = <SeasonPlayer>[];
    final demoted = <SeasonPlayer>[];
    final tiebreakers = <List<SeasonPlayer>>[];

    // Find players in top 25
    final top25 = leaderboard.take(25).toList();

    // Check for ties at position 25
    if (leaderboard.length > 25) {
      final position25Points = top25.last.points;
      final tiedPlayers = leaderboard
          .where((player) => player.points == position25Points)
          .toList();

      if (tiedPlayers.length > 1) {
        tiebreakers.add(tiedPlayers);
      }
    }

    // Players below top 25 lose accumulated points
    final below25 = leaderboard.skip(25).toList();
    for (final player in below25) {
      demoted.add(player);
      // Reset their seasonal points
      await _resetPlayerSeasonPoints(player.playerId);
    }

    return SeasonEndResult(
      promoted: promoted,
      demoted: demoted,
      tiebreakers: tiebreakers,
      seasonId: await getCurrentSeasonId(),
    );
  }

  /// Reset player's seasonal points
  Future<void> _resetPlayerSeasonPoints(String playerId) async {
    // In a real implementation, this would update the player's record
    await _apiService.resetPlayerSeasonPoints(playerId);
  }

  /// Schedule tiebreaker quiz
  Future<void> scheduleTiebreaker(List<SeasonPlayer> tiedPlayers) async {
    final tiebreakerTime = DateTime.now().add(const Duration(hours: 2));

    await _apiService.scheduleTiebreakerQuiz(
      players: tiedPlayers.map((p) => p.playerId).toList(),
      scheduledTime: tiebreakerTime,
    );

    // Notify players about tiebreaker
    for (final player in tiedPlayers) {
      await _notifyPlayerOfTiebreaker(player, tiebreakerTime);
    }
  }

  /// Notify player of tiebreaker requirement
  Future<void> _notifyPlayerOfTiebreaker(SeasonPlayer player, DateTime time) async {
    // Implementation would send push notification or in-app notification
    debugPrint('Tiebreaker scheduled for ${player.playerName} at $time');
  }
}
