import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/arcade_daily_bonus_service.dart';
import '../services/arcade_personal_best_service.dart';
import '../services/arcade_registry.dart';
import '../services/arcade_rewards_service.dart';
import '../services/arcade_session_service.dart';
import '../services/arcade_analytics_service.dart';

final arcadeRegistryProvider = Provider<ArcadeRegistry>((ref) {
  return const ArcadeRegistry();
});

final arcadeRewardsServiceProvider = Provider<ArcadeRewardsService>((ref) {
  return const ArcadeRewardsService();
});

final arcadeSessionServiceProvider = Provider<ArcadeSessionService>((ref) {
  return const ArcadeSessionService();
});

final arcadeAnalyticsServiceProvider = Provider<ArcadeAnalyticsService>((ref) {
  return const ArcadeAnalyticsService();
});

final arcadePersonalBestServiceProvider = Provider<ArcadePersonalBestService>((ref) {
  return ArcadePersonalBestService();
});

final arcadeDailyBonusServiceProvider = Provider<ArcadeDailyBonusService>((ref) {
  return ArcadeDailyBonusService();
});
