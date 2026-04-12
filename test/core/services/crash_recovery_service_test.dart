import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/crash_recovery_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/quiz_progress_service.dart';
import 'package:trivia_tycoon/core/services/state_persistence_service.dart';

void main() {
  late Directory tempDir;
  late StatePersistenceService persistenceService;
  late QuizProgressService quizProgressService;
  late PlayerProfileService playerProfileService;
  late CrashRecoveryService crashRecoveryService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('crash_recovery_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    persistenceService = StatePersistenceService();
    await persistenceService.initialize();
    quizProgressService = await QuizProgressService.initialize();
    playerProfileService = PlayerProfileService();
    crashRecoveryService = CrashRecoveryService(
      quizProgressService: quizProgressService,
      playerProfileService: playerProfileService,
    );
  });

  tearDown(() async {
    await Hive.close();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('restores quiz progress and player profile from persistence', () async {
    await persistenceService.saveAll(
      gameState: {
        'quiz_progress': {
          'quiz_id': 'science_daily',
          'score': 7,
        },
        'player_progress': {
          'total_questions': 10,
          'correct_answers': 7,
        },
      },
      userSession: {
        'is_logged_in': true,
        'user_id': 'user-42',
        'player_name': 'Avery',
        'username': 'avery',
        'age_group': 'teens',
        'synaptix_mode': 'teen',
      },
      pendingActions: [
        {'type': 'mission_claim', 'id': 'daily_1'},
      ],
    );

    // Simulate a crash detected on next launch.
    final reopenedPersistence = StatePersistenceService();
    await reopenedPersistence.initialize();

    final result = await crashRecoveryService.restore(reopenedPersistence);

    expect(result.restoredAuthState, isTrue);
    expect(result.restoredGameState, isTrue);
    expect(result.restoredUserProfile, isTrue);
    expect(result.pendingActionCount, 1);

    final restoredQuiz = await quizProgressService.getQuizProgress();
    final restoredPlayer = await quizProgressService.getPlayerProgress();
    final restoredProfile = await playerProfileService.loadCompleteProfile();

    expect(restoredQuiz['quiz_id'], 'science_daily');
    expect(restoredQuiz['score'], 7);
    expect(restoredPlayer['total_questions'], 10);
    expect(restoredPlayer['correct_answers'], 7);
    expect(restoredProfile['user_id'], 'user-42');
    expect(restoredProfile['player_name'], 'Avery');
    expect(restoredProfile['username'], 'avery');
    expect(restoredProfile['age_group'], 'teens');
    expect(restoredProfile['synaptix_mode'], 'teen');
    expect(await reopenedPersistence.hasRecoverableData(), isFalse);
  });
}
