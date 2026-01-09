import '../domain/arcade_result.dart';

class ArcadeAnalyticsService {
  const ArcadeAnalyticsService();

  void logGameCompleted(ArcadeResult result) {
    // TODO: wire into your analytics pipeline
    // ignore: avoid_print
    print('[Arcade] Completed: ${result.gameId} score=${result.score} diff=${result.difficulty} dur=${result.duration}');
  }
}
