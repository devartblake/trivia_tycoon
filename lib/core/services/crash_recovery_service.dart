import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/quiz_progress_service.dart';
import 'package:trivia_tycoon/core/services/state_persistence_service.dart';

class CrashRecoveryResult {
  const CrashRecoveryResult({
    required this.restoredAuthState,
    required this.restoredGameState,
    required this.restoredUserProfile,
    required this.pendingActionCount,
  });

  final bool restoredAuthState;
  final bool restoredGameState;
  final bool restoredUserProfile;
  final int pendingActionCount;
}

class CrashRecoveryService {
  const CrashRecoveryService({
    required QuizProgressService quizProgressService,
    required PlayerProfileService playerProfileService,
  })  : _quizProgressService = quizProgressService,
        _playerProfileService = playerProfileService;

  final QuizProgressService _quizProgressService;
  final PlayerProfileService _playerProfileService;

  Future<CrashRecoveryResult> restore(
    StatePersistenceService persistenceService,
  ) async {
    final gameState = await persistenceService.getGameState();
    final userSession = await persistenceService.getUserSession();
    final pendingActions = await persistenceService.getPendingActions();

    var restoredGameState = false;
    var restoredUserProfile = false;
    var restoredAuthState = false;

    if (gameState != null) {
      final quizProgress = _mapOrNull(gameState['quiz_progress']);
      if (quizProgress != null) {
        await _quizProgressService.saveQuizProgress(quizProgress);
        restoredGameState = true;
      }

      final playerProgress = _mapOrNull(gameState['player_progress']);
      if (playerProgress != null) {
        await _quizProgressService.savePlayerProgress(playerProgress);
        restoredGameState = true;
      }
    }

    if (userSession != null) {
      restoredAuthState = userSession['is_logged_in'] as bool? ?? false;

      final profileBatch = <String, dynamic>{};
      _copyIfPresent(userSession, profileBatch, 'user_id');
      _copyIfPresent(userSession, profileBatch, 'player_name');
      _copyIfPresent(userSession, profileBatch, 'username');
      _copyIfPresent(userSession, profileBatch, 'user_role');
      _copyIfPresent(userSession, profileBatch, 'user_roles');
      _copyIfPresent(userSession, profileBatch, 'is_premium');
      _copyIfPresent(userSession, profileBatch, 'country');
      _copyIfPresent(userSession, profileBatch, 'age_group');
      _copyIfPresent(userSession, profileBatch, 'avatar');
      _copyIfPresent(userSession, profileBatch, 'synaptix_mode');
      _copyIfPresent(userSession, profileBatch, 'preferred_home_surface');
      _copyIfPresent(userSession, profileBatch, 'reduced_motion');
      _copyIfPresent(userSession, profileBatch, 'tone_preference');

      if (profileBatch.isNotEmpty) {
        await _playerProfileService.saveProfileBatch(profileBatch);
        restoredUserProfile = true;
      }
    }

    await persistenceService.markRecoveryHandled();

    LogManager.info(
      '[Recovery] Restored gameState=$restoredGameState userProfile=$restoredUserProfile pendingActions=${pendingActions.length}',
      source: 'CrashRecoveryService',
    );

    return CrashRecoveryResult(
      restoredAuthState: restoredAuthState,
      restoredGameState: restoredGameState,
      restoredUserProfile: restoredUserProfile,
      pendingActionCount: pendingActions.length,
    );
  }

  Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _copyIfPresent(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
    String key,
  ) {
    if (!source.containsKey(key)) return;
    final value = source[key];
    if (value == null) return;
    target[key] = value;
  }
}
