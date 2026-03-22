import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../dto/hub_event_dto.dart';
import 'hub_client_base.dart';

/// Hub connected only during an active match.
/// Path: /ws/match?playerId={id}&access_token={token}
///
/// Delivers real-time match state updates for the duration of one match,
/// then disconnected when the match ends.
class MatchHub extends HubClientBase {
  final _matchUpdates = StreamController<MatchUpdateDto>.broadcast();

  Stream<MatchUpdateDto> get matchUpdates => _matchUpdates.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('MatchUpdate', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _matchUpdates.add(MatchUpdateDto.fromJson(raw));
      }
    });
  }

  @override
  Future<void> stop() async {
    await super.stop();
    await _matchUpdates.close();
  }

  Map<String, dynamic>? _firstArg(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args[0];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }
}
