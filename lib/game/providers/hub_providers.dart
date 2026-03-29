import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/networking/signalr/notification_hub.dart';
import '../../core/networking/signalr/match_hub.dart';
import '../../core/dto/hub_event_dto.dart';
import '../../core/dto/game_event_dto.dart';
import '../../core/dto/guardian_dto.dart';
import '../../core/dto/territory_dto.dart';
import '../../core/dto/vote_dto.dart';
import 'riverpod_providers.dart';

// ── Hub instances ────────────────────────────────────────────────────────────

/// The persistent [NotificationHub] — connected on login, disconnected on logout.
/// Consumers call [notificationHubProvider].start() / .stop() from auth handlers.
final notificationHubProvider = Provider<NotificationHub>((ref) {
  final hub = ref.read(serviceManagerProvider).notificationHub;
  ref.onDispose(hub.stop);
  return hub;
});

/// The per-match [MatchHub] — connected at match start, disconnected at match end.
final matchHubProvider = Provider<MatchHub>((ref) {
  final hub = ref.read(serviceManagerProvider).matchHub;
  ref.onDispose(hub.stop);
  return hub;
});

// ── NotificationHub stream providers ────────────────────────────────────────

final playerNotificationStreamProvider =
StreamProvider<PlayerNotificationDto>((ref) {
  return ref.watch(notificationHubProvider).playerNotifications;
});

final gameEventEliminationStreamProvider =
StreamProvider<GameEventEliminationDto>((ref) {
  return ref.watch(notificationHubProvider).gameEventEliminations;
});

final gameEventClosedStreamProvider =
StreamProvider<GameEventClosedDto>((ref) {
  return ref.watch(notificationHubProvider).gameEventsClosed;
});

final guardianChangedStreamProvider =
StreamProvider<GuardianChangedDto>((ref) {
  return ref.watch(notificationHubProvider).guardianChanges;
});

final territoryCaptureStreamProvider =
StreamProvider<TerritoryCaptureDto>((ref) {
  return ref.watch(notificationHubProvider).territoryCaptures;
});

final voteTallyStreamProvider =
StreamProvider<VoteTallyUpdatedDto>((ref) {
  return ref.watch(notificationHubProvider).voteTallyUpdates;
});

// ── MatchHub stream provider ─────────────────────────────────────────────────

final matchUpdateStreamProvider = StreamProvider<MatchUpdateDto>((ref) {
  return ref.watch(matchHubProvider).matchUpdates;
});

// ── REST-backed feature providers ────────────────────────────────────────────

/// Upcoming game events from GET /game-events/upcoming.
final upcomingGameEventsProvider =
FutureProvider<List<GameEventDto>>((ref) async {
  final api = ref.read(serviceManagerProvider).tycoonApiClient;
  return api.getUpcomingGameEvents();
});

/// Current active season from GET /seasons/active.
final activeSeasonProvider =
FutureProvider.autoDispose((ref) async {
  final api = ref.read(serviceManagerProvider).tycoonApiClient;
  return api.getActiveSeason();
});

/// Guardian list for a (seasonId, tierNumber) pair.
final guardianListProvider = FutureProvider.autoDispose
    .family<List<GuardianDto>, (String, int)>((ref, args) async {
  final (seasonId, tierNumber) = args;
  final api = ref.read(serviceManagerProvider).tycoonApiClient;
  return api.getGuardians(seasonId: seasonId, tierNumber: tierNumber);
});

/// Territory board for a (seasonId, tierNumber) pair.
final territoryBoardProvider = FutureProvider.autoDispose
    .family<TerritoryBoardDto, (String, int)>((ref, args) async {
  final (seasonId, tierNumber) = args;
  final api = ref.read(serviceManagerProvider).tycoonApiClient;
  return api.getTerritoryBoard(seasonId: seasonId, tierNumber: tierNumber);
});

/// Vote results for a given topic.
final voteResultsProvider =
FutureProvider.autoDispose.family<VoteResultDto, String>((ref, topic) async {
  final api = ref.read(serviceManagerProvider).tycoonApiClient;
  return api.getVoteResults(topic: topic);
});

