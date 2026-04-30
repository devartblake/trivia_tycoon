import 'dart:async' show Future, unawaited;

import '../../dto/personalization_dto.dart';
import '../../networking/synaptix_api_client.dart';
import 'experiment_store.dart';

/// Wraps all personalization and experiment API calls.
///
/// Session startup sequence (call once after login/splash):
/// ```dart
/// await service.initSession(playerId);
/// ```
/// After that, individual getters return fresh or cached data.
///
/// All behaviour event methods are fire-and-forget; errors are swallowed.
class PersonalizationService {
  final SynaptixApiClient _api;

  const PersonalizationService(this._api);

  // ── Session Startup ─────────────────────────────────────────────────────────

  /// Bootstrap experiments + home personalization in parallel (per contract §3).
  /// Seeds [ExperimentStore] and returns home personalization for immediate rendering.
  Future<PlayerHomePersonalizationDto> initSession(String playerId) async {
    final results = await Future.wait([
      _api.getPlayerExperiments(playerId: playerId),
      _api.getHomePersonalization(playerId: playerId),
    ]);

    final experiments = results[0] as PlayerExperimentsDto;
    final home = results[1] as PlayerHomePersonalizationDto;

    ExperimentStore.instance.seed(experiments.assignments);
    return home;
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<PlayerMindProfileDto> getProfile(String playerId) =>
      _api.getPlayerMindProfile(playerId: playerId);

  // ── Home ────────────────────────────────────────────────────────────────────

  Future<PlayerHomePersonalizationDto> getHome(String playerId) =>
      _api.getHomePersonalization(playerId: playerId);

  // ── Recommendations ─────────────────────────────────────────────────────────

  Future<List<PlayerRecommendationDto>> getRecommendations(String playerId) =>
      _api.getRecommendations(playerId: playerId);

  // ── Coach Brief ─────────────────────────────────────────────────────────────

  Future<CoachBriefDto> getDailyBrief(String playerId) =>
      _api.getDailyBrief(playerId: playerId);

  Future<void> sendCoachFeedback({
    required String playerId,
    required String briefId,
    required String feedback,
  }) async {
    try {
      await _api.postCoachFeedback(
        playerId: playerId,
        briefId: briefId,
        feedback: feedback,
      );
    } catch (_) {}
  }

  // ── Personalization Toggle ──────────────────────────────────────────────────

  Future<bool> togglePersonalization({
    required String playerId,
    required bool enabled,
  }) =>
      _api.togglePersonalization(playerId: playerId, enabled: enabled);

  // ── Behaviour Events (fire-and-forget) ──────────────────────────────────────

  void fireEvent(String playerId, BehaviourEventDto event) {
    unawaited(_safeFire(playerId, event));
  }

  void fireQuestionAnswered({
    required String playerId,
    required String category,
    required String difficulty,
    required String mode,
    required bool correct,
    required int timeMs,
    String? questionId,
  }) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'question_answered',
        eventSource: 'quiz',
        category: category,
        difficulty: difficulty,
        mode: mode,
        metadata: {
          'correct': correct,
          'timeMs': timeMs,
          if (questionId != null) 'questionId': questionId,
        },
      ),
    );
  }

  void fireMatchCompleted({
    required String playerId,
    required String mode,
    String? category,
    Map<String, dynamic> metadata = const {},
  }) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'match_completed',
        eventSource: 'game',
        category: category,
        mode: mode,
        metadata: metadata,
      ),
    );
  }

  void fireLearningModuleCompleted({
    required String playerId,
    String? category,
    Map<String, dynamic> metadata = const {},
  }) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'learning_module_completed',
        eventSource: 'learn',
        category: category,
        metadata: metadata,
      ),
    );
  }

  void fireStoreItemPurchased({
    required String playerId,
    required String itemId,
    Map<String, dynamic> metadata = const {},
  }) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'store_item_purchased',
        eventSource: 'store',
        metadata: {'itemId': itemId, ...metadata},
      ),
    );
  }

  void fireNotificationOpened({required String playerId, String? notificationId}) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'notification_opened',
        eventSource: 'notification',
        metadata: {if (notificationId != null) 'notificationId': notificationId},
      ),
    );
  }

  void fireNotificationDismissed({required String playerId, String? notificationId}) {
    fireEvent(
      playerId,
      BehaviourEventDto(
        eventType: 'notification_dismissed',
        eventSource: 'notification',
        metadata: {if (notificationId != null) 'notificationId': notificationId},
      ),
    );
  }

  // ── Experiments ─────────────────────────────────────────────────────────────

  Future<void> recordImpression({
    required String playerId,
    required String experimentKey,
  }) async {
    try {
      await _api.recordExperimentImpression(
        playerId: playerId,
        experimentKey: experimentKey,
      );
    } catch (_) {}
  }

  Future<void> recordOutcome({
    required String playerId,
    required String experimentKey,
  }) async {
    try {
      await _api.recordExperimentOutcome(
        playerId: playerId,
        experimentKey: experimentKey,
      );
    } catch (_) {}
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _safeFire(String playerId, BehaviourEventDto event) async {
    try {
      await _api.recordBehaviourEvent(playerId: playerId, event: event);
    } catch (_) {}
  }
}

