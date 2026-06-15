import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../dto/hub_event_dto.dart';
import '../../dto/party_dto.dart';
import 'hub_client_base.dart';

/// Hub connected only during an active match.
/// Path: /ws/match?playerId={id}&access_token={token}
///
/// Delivers real-time match state updates for the duration of one match,
/// then disconnected when the match ends.
///
/// Party events are also delivered here: the server auto-joins the connection
/// to the `player:{playerId}` group (from the `playerId` query param), so as
/// long as the hub is connected with the player's id, party push events arrive
/// without any extra subscription call.
class MatchHub extends HubClientBase {
  final _matchUpdates = StreamController<MatchUpdateDto>.broadcast();
  final _partyMatched = StreamController<PartyMatchedDto>.broadcast();
  final _partyRosterUpdated =
      StreamController<PartyRosterUpdatedDto>.broadcast();
  final _partyClosed = StreamController<PartyClosedDto>.broadcast();

  Stream<MatchUpdateDto> get matchUpdates => _matchUpdates.stream;

  /// `party.matched` — opponent found; the connection has been auto-joined to
  /// the `match:{matchId}` group server-side.
  Stream<PartyMatchedDto> get partyMatched => _partyMatched.stream;

  /// `party.roster.updated` — roster/online-state changed.
  Stream<PartyRosterUpdatedDto> get partyRosterUpdated =>
      _partyRosterUpdated.stream;

  /// `party.closed` — the party was disbanded.
  Stream<PartyClosedDto> get partyClosed => _partyClosed.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('MatchUpdate', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _matchUpdates.add(MatchUpdateDto.fromJson(raw));
      }
    });

    connection.on('party.matched', (args) {
      final raw = _firstArg(args);
      if (raw != null) _partyMatched.add(PartyMatchedDto.fromJson(raw));
    });

    connection.on('party.roster.updated', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _partyRosterUpdated.add(PartyRosterUpdatedDto.fromJson(raw));
      }
    });

    connection.on('party.closed', (args) {
      final raw = _firstArg(args);
      if (raw != null) _partyClosed.add(PartyClosedDto.fromJson(raw));
    });
  }

  @override
  Future<void> stop() async {
    await super.stop();
    await _matchUpdates.close();
    await _partyMatched.close();
    await _partyRosterUpdated.close();
    await _partyClosed.close();
  }

  Map<String, dynamic>? _firstArg(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args[0];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }
}
