import 'package:trivia_tycoon/core/manager/log_manager.dart';
import '../domain/arcade_result.dart';

class ArcadeAnalyticsService {
  const ArcadeAnalyticsService();

  void logGameCompleted(ArcadeResult result) {
    LogManager.performance(
      '[Arcade] Completed: ${result.gameId} '
      'score=${result.score} diff=${result.difficulty} dur=${result.duration}',
      source: 'ArcadeAnalytics',
    );
  }
}
