import 'package:flutter_riverpod/flutter_riverpod.dart';
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
