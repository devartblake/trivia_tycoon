import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/networking/signalr/notification_hub.dart';
import '../../core/networking/signalr/match_hub.dart';
import '../../core/networking/signalr/presence_hub.dart';
import '../../core/networking/signalr/leaderboard_hub.dart';
import '../../core/networking/signalr/matchmaking_hub.dart';
import '../../core/dto/hub_event_dto.dart';
import '../../core/dto/champion_round_events.dart';
import '../../core/dto/game_event_dto.dart';
import '../../core/dto/guardian_dto.dart';
import '../../core/dto/territory_dto.dart';
import '../../core/dto/vote_dto.dart';
import 'core_providers.dart';

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

/// [PresenceHub] — connected on login; subscribe friends after friend list loads.
final presenceHubProvider = Provider<PresenceHub>((ref) {
  final hub = ref.read(serviceManagerProvider).presenceHub;
  ref.onDispose(hub.stop);
  return hub;
});

/// [LeaderboardHub] — connect when the leaderboard screen is open.
final leaderboardHubProvider = Provider<LeaderboardHub>((ref) {
  final hub = ref.read(serviceManagerProvider).leaderboardHub;
  ref.onDispose(hub.stop);
  return hub;
});

/// [MatchmakingHub] — connect when entering the matchmaking queue.
final matchmakingHubProvider = Provider<MatchmakingHub>((ref) {
  final hub = ref.read(serviceManagerProvider).matchmakingHub;
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

final gameEventClosedStreamProvider = StreamProvider<GameEventClosedDto>((ref) {
  return ref.watch(notificationHubProvider).gameEventsClosed;
});

// ── Champion vs Tier live-round streams ──────────────────────────────────────

final championRoundStartedStreamProvider =
    StreamProvider<ChampionRoundStartedDto>((ref) {
  return ref.watch(notificationHubProvider).championRoundStarted;
});

final championRoundResolvedStreamProvider =
    StreamProvider<ChampionRoundResolvedDto>((ref) {
  return ref.watch(notificationHubProvider).championRoundResolved;
});

final championMatchEndedStreamProvider =
    StreamProvider<ChampionMatchEndedDto>((ref) {
  return ref.watch(notificationHubProvider).championMatchEnded;
});

final guardianChangedStreamProvider = StreamProvider<GuardianChangedDto>((ref) {
  return ref.watch(notificationHubProvider).guardianChanges;
});

final territoryCaptureStreamProvider =
    StreamProvider<TerritoryCaptureDto>((ref) {
  return ref.watch(notificationHubProvider).territoryCaptures;
});

final voteTallyStreamProvider = StreamProvider<VoteTallyUpdatedDto>((ref) {
  return ref.watch(notificationHubProvider).voteTallyUpdates;
});

final directMessagesUpdatedStreamProvider =
    StreamProvider<DirectMessagesUpdatedDto>((ref) {
  return ref.watch(notificationHubProvider).directMessagesUpdated;
});

// ── MatchHub stream provider ─────────────────────────────────────────────────

final matchUpdateStreamProvider = StreamProvider<MatchUpdateDto>((ref) {
  return ref.watch(matchHubProvider).matchUpdates;
});

// ── PresenceHub stream providers ─────────────────────────────────────────────

final presenceChangedStreamProvider =
    StreamProvider<PlayerPresenceChangedDto>((ref) {
  return ref.watch(presenceHubProvider).presenceChanged;
});

final presenceSnapshotStreamProvider =
    StreamProvider<PlayerPresenceSnapshotDto>((ref) {
  return ref.watch(presenceHubProvider).presenceSnapshot;
});

// ── LeaderboardHub stream providers ──────────────────────────────────────────

final leaderboardRankChangedStreamProvider =
    StreamProvider<LeaderboardRankChangedDto>((ref) {
  return ref.watch(leaderboardHubProvider).rankChanged;
});

final leaderboardSnapshotStreamProvider =
    StreamProvider<LeaderboardSnapshotDto>((ref) {
  return ref.watch(leaderboardHubProvider).snapshot;
});

// ── MatchmakingHub stream providers ──────────────────────────────────────────

final matchmakingQueuedStreamProvider =
    StreamProvider<MatchmakingQueuedDto>((ref) {
  return ref.watch(matchmakingHubProvider).queued;
});

final matchmakingMatchedStreamProvider =
    StreamProvider<MatchmakingMatchedDto>((ref) {
  return ref.watch(matchmakingHubProvider).matched;
});

final matchmakingCancelledStreamProvider =
    StreamProvider<MatchmakingCancelledDto>((ref) {
  return ref.watch(matchmakingHubProvider).cancelled;
});

// ── REST-backed feature providers ────────────────────────────────────────────

/// Upcoming game events from GET /game-events/upcoming.
final upcomingGameEventsProvider =
    FutureProvider<List<GameEventDto>>((ref) async {
  final api = ref.read(serviceManagerProvider).synaptixApiClient;
  return api.getUpcomingGameEvents();
});

/// Current active season from GET /seasons/active.
final activeSeasonProvider = FutureProvider.autoDispose((ref) async {
  final api = ref.read(serviceManagerProvider).synaptixApiClient;
  return api.getActiveSeason();
});

/// Guardian list for a (seasonId, tierNumber) pair.
final guardianListProvider = FutureProvider.autoDispose
    .family<List<GuardianDto>, (String, int)>((ref, args) async {
  final (seasonId, tierNumber) = args;
  final api = ref.read(serviceManagerProvider).synaptixApiClient;
  return api.getGuardians(seasonId: seasonId, tierNumber: tierNumber);
});

/// Territory board for a (seasonId, tierNumber) pair.
final territoryBoardProvider = FutureProvider.autoDispose
    .family<TerritoryBoardDto, (String, int)>((ref, args) async {
  final (seasonId, tierNumber) = args;
  final api = ref.read(serviceManagerProvider).synaptixApiClient;
  return api.getTerritoryBoard(seasonId: seasonId, tierNumber: tierNumber);
});

/// Vote results for a given topic.
final voteResultsProvider = FutureProvider.autoDispose
    .family<VoteResultDto, String>((ref, topic) async {
  final api = ref.read(serviceManagerProvider).synaptixApiClient;
  return api.getVoteResults(topic: topic);
});
