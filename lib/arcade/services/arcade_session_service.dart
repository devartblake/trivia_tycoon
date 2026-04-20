import '../domain/arcade_result.dart';

class ArcadeSessionService {
  const ArcadeSessionService();

  DateTime startSession() => DateTime.now();

  Duration endSession(DateTime startedAt) =>
      DateTime.now().difference(startedAt);

  ArcadeResult attachDuration(ArcadeResult result, Duration duration) {
    return ArcadeResult(
      gameId: result.gameId,
      difficulty: result.difficulty,
      score: result.score,
      duration: duration,
      metadata: result.metadata,
    );
  }
}
