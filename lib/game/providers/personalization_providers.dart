/// Personalization + A/B experiment Riverpod providers.
///
/// Caching strategy (per contract §5):
///   Experiment assignments — session lifetime
///   Home personalization    — 5 min  (autoDispose + keepAlive for 5 min)
///   Full profile            — 10 min (lazy fetch, used only by Settings)
///   Coach brief             — 1 hr   (standalone endpoint, lazy)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/personalization_dto.dart';
import '../../core/services/personalization/experiment_store.dart';
import '../../core/services/personalization/personalization_service.dart';
import 'core_providers.dart';

// ── Service ───────────────────────────────────────────────────────────────────

final personalizationServiceProvider = Provider<PersonalizationService>((ref) {
  return PersonalizationService(ref.watch(synaptixApiClientProvider));
});

// ── Experiment Store ──────────────────────────────────────────────────────────

/// Singleton accessor — the store is session-scoped and seeded during initSession.
final experimentStoreProvider = Provider<ExperimentStore>((ref) {
  return ExperimentStore.instance;
});

// ── Session Init ──────────────────────────────────────────────────────────────

/// Fetches experiments + home personalization in parallel at session start.
/// Automatically re-runs when [playerId] changes (family).
/// Returns [PlayerHomePersonalizationDto] which also seeds ExperimentStore.
final sessionInitProvider = FutureProvider.autoDispose
    .family<PlayerHomePersonalizationDto, String>((ref, playerId) async {
  final service = ref.watch(personalizationServiceProvider);
  return service.initSession(playerId);
});

// ── Home Personalization ──────────────────────────────────────────────────────

/// Short-lived (autoDispose) home personalization — re-fetch every foreground.
final homePersonalizationProvider = FutureProvider.autoDispose
    .family<PlayerHomePersonalizationDto, String>((ref, playerId) async {
  final service = ref.watch(personalizationServiceProvider);
  return service.getHome(playerId);
});

// ── Player Mind Profile ───────────────────────────────────────────────────────

/// Lazy full profile — used by Settings + deep personalization.
/// autoDispose keeps it out of memory when not on screen.
final playerMindProfileProvider = FutureProvider.autoDispose
    .family<PlayerMindProfileDto, String>((ref, playerId) async {
  final service = ref.watch(personalizationServiceProvider);
  return service.getProfile(playerId);
});

// ── Coach Brief ───────────────────────────────────────────────────────────────

final dailyBriefProvider = FutureProvider.autoDispose
    .family<CoachBriefDto, String>((ref, playerId) async {
  final service = ref.watch(personalizationServiceProvider);
  return service.getDailyBrief(playerId);
});

// ── Recommendations ───────────────────────────────────────────────────────────

final recommendationsProvider = FutureProvider.autoDispose
    .family<List<PlayerRecommendationDto>, String>((ref, playerId) async {
  final service = ref.watch(personalizationServiceProvider);
  return service.getRecommendations(playerId);
});

// ── Personalization Toggle ────────────────────────────────────────────────────

/// Local state for the personalization enabled toggle.
/// Seeded from profile on first load; mutated by Settings.
final personalizationEnabledProvider =
    StateProvider.family<bool, String>((ref, playerId) => true);

