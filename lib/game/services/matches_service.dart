import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchesService {
  // Service methods for match management
  Future<List<Map<String, dynamic>>> getActiveMatches() async {
    // Implement API call to get active matches
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return []; // Return actual match data
  }

  Future<void> updateMatchScore(String matchId, int playerScore, int opponentScore) async {
    // Implement API call to update match score
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    // Implement API call to get detailed match information
    await Future.delayed(const Duration(milliseconds: 300));
    return {};
  }
}

class ActiveMatchesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ActiveMatchesNotifier() : super([
    {
      'id': '1',
      'name': 'mindpixell',
      'score': '0-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-1.png',
      'status': 'waiting',
      'lastMove': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '2',
      'name': 'giovanni.rasmussen',
      'score': '3-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-2.png',
      'status': 'winning',
      'lastMove': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'id': '3',
      'name': 'dexter.henderson',
      'score': '0-1',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-3.png',
      'status': 'losing',
      'lastMove': DateTime.now().subtract(const Duration(minutes: 30)),
    },
  ]) {
    // Start periodic updates for match times
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    // Update match times every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateMatchTimes();
    });
  }

  void _updateMatchTimes() {
    final updatedMatches = state.map((match) {
      final lastMove = match['lastMove'] as DateTime;
      final timeDiff = DateTime.now().difference(lastMove);

      String timeDisplay;
      if (timeDiff.inDays > 0) {
        timeDisplay = '${timeDiff.inDays}d left';
      } else if (timeDiff.inHours > 0) {
        timeDisplay = '${24 - timeDiff.inHours}h left';
      } else {
        timeDisplay = '${60 - timeDiff.inMinutes}m left';
      }

      return {
        ...match,
        'time': timeDisplay,
      };
    }).toList();

    state = updatedMatches;
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
