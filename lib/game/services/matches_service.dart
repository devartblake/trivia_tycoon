import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../core/services/matches_api_client.dart';

class MatchesService {
  final MatchesApiClient _apiClient;

  MatchesService(this._apiClient);

  /// Starts a new match (multiplayer or singleplayer).
  Future<MatchStartResponse> startMatch({
    String? opponentId,
    String? gameMode,
  }) {
    return _apiClient.startMatch(opponentId: opponentId, gameMode: gameMode);
  }

  /// Submits match results and claims rewards.
  Future<MatchSubmitResponse> submitMatch({
    required String matchId,
    required int playerScore,
    int? opponentScore,
    required List<String> answeredQuestionIds,
    DateTime? completedAtUtc,
  }) {
    return _apiClient.submitMatch(
      matchId: matchId,
      playerScore: playerScore,
      opponentScore: opponentScore,
      answeredQuestionIds: answeredQuestionIds,
      completedAtUtc: completedAtUtc,
    );
  }

  /// Gets active (ongoing) matches for the current player.
  Future<List<Map<String, dynamic>>> getActiveMatches() async {
    final response = await _apiClient.listMatches(status: 'ongoing');
    return response.matches
        .map((m) => {
          'id': m.matchId,
          'matchId': m.matchId,
          'opponentId': m.opponentId,
          'opponentName': m.opponentName ?? 'Unknown',
          'playerScore': m.playerScore,
          'opponentScore': m.opponentScore ?? 0,
          'gameMode': m.gameMode,
          'status': m.status,
          'result': m.result,
          'createdAt': m.createdAtUtc.toIso8601String(),
        })
        .toList();
  }

  /// Gets details for a specific match.
  Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final match = await _apiClient.getMatchDetails(matchId);
    return {
      'matchId': match.matchId,
      'playerId': match.playerId,
      'opponentId': match.opponentId,
      'opponentName': match.opponentName,
      'playerScore': match.playerScore,
      'opponentScore': match.opponentScore,
      'gameMode': match.gameMode,
      'status': match.status,
      'result': match.result,
      'createdAt': match.createdAtUtc.toIso8601String(),
      'completedAt': match.completedAtUtc?.toIso8601String(),
      'rewardCoins': match.rewardCoins,
    };
  }

  /// Submits match results (updates score).
  Future<void> updateMatchScore(
    String matchId,
    int playerScore,
    int opponentScore,
  ) {
    return submitMatch(
      matchId: matchId,
      playerScore: playerScore,
      opponentScore: opponentScore,
      answeredQuestionIds: [],
    );
  }

  /// Abandons an ongoing match.
  Future<void> abandonMatch(String matchId) {
    return _apiClient.abandonMatch(matchId);
  }
}

class ActiveMatchesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  static final _log = Logger('ActiveMatchesNotifier');

  final MatchesService _matchesService;
  Timer? _refreshTimer;
  Timer? _timeUpdateTimer;

  ActiveMatchesNotifier(this._matchesService) : super([]) {
    _loadActiveMatches();
    _startPeriodicRefresh();
  }

  /// Loads active matches from the API
  Future<void> _loadActiveMatches() async {
    try {
      _log.info('Loading active matches from API');
      final matches = await _matchesService.getActiveMatches();
      _log.fine('Loaded ${matches.length} active matches');
      state = matches;
      _startPeriodicUpdates();
    } catch (e, stackTrace) {
      _log.warning('Failed to load active matches', e, stackTrace);
    }
  }

  /// Refreshes match data from the API periodically (every 30 seconds)
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadActiveMatches();
    });
  }

  void _startPeriodicUpdates() {
    // Clean up old timer if exists
    _timeUpdateTimer?.cancel();
    // Trigger widget rebuilds to update relative timestamps every minute
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Force UI rebuild by updating state reference
      // This causes displayed timestamps to recalculate
      state = [...state];
    });
  }

  void updateMatchScore(String matchId, String newScore, String newStatus) {
    state = state.map((match) {
      if (match['id'] == matchId) {
        return {
          ...match,
          'score': newScore,
          'status': newStatus,
          'lastMove': DateTime.now(),
        };
      }
      return match;
    }).toList();
  }

  void addMatch(Map<String, dynamic> newMatch) {
    state = [...state, newMatch];
  }

  void removeMatch(String matchId) {
    state = state.where((match) => match['id'] != matchId).toList();
  }
}
