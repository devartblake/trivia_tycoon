/// Multiplayer providers — challenge coordination and match management.
///
/// Depends only on [core_providers.dart].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/social/challenge_coordination_service.dart';
import '../../game/services/matches_service.dart';
import 'core_providers.dart'; // ignore: unused_import — kept for consistency

// ---------------------------------------------------------------------------
// Challenge
// ---------------------------------------------------------------------------

final challengeCoordinationServiceProvider =
Provider<ChallengeCoordinationService>((ref) {
  final service = ChallengeCoordinationService();
  service.initialize();
  return service;
});

// ---------------------------------------------------------------------------
// Matches
// ---------------------------------------------------------------------------

final matchesServiceProvider = Provider<MatchesService>((ref) {
  return MatchesService();
});

final activeMatchesProvider =
StateNotifierProvider<ActiveMatchesNotifier, List<Map<String, dynamic>>>(
        (ref) {
      return ActiveMatchesNotifier();
    });
