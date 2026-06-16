import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/party_dto.dart';
import '../../core/networking/http_client.dart' show HttpException;
import '../../core/networking/synaptix_api_client.dart';
import 'core_providers.dart';
import 'hub_providers.dart';

/// Immutable state for the party lobby.
class PartyState {
  final PartyRosterDto? roster;
  final List<PartyInviteDto> incomingInvites;

  /// Last enqueue status: Queued | Matched | null (not queued).
  final String? queueStatus;

  /// Set when a `party.matched` push arrives — the screen navigates into the match.
  final PartyMatchedDto? matched;
  final bool busy;
  final String? error;

  const PartyState({
    this.roster,
    this.incomingInvites = const [],
    this.queueStatus,
    this.matched,
    this.busy = false,
    this.error,
  });

  bool get inParty => roster != null && roster!.status != 'Closed';
  bool get isQueued => queueStatus == 'Queued';

  PartyState copyWith({
    PartyRosterDto? roster,
    bool clearRoster = false,
    List<PartyInviteDto>? incomingInvites,
    String? queueStatus,
    bool clearQueueStatus = false,
    PartyMatchedDto? matched,
    bool clearMatched = false,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return PartyState(
      roster: clearRoster ? null : (roster ?? this.roster),
      incomingInvites: incomingInvites ?? this.incomingInvites,
      queueStatus: clearQueueStatus ? null : (queueStatus ?? this.queueStatus),
      matched: clearMatched ? null : (matched ?? this.matched),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the party lobby: REST actions against `/party/*` plus live updates
/// from MatchHub (`party.roster.updated` / `party.matched` / `party.closed`).
class PartyController extends StateNotifier<PartyState> {
  final SynaptixApiClient _api;
  final String playerId;
  final List<StreamSubscription<dynamic>> _subs = [];

  PartyController(this._api, this.playerId, Ref ref)
      : super(const PartyState()) {
    final hub = ref.read(matchHubProvider);
    _subs
      ..add(hub.partyRosterUpdated.listen(
        (e) { state = state.copyWith(roster: e.roster); },
        onError: (e) => state = state.copyWith(error: e.toString()),
      ))
      ..add(hub.partyMatched.listen(
        (e) { state = state.copyWith(matched: e, queueStatus: 'Matched'); },
        onError: (e) => state = state.copyWith(error: e.toString()),
      ))
      ..add(hub.partyClosed.listen(
        (_) { state = state.copyWith(clearRoster: true, clearQueueStatus: true, incomingInvites: const []); },
        onError: (e) => state = state.copyWith(error: e.toString()),
      ));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<T?> _guard<T>(Future<T> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      return await action();
    } on HttpException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Loads incoming invites and the roster (when already in a party).
  Future<void> refresh() async {
    await _guard(() async {
      final invites = await _api.listPartyInvites(playerId: playerId);
      PartyRosterDto? roster = state.roster;
      if (roster != null) {
        roster = await _api.getPartyRoster(roster.partyId);
      }
      state = state.copyWith(
        incomingInvites: invites.items
            .where((i) => i.status == 'Pending')
            .toList(growable: false),
        roster: roster,
      );
    });
  }

  Future<void> createParty() => _guard(() async {
        final roster = await _api.createParty(leaderPlayerId: playerId);
        state = state.copyWith(roster: roster);
      });

  Future<void> leaveParty() async {
    final roster = state.roster;
    if (roster == null) return;
    await _guard(() async {
      await _api.leaveParty(partyId: roster.partyId, playerId: playerId);
      state = state.copyWith(clearRoster: true, clearQueueStatus: true);
    });
  }

  Future<void> invite(String toPlayerId) async {
    final roster = state.roster;
    if (roster == null) return;
    await _guard(() => _api.inviteToParty(
          partyId: roster.partyId,
          fromPlayerId: playerId,
          toPlayerId: toPlayerId,
        ));
  }

  Future<void> acceptInvite(PartyInviteDto invite) => _guard(() async {
        await _api.acceptPartyInvite(
            inviteId: invite.inviteId, playerId: playerId);
        final roster = await _api.getPartyRoster(invite.partyId);
        state = state.copyWith(
          roster: roster,
          incomingInvites: state.incomingInvites
              .where((i) => i.inviteId != invite.inviteId)
              .toList(growable: false),
        );
      });

  Future<void> declineInvite(PartyInviteDto invite) => _guard(() async {
        await _api.declinePartyInvite(
            inviteId: invite.inviteId, playerId: playerId);
        state = state.copyWith(
          incomingInvites: state.incomingInvites
              .where((i) => i.inviteId != invite.inviteId)
              .toList(growable: false),
        );
      });

  Future<void> enqueue({required String mode, required int tier}) async {
    final roster = state.roster;
    if (roster == null) return;
    await _guard(() async {
      final res = await _api.enqueueParty(
        partyId: roster.partyId,
        leaderPlayerId: playerId,
        mode: mode,
        tier: tier,
      );
      state = state.copyWith(queueStatus: res.status);
    });
  }

  Future<void> cancelQueue() async {
    final roster = state.roster;
    if (roster == null) return;
    await _guard(() async {
      await _api.cancelPartyQueue(
          partyId: roster.partyId, leaderPlayerId: playerId);
      state = state.copyWith(clearQueueStatus: true);
    });
  }

  /// Clears the one-shot `matched` flag once the screen has navigated.
  void consumeMatched() => state = state.copyWith(clearMatched: true);

  bool get isLeader => state.roster?.leaderPlayerId == playerId;
}

final partyControllerProvider = StateNotifierProvider.autoDispose
    .family<PartyController, PartyState, String>((ref, playerId) {
  final api = ref.watch(synaptixApiClientProvider);
  return PartyController(api, playerId, ref);
});
